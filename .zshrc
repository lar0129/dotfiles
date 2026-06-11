# ===================== 跨平台 zsh 配置 =====================
# 机器专属配置放在 dotfiles/zsh/<机器名>.zsh,在本文件末尾按需加载。
#   - macOS         : 自动识别($OSTYPE == darwin*)-> zsh/mac.zsh
#   - Linux(多台) : 读 ~/.zsh_machine 文件内容(如 linux_a / linux_b)
#                     -> zsh/linux_a.zsh 等。该文件不提交到 git,每台机器各放一份。
# ===========================================================

# ---- 代理开关(跨平台,各机器按需调用 proxy_on)----
function proxy_on() {
    export https_proxy="http://127.0.0.1:7890"
    export http_proxy="http://127.0.0.1:7890"
    export all_proxy="socks5://127.0.0.1:7890"
    echo "代理已开启"
}

function ipads_proxy_on() {
    export https_proxy="http://ipads:ipads123@202.120.40.82:11235"
    export http_proxy="http://ipads:ipads123@202.120.40.82:11235"
    echo "ipads代理已开启"
}

function proxy_off() {
    unset https_proxy
    unset http_proxy
    unset all_proxy
    echo "代理已关闭"
}

# ---- 通用 alias ----
alias ll='ls -alh'
alias v='nvim'
alias 666='echo'
alias python='python3'
alias pip='pip3'

# ---- 通用环境变量 ----
export PATH="$HOME/.local/bin:$PATH"
export HF_ENDPOINT=https://hf-mirror.com          # HuggingFace 国内镜像
export TLDR_AUTO_UPDATE_DISABLED=1

# ---- oh-my-zsh ----
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
zstyle ':omz:update' mode disabled                # 关闭自动更新
plugins=(
  git
  extract
  autojump
  zsh-autosuggestions
  zsh-syntax-highlighting
)
source $ZSH/oh-my-zsh.sh

# ===================== 加载机器专属配置 =====================
# 解析 ~/.zshrc 软链接回 dotfiles 仓库目录(纯 zsh,跨平台)
ZSH_DOTFILES="${${(%):-%x}:A:h}"

if [[ -z "$ZSH_MACHINE" ]]; then
  if [[ "$OSTYPE" == darwin* ]]; then
    ZSH_MACHINE=mac
  elif [[ -r "$HOME/.zsh_machine" ]]; then
    ZSH_MACHINE="${$(< "$HOME/.zsh_machine")//[[:space:]]/}"
  fi
fi

if [[ -n "$ZSH_MACHINE" ]]; then
  if [[ -r "$ZSH_DOTFILES/zsh/$ZSH_MACHINE.zsh" ]]; then
    source "$ZSH_DOTFILES/zsh/$ZSH_MACHINE.zsh"
  else
    echo "[zshrc] 未找到机器配置: $ZSH_DOTFILES/zsh/$ZSH_MACHINE.zsh" >&2
  fi
else
  echo "[zshrc] 未识别机器类型,请创建 ~/.zsh_machine (内容如 linux_a)" >&2
fi
