#!/bin/bash

# 遍历当前目录下的所有符号链接
for symlink in *; do
	if [ -L "$symlink" ]; then
		# 获取当前符号链接的目标文件路径
		target=$(readlink "$symlink")

		# 提取目标文件名和路径
		filename=$(basename "$target")
		filepath=$(dirname "$target")

		# 移动符号链接到目标路径，将目标文件移动到当前目录并重命名为原来的符号链接
		mv "$symlink" "$target"
		mv "$target" "$symlink"

		# 创建新的符号链接
		ln -s "$symlink" "$filepath/$filename"
	fi
done
