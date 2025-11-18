#!/bin/bash
# 增加 -e，任何命令失败时立即退出
set -e

# 1. 鲁棒的路径获取：获取脚本所在的目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Dotfiles 目录位于: $SCRIPT_DIR"

# 2. OS 及架构检测
OS_TYPE=""
OS_ARCH=$(uname -m)

case "$(uname -s)" in
    Linux*)     OS_TYPE="Linux";;
    Darwin*)    OS_TYPE="Mac";;
    *)          echo "Error: 不支持的操作系统。"; exit 1;;
esac
echo "检测到操作系统: $OS_TYPE ($OS_ARCH)"


# --- 3. 平台相关的包安装 ---
install_packages() {
    echo "正在安装基础依赖包 (zsh, autojump, curl, wget, git)..."
    if [ "$OS_TYPE" == "Linux" ]; then
        # 假设是 Ubuntu/Debian
        sudo apt-get update
        sudo apt-get install -y zsh autojump curl wget git
    elif [ "$OS_TYPE" == "Mac" ]; then
        # 检查 Homebrew
        if ! command -v brew >/dev/null 2>&1; then
            echo "错误: 未找到 Homebrew。请先访问 https://brew.sh/ 安装 Homebrew。"
            exit 1
        fi
        brew install zsh autojump curl wget git
    fi
}

# --- 4. 平台相关的 Neovim 安装 ---
# (更简单的方式是使用 brew install neovim 或 apt install neovim)
# 这里遵循您下载特定 v0.9.5 版本的逻辑
install_neovim() {
    if command -v nvim >/dev/null 2>&1; then
        echo "Neovim 已安装。跳过。"
        return
    fi
    
    echo "正在安装 Neovim v0.9.5..."
    
    # 推荐的安装路径 (用户空间，避免 sudo)
    NVIM_INSTALL_DIR="$HOME/.local"
    NVIM_BIN_DIR="$NVIM_INSTALL_DIR/bin"
    mkdir -p "$NVIM_BIN_DIR"

    local nvim_url=""
    local nvim_archive=""
    local nvim_folder=""

    if [ "$OS_TYPE" == "Linux" ]; then
        nvim_url="https://github.com/neovim/neovim/releases/download/v0.9.5/nvim-linux64.tar.gz"
        nvim_archive="nvim-linux64.tar.gz"
        nvim_folder="nvim-linux64"
    elif [ "$OS_TYPE" == "Mac" ]; then
        if [ "$OS_ARCH" == "arm64" ]; then # Apple Silicon
            nvim_url="https://github.com/neovim/neovim/releases/download/v0.9.5/nvim-macos-arm64.tar.gz"
            nvim_archive="nvim-macos-arm64.tar.gz"
            nvim_folder="nvim-macos-arm64"
        else # Intel
            nvim_url="https://github.com/neovim/neovim/releases/download/v0.9.5/nvim-macos-x86_64.tar.gz"
            nvim_archive="nvim-macos-x86_64.tar.gz"
            nvim_folder="nvim-macos-x86_64"
        fi
    fi

    echo "正在下载: $nvim_url"
    curl -L -o "/tmp/$nvim_archive" "$nvim_url"

    echo "正在解压 Neovim..."
    # -C 指定解压的目标目录
    tar -xzvf "/tmp/$nvim_archive" -C "$NVIM_INSTALL_DIR"
    
    # 5. 使用更安全的符号链接，-f (force) 会覆盖已有的
    ln -sf "$NVIM_INSTALL_DIR/$nvim_folder/bin/nvim" "$NVIM_BIN_DIR/nvim"
    
    # 清理
    rm "/tmp/$nvim_archive"

    echo "Neovim 已安装到 $NVIM_BIN_DIR/nvim"
    echo "请确保 '$HOME/.local/bin' 已经添加到您 .zshrc 的 PATH 环境变量中。"
}

# --- 6. 符号链接函数 ---
create_symlink() {
    local source_file=$1
    local target_file=$2

    # 确保源文件存在
    if [ ! -e "$source_file" ]; then
        echo "警告: 源文件未找到: $source_file"
        return
    fi

    # 确保目标目录存在
    local target_dir
    target_dir=$(dirname "$target_file")
    mkdir -p "$target_dir"

    # 检查目标文件
    if [ -L "$target_file" ]; then
        # 如果已经是符号链接，先删除
        rm "$target_file"
    elif [ -e "$target_file" ]; then
        # 如果是文件或目录，备份
        mv "$target_file" "${target_file}_old"
        echo "已将现有的 $target_file 备份为 ${target_file}_old"
    fi

    # 创建符号链接
    ln -s "$source_file" "$target_file"
    echo "已创建符号链接：$source_file -> $target_file"
}

# --- 7. Oh My Zsh 和插件安装 ---
install_ohmyzsh_and_plugins() {
    echo "正在安装 Oh My Zsh..."
    if [ -d "$HOME/.oh-my-zsh" ]; then
        echo "Oh My Zsh 已安装。跳过。"
    else
        # 添加 --unattended 自动安装，避免交互
        sh -c "$(curl -fsSL https://install.ohmyz.sh/)" "" --unattended
    fi

    # 8. 修改 Git 协议为 HTTPS，更具鲁棒性
    local zsh_custom=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
    
    echo "正在安装 zsh 插件..."
    # 检查插件是否已存在，避免重复克隆
    if [ ! -d "${zsh_custom}/plugins/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions.git "${zsh_custom}/plugins/zsh-autosuggestions"
    else
        echo "zsh-autosuggestions 已安装。"
    fi

    if [ ! -d "${zsh_custom}/plugins/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${zsh_custom}/plugins/zsh-syntax-highlighting"
    else
        echo "zsh-syntax-highlighting 已安装。"
    fi
}

# =================
#    执行安装流程
# =================

install_packages
echo "正在创建符号链接..."
# 使用 $SCRIPT_DIR 保证路径正确
create_symlink "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"

install_ohmyzsh_and_plugins

echo "正在安装 nvimdots..."
install_neovim
if command -v curl >/dev/null 2>&1; then
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/ayamir/nvimdots/HEAD/scripts/install.sh)"
else
    bash -c "$(wget -O- https://raw.githubusercontent.com/ayamir/nvimdots/HEAD/scripts/install.sh)"
fi

create_symlink "$SCRIPT_DIR/nvim/init.lua" "$HOME/.config/nvim/init.lua"

# 9. 移除 source，替换为提示
echo "✅ Dotfiles 安装完成!"
echo "请重启您的终端，或手动运行 'zsh' 来加载新配置。"
