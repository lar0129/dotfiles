#!/bin/bash
# Exit immediately if a command exits with a non-zero status.
set -e

# 1. Get the robust script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Dotfiles directory is at: $SCRIPT_DIR"

# 2. Detect OS and architecture
OS_TYPE=""
OS_ARCH=$(uname -m)

case "$(uname -s)" in
    Linux*)     OS_TYPE="Linux";;
    Darwin*)    OS_TYPE="Mac";;
    *)          echo "Error: Unsupported operating system."; exit 1;;
esac
echo "Detected OS: $OS_TYPE ($OS_ARCH)"


# --- 3. Platform-dependent package installation ---
install_packages() {
    echo "Installing base dependencies (zsh, autojump, curl, wget, git)..."
    if [ "$OS_TYPE" == "Linux" ]; then
        # Assumes Ubuntu/Debian
        sudo apt-get update
        # software-properties-common is needed for add-apt-repository
        sudo apt-get install -y zsh autojump curl wget git software-properties-common
    elif [ "$OS_TYPE" == "Mac" ]; then
        # Check for Homebrew
        if ! command -v brew >/dev/null 2>&1; then
            echo "Error: Homebrew not found. Please install it from https://brew.sh/ first."
            exit 1
        fi
        # 'git' and 'curl' are usually pre-installed on macOS, but 'brew install' is safe.
        brew install zsh autojump curl wget git
    fi
}

# --- 4. FRIENDLIER Neovim Installation (Using Package Managers) ---
install_neovim() {
    if command -v nvim >/dev/null 2>&1; then
        echo "Neovim is already installed. Skipping."
        return
    fi
    
    echo "Installing Neovim..."

    if [ "$OS_TYPE" == "Linux" ]; then
        echo "Adding Neovim stable PPA..."
        # This PPA is the official recommended way for Ubuntu
        sudo add-apt-repository ppa:neovim-ppa/stable -y
        sudo apt-get update
        echo "Installing neovim via apt..."
        sudo apt-get install -y neovim
        
    elif [ "$OS_TYPE" == "Mac" ]; then
        echo "Installing neovim via Homebrew..."
        brew install neovim
    fi
    echo "Neovim installation complete."
}

# --- 5. Symlink creation function (with English output) ---
create_symlink() {
    local source_file=$1
    local target_file=$2

    # Ensure source file exists
    if [ ! -e "$source_file" ]; then
        echo "Warning: Source file not found: $source_file"
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
        echo "Backed up existing $target_file to ${target_file}_old"
    fi

    # Create the symlink
    ln -s "$source_file" "$target_file"
    echo "Created symlink: $source_file -> $target_file"
}

# --- 6. Oh My Zsh and plugins installation (with English output) ---
install_ohmyzsh_and_plugins() {
    echo "Installing Oh My Zsh..."
    if [ -d "$HOME/.oh-my-zsh" ]; then
        echo "Oh My Zsh is already installed. Skipping."
    else
        # Run non-interactively
        sh -c "$(curl -fsSL https://install.ohmyz.sh/)" "" --unattended
    fi

    # Use HTTPS for robustness (no SSH key needed)
    local zsh_custom=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
    
    echo "Installing zsh plugins..."
    
    if [ ! -d "${zsh_custom}/plugins/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions.git "${zsh_custom}/plugins/zsh-autosuggestions"
    else
        echo "zsh-autosuggestions is already installed."
    fi

    if [ ! -d "${zsh_custom}/plugins/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${zsh_custom}/plugins/zsh-syntax-highlighting"
    else
        echo "zsh-syntax-highlighting is already installed."
    fi
}

# =================
#    Execute Script
# =================

install_packages
install_neovim

echo "Installing nvimdots..."
if command -v curl >/dev/null 2>&1; then
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/ayamir/nvimdots/HEAD/scripts/install.sh)"
else
    bash -c "$(wget -O- https://raw.githubusercontent.com/ayamir/nvimdots/HEAD/scripts/install.sh)"
fi

echo "Creating symlinks..."
# Use $SCRIPT_DIR for correct pathing
create_symlink "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"
create_symlink "$SCRIPT_DIR/nvim/init.lua" "$HOME/.config/nvim/init.lua"

install_ohmyzsh_and_plugins

echo "✅ Dotfiles installation complete!"
echo "Please restart your terminal or run 'zsh' to apply changes."
