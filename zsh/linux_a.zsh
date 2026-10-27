# ===== Linux A 专属配置(IPADS GPU/NVMe 机器)=====
# 由 ~/.zshrc 在 ~/.zsh_machine 内容为 "linux_a" 时自动加载

# 把包管理器、模型下载、XDG 用户数据放到数据盘
export DATA_DISK_HOME="/mnt/nvme2/lar"
export PYTHONUSERBASE="$DATA_DISK_HOME/.local"
export XDG_CACHE_HOME="$DATA_DISK_HOME/.cache"
export XDG_DATA_HOME="$DATA_DISK_HOME/.local/share"
export XDG_STATE_HOME="$DATA_DISK_HOME/.local/state"
export XDG_BIN_HOME="$DATA_DISK_HOME/.local/bin"

export UV_CACHE_DIR="$XDG_CACHE_HOME/uv"
export UV_PYTHON_INSTALL_DIR="$XDG_DATA_HOME/uv/python"

export HF_HOME="$XDG_CACHE_HOME/huggingface"
export HF_HUB_CACHE="$HF_HOME/hub"
export HUGGINGFACE_HUB_CACHE="$HF_HOME/hub"
export TRANSFORMERS_CACHE="$HF_HOME/transformers"
export HF_DATASETS_CACHE="$HF_HOME/datasets"

export PIP_CACHE_DIR="$XDG_CACHE_HOME/pip"

# 临时文件 / JIT 编译缓存放到 NVMe 数据盘
export TMPDIR="/mnt/nvme2/lianganran/tmp"
export TRITON_CACHE_DIR="$TMPDIR/triton_cache"
export TORCH_EXTENSIONS_DIR="$TMPDIR/torch_extensions"
export CUDA_CACHE_PATH="$TMPDIR/cuda_cache"

# 把数据盘 bin 目录加入 PATH(去重)
case ":$PATH:" in
  *":$XDG_BIN_HOME:"*) ;;
  *) export PATH="$XDG_BIN_HOME:$PATH" ;;
esac

# 默认开启本地代理
proxy_on
