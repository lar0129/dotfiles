#!/bin/bash
# Exit immediately if a command exits with a non-zero status.
set -e

# 1. Get the robust script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "📂 Dotfiles directory is at: $SCRIPT_DIR"

# 2. Detect OS and architecture
OS_TYPE=""
OS_ARCH=$(uname -m)

case "$(uname -s)" in
    Linux*)     OS_TYPE="Linux";;
    Darwin*)    OS_TYPE="Mac";;
    *)          echo "❌ Error: Unsupported operating system."; exit 1;;
esac
echo "🖥️ Detected OS: $OS_TYPE ($OS_ARCH)"


# --- 3. Platform-dependent package installation ---
install_packages() {
    local package
    local -a missing_packages=()
    for package in zsh autojump curl wget git unzip; do
        if ! command -v "$package" >/dev/null 2>&1; then
            missing_packages+=("$package")
        fi
    done
    if [ "${#missing_packages[@]}" -eq 0 ]; then
        echo "✅ Base shell dependencies are already installed."
        return
    fi

    echo "📦 Installing missing dependencies: ${missing_packages[*]}"
    if [ "$OS_TYPE" = "Linux" ]; then
        if ! command -v apt-get >/dev/null 2>&1; then
            echo "❌ Automatic system package installation requires Debian/Ubuntu." >&2
            return 1
        fi
        sudo apt-get update
        sudo apt-get install -y "${missing_packages[@]}"
    elif [ "$OS_TYPE" = "Mac" ]; then
        # Check for Homebrew
        if ! command -v brew >/dev/null 2>&1; then
            echo "❌ Error: Homebrew not found. Please install it from https://brew.sh/ first."
            exit 1
        fi
        brew install "${missing_packages[@]}"
    fi
}

# Make existing user installations visible without sourcing interactive zsh code.
bootstrap_shell_path() {
    local brew_binary
    export PATH="$HOME/.local/bin:$PATH"
    for brew_binary in "$(command -v brew || true)" /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
        if [ -n "$brew_binary" ] && [ -x "$brew_binary" ]; then
            eval "$("$brew_binary" shellenv)"
            break
        fi
    done
    export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
    export FZF_BASE="${FZF_BASE:-$HOME/.fzf}"
    export PATH="$BUN_INSTALL/bin:$FZF_BASE/bin:$PATH"
}

# Download completely before execution; a failed download must stop setup.
run_installer() (
    local url="$1" interpreter="$2" installer
    shift 2
    installer=$(mktemp) || exit
    trap 'rm -f "$installer"' EXIT
    curl --retry 3 --connect-timeout 15 -fsSL "$url" -o "$installer" || exit
    "$interpreter" "$installer" "$@"
)

