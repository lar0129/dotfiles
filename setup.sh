#!/bin/bash
# Exit immediately if a command exits with a non-zero status.
set -e

# 1. Get the robust script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
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
    echo "📦 Installing base dependencies (zsh, autojump, curl, wget, git)..."
    if [ "$OS_TYPE" = "Linux" ]; then
        # Assumes Ubuntu/Debian
        sudo apt-get update
        # software-properties-common is needed for add-apt-repository
        sudo apt-get install -y zsh autojump curl wget git software-properties-common
    elif [ "$OS_TYPE" = "Mac" ]; then
        # Check for Homebrew
        if ! command -v brew >/dev/null 2>&1; then
            echo "❌ Error: Homebrew not found. Please install it from https://brew.sh/ first."
            exit 1
        fi
        # 'git' and 'curl' are usually pre-installed on macOS, but 'brew install' is safe.
        brew install zsh autojump curl wget git
    fi
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
        sh -c "$(curl -fsSL https://install.ohmyz.sh/)" "" --unattended
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

install_packages

install_ohmyzsh_and_plugins
echo "🔗 Creating symlinks for zshrc..."
create_symlink "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"


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

echo "✅ Dotfiles installation complete!"
echo "🔄 Please restart your terminal or run 'zsh' to apply changes."
