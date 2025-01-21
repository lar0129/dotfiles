#!/bin/bash

# 获取当前目录
CURRENT_DIR="$(pwd)"

# 更新软件包列表并安装 zsh 和 neovim
sudo apt-get update
sudo apt-get install -y zsh 

wget https://github.com/neovim/neovim/releases/download/v0.9.5/nvim-linux64.tar.gz
tar -xzvf nvim-linux64.tar.gz
ln -s $CURRENT_DIR/nvim-linux64/bin/nvim /usr/bin/nvim

# 安装 nvimdots 仓库到当前目录
if command -v curl >/dev/null 2>&1; then
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/ayamir/nvimdots/HEAD/scripts/install.sh)"
else
    bash -c "$(wget -O- https://raw.githubusercontent.com/ayamir/nvimdots/HEAD/scripts/install.sh)"
fi

# 定义创建符号链接的函数
create_symlink() {
	local source_file=$1
	local target_file=$2

	# 检查目标文件是否存在（包括符号链接）
	if [ -e "$target_file" ] || [ -L "$target_file" ]; then
		mv "$target_file" "${target_file}_old"
		echo "已将现有的 $target_file 备份为 ${target_file}_old"
	fi

	# 创建符号链接
	ln -s "$source_file" "$target_file"
	echo "已创建符号链接：$source_file -> $target_file"
}

# 为 .zshrc 创建符号链接
create_symlink "$CURRENT_DIR/.zshrc" "$HOME/.zshrc"
source ~/.zshrc

# 确保 ~/.config/nvim 目录存在
mkdir -p "$HOME/.config/nvim"

# 为 init.lua 创建符号链接
create_symlink "$CURRENT_DIR/nvim/init.lua" "$HOME/.config/nvim/init.lua"

#切换shell,安装ohmyzsh
sh -c "$(curl -fsSL https://install.ohmyz.sh/)"