fzf_version_supported() {
    local version major minor
    command -v fzf >/dev/null 2>&1 || return 1
    version=$(fzf --version) || return 1
    version=${version#fzf }
    version=${version%% *}
    major=${version%%.*}
    minor=${version#*.}
    minor=${minor%%.*}
    [[ "$major" =~ ^[0-9]+$ && "$minor" =~ ^[0-9]+$ ]] || return 1
    (( major > 0 || minor >= 51 ))
}

install_shell_tools() {
    # zoxide upstream recommends its installer over old Debian/Ubuntu packages.
    if command -v zoxide >/dev/null 2>&1; then
        echo "✅ zoxide is already installed."
    elif command -v brew >/dev/null 2>&1; then
        brew install zoxide
    else
        run_installer https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh sh
    fi

    # zi needs fzf >= 0.51.0. Use Homebrew or the upstream binary installer.
    if fzf_version_supported; then
        echo "✅ fzf >= 0.51.0 is already installed."
    elif command -v brew >/dev/null 2>&1; then
        if brew list --versions fzf >/dev/null 2>&1; then
            brew upgrade fzf
        else
            brew install fzf
        fi
    else
        if [ ! -e "$FZF_BASE" ]; then
            git clone --depth 1 https://github.com/junegunn/fzf.git "$FZF_BASE"
        elif [ -d "$FZF_BASE/.git" ]; then
            git -C "$FZF_BASE" pull --ff-only
        else
            echo "❌ $FZF_BASE exists but is not an fzf Git checkout." >&2
            return 1
        fi
        "$FZF_BASE/install" --bin
    fi
    hash -r
    if ! fzf_version_supported; then
        echo "❌ fzf >= 0.51.0 must be first on PATH for zi to work." >&2
        return 1
    fi

    if command -v bun >/dev/null 2>&1; then
        echo "✅ Bun is already installed."
    else
        # BUN_INSTALL/bin is already on PATH, so the installer skips rc edits.
        # Completions are managed by the shared Oh My Zsh bun plugin.
        SHELL=/bin/sh run_installer https://bun.com/install bash
    fi

    zoxide --version
    fzf --version
    bun --version
}

setup_zsh_files() {
    local config_dir="${1:-$HOME}"
    local machine="${SETUP_MACHINE:-}"
    mkdir -p "$config_dir"
    if [ ! -e "$config_dir/.zshrc.local" ] && [ ! -L "$config_dir/.zshrc.local" ]; then
        install -m 600 "$SCRIPT_DIR/.zshrc.local.example" "$config_dir/.zshrc.local"
        echo "🔒 Created $config_dir/.zshrc.local (mode 600)."
    else
        chmod 600 "$config_dir/.zshrc.local"
    fi

    if [ -z "$machine" ] && [ -r "$config_dir/.zsh_machine" ]; then
        if [ "$(tr -d '[:space:]' < "$config_dir/.zsh_machine")" = linux_b ]; then
            machine=linux-lar-pc
        fi
    fi
    if [ -n "$machine" ]; then
        printf '%s\n' "$machine" > "$config_dir/.zsh_machine"
        echo "🖥️ Machine configuration: $machine"
    fi
    create_symlink "$SCRIPT_DIR/.zshrc" "$config_dir/.zshrc"
}

# --- 4. FRIENDLIER Neovim Installation (Using Package Managers) ---
install_neovim() {
    # Check if nvim is installed
    if command -v nvim >/dev/null 2>&1; then
        # Check version
        local current_ver
        current_ver=$(nvim --version | head -n 1 | grep -oE 'v[0-9]+\.[0-9]+')
        
        # Check if version is 0.11 or higher (simple string check for now, can be improved)
        # Matches v0.11, v0.12, etc.
        if [[ "$current_ver" =~ v0\.(1[1-9]|[2-9][0-9]) ]]; then
            echo "✅ Neovim $current_ver is already installed. Skipping."
            return
        fi
        echo "⚠️  Old Neovim version detected ($current_ver). Upgrading to 0.11+..."
    else
        echo "🚀 Installing Neovim..."
    fi

    if [ "$OS_TYPE" = "Linux" ]; then
        echo "🧹 Removing any existing apt neovim..."
        sudo apt-get remove -y neovim neovim-runtime

        # Determine architecture
        local nvim_arch=""
        if [ "$OS_ARCH" = "x86_64" ]; then
            nvim_arch="linux-x86_64"
        elif [ "$OS_ARCH" = "aarch64" ]; then
            nvim_arch="linux-arm64"
        else
            echo "❌ Error: Unsupported architecture for Neovim binary: $OS_ARCH"
            exit 1
        fi

        echo "⬇️ Downloading Neovim latest release (0.11+)..."
        local download_url="https://github.com/neovim/neovim/releases/latest/download/nvim-$nvim_arch.tar.gz"
        
        # Download to /tmp
        if wget -O "/tmp/nvim.tar.gz" "$download_url"; then
            echo "📦 Extracting to /opt/nvim..."
            sudo rm -rf /opt/nvim
            # Extract to /opt
            sudo tar -C /opt -xzf "/tmp/nvim.tar.gz"
            
            # The tarball contains a directory like 'nvim-linux-x86_64'. We rename it to 'nvim' for simplicity
            # or just symlink from it.
            if [ -d "/opt/nvim-$nvim_arch" ]; then
                sudo mv "/opt/nvim-$nvim_arch" /opt/nvim
            fi
            
            # Create symlink
            echo "🔗 Linking /usr/local/bin/nvim..."
            sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
            
            rm "/tmp/nvim.tar.gz"
        else
            echo "❌ Error: Failed to download Neovim."
            exit 1
        fi
        
    elif [ "$OS_TYPE" = "Mac" ]; then
        echo "⬇️ Installing neovim via Homebrew..."
        brew install neovim
    fi
    echo "🎉 Neovim installation complete."
}

# --- 5. Symlink creation function (with English output) ---
create_symlink() {
    local source_file=$1
    local target_file=$2

    # Ensure source file exists
    if [ ! -e "$source_file" ]; then
        echo "⚠️ Warning: Source file not found: $source_file"
        return
    fi

    # Ensure target directory exists
    local target_dir
    target_dir=$(dirname "$target_file")
    mkdir -p "$target_dir"

    # Handle existing target file
    if [ -L "$target_file" ]; then
        # It's already a symlink, just remove it to update
        rm "$target_file"
    elif [ -e "$target_file" ]; then
        # It's a file or directory, back it up
        mv "$target_file" "${target_file}_old"
        echo "💾 Backed up existing $target_file to ${target_file}_old"
    fi

    # Create the symlink
    ln -s "$source_file" "$target_file"
    echo "🔗 Created symlink: $source_file -> $target_file"
}

# --- 6. Oh My Zsh and plugins installation (with English output) ---
install_ohmyzsh_and_plugins() {
    echo "🐚 Installing Oh My Zsh..."
    if [ -d "$HOME/.oh-my-zsh" ]; then
        echo "✅ Oh My Zsh is already installed. Skipping."
    else
        # Run non-interactively
        KEEP_ZSHRC=yes run_installer https://install.ohmyz.sh/ sh --unattended
    fi

    # Use HTTPS for robustness (no SSH key needed)
    local zsh_custom=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
    
    echo "🔌 Installing zsh plugins..."
    
    if [ ! -d "${zsh_custom}/plugins/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions.git "${zsh_custom}/plugins/zsh-autosuggestions"
    else
        echo "✅ zsh-autosuggestions is already installed."
    fi

    if [ ! -d "${zsh_custom}/plugins/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${zsh_custom}/plugins/zsh-syntax-highlighting"
    else
        echo "✅ zsh-syntax-highlighting is already installed."
    fi
}

# =================
#    Execute Script
# =================

# Allow the shell setup functions to be checked without running the full installer.
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
    return 0
fi

SHELL_ONLY=false
SETUP_MACHINE=""
while [ "$#" -gt 0 ]; do
    case "$1" in
        --shell-only) SHELL_ONLY=true; shift ;;
        --machine)
            if [ "$#" -lt 2 ] || [[ ! "$2" =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]*$ ]] || [ ! -f "$SCRIPT_DIR/zsh/$2.zsh" ]; then
                echo "❌ --machine requires an existing name from zsh/<name>.zsh." >&2
                exit 1
            fi
            SETUP_MACHINE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: bash setup.sh [--shell-only] [--machine NAME]"
            echo "  --shell-only   Install zsh plugins, zoxide (z/zi), fzf and Bun only."
            echo "  --machine NAME Select a machine configuration, e.g. linux-lar-pc."
            exit 0
            ;;
        *) echo "❌ Unknown argument: $1" >&2; exit 1 ;;
    esac
done

bootstrap_shell_path
install_packages
install_shell_tools

install_ohmyzsh_and_plugins
setup_zsh_files
if [ "$SHELL_ONLY" = true ]; then
    echo "✅ Shell setup complete. Run 'exec zsh' to load it."
    exit 0
fi

install_neovim
echo "🎨 Installing nvimdots..."
if command -v curl >/dev/null 2>&1; then
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/ayamir/nvimdots/HEAD/scripts/install.sh)"
else
    bash -c "$(wget -O- https://raw.githubusercontent.com/ayamir/nvimdots/HEAD/scripts/install.sh)"
fi

echo "🔗 Creating symlinks for nvim..."
# Use $SCRIPT_DIR for correct pathing
mkdir -p "$HOME/.config/nvim"
create_symlink "$SCRIPT_DIR/nvim/init.lua" "$HOME/.config/nvim/init.lua"

# --- 7. tmux + catppuccin 主题 ---
echo "🖥️ Installing tmux and catppuccin theme..."
if [ "$OS_TYPE" = "Linux" ]; then
    sudo apt-get install -y tmux
elif [ "$OS_TYPE" = "Mac" ]; then
    brew install tmux
fi

mkdir -p "$HOME/.config/tmux"
if [ -d "$HOME/.config/tmux/catppuccin" ]; then
    echo "✅ catppuccin/tmux already exists. Updating tags."
    git -C "$HOME/.config/tmux/catppuccin" fetch --tags
else
    git clone -b v2.1.3 --depth 1 https://github.com/catppuccin/tmux.git "$HOME/.config/tmux/catppuccin"
fi

echo "🔗 Creating symlink for tmux..."
create_symlink "$SCRIPT_DIR/.tmux.conf" "$HOME/.tmux.conf"
# 若有正在运行的 tmux,重新加载配置
tmux info >/dev/null 2>&1 && tmux source-file "$HOME/.tmux.conf"

echo "✅ Dotfiles installation complete!"
echo "🔄 Please restart your terminal or run 'zsh' to apply changes."
