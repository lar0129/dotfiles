# ===================== 共享 zsh 配置 =====================
# 私密变量: ~/.zshrc.local；机器配置: zsh/<~/.zsh_machine 的内容>.zsh。
# 解析 ~/.zshrc 软链接，仓库可以放在任意目录。
ZSH_DOTFILES="${${(%):-%x}:A:h}"

# ---- 代理开关：保留已有绕过规则，始终加入本机地址 ----
_zsh_proxy_bypass() {
  emulate -L zsh
  local -a hosts
  hosts=(${(s:,:)NO_PROXY} ${(s:,:)no_proxy} localhost 127.0.0.1 ::1)
  typeset -U hosts
  export NO_PROXY="${(j:,:)hosts}"
  export no_proxy="$NO_PROXY"
}

proxy_on() {
  export http_proxy="${LOCAL_HTTP_PROXY:-http://127.0.0.1:7890}"
  export https_proxy="$http_proxy"
  export all_proxy="${LOCAL_SOCKS_PROXY:-socks5h://127.0.0.1:7890}"
  export HTTP_PROXY="$http_proxy" HTTPS_PROXY="$https_proxy" ALL_PROXY="$all_proxy"
  _zsh_proxy_bypass
  echo "代理已开启"
}

ipads_proxy_on() {
  if [[ -z "${IPADS_PROXY_URL:-}" ]]; then
    echo "[zshrc] 请先在 ~/.zshrc.local 中设置 IPADS_PROXY_URL" >&2
    return 1
  fi
  export http_proxy="$IPADS_PROXY_URL" https_proxy="$IPADS_PROXY_URL"
  export HTTP_PROXY="$http_proxy" HTTPS_PROXY="$https_proxy"
  unset all_proxy ALL_PROXY
  _zsh_proxy_bypass
  echo "ipads代理已开启"
}

proxy_off() {
  unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY
  echo "代理已关闭"
}

# 提前加载凭据和路径覆盖，后续初始化只提供默认值。
if [[ -r "${ZSH_LOCAL_CONFIG:-$HOME/.zshrc.local}" ]]; then
  source "${ZSH_LOCAL_CONFIG:-$HOME/.zshrc.local}"
fi
_zsh_proxy_bypass

# ---- 通用 alias ----
alias ll='ls -alh'
alias v='nvim'
alias 666='echo'
alias python='python3'
alias pip='pip3'

# ---- 通用环境变量 ----
typeset -U path PATH
path=("$HOME/.local/bin" $path)
export HF_ENDPOINT="${HF_ENDPOINT:-https://hf-mirror.com}"
export TLDR_AUTO_UPDATE_DISABLED="${TLDR_AUTO_UPDATE_DISABLED:-1}"

# ---- 通用工具路径：先 nvm，再 Homebrew，最后 Bun ----
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  source "$NVM_DIR/nvm.sh"
fi

for _zsh_brew in "${commands[brew]:-}" /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
  if [[ -n "$_zsh_brew" && -x "$_zsh_brew" ]]; then
    eval "$("$_zsh_brew" shellenv zsh)"
    break
  fi
done
unset _zsh_brew

export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
export FZF_BASE="${FZF_BASE:-$HOME/.fzf}"
[[ -d "$FZF_BASE/bin" ]] && path=("$FZF_BASE/bin" $path)
[[ -d "$BUN_INSTALL/bin" ]] && path=("$BUN_INSTALL/bin" $path)

# ---- 机器专属配置：在补全和目录历史初始化前设置 PATH / XDG ----
if [[ -z "${ZSH_MACHINE:-}" ]]; then
  if [[ "$OSTYPE" == darwin* ]]; then
    ZSH_MACHINE=mac
  elif [[ -r "$HOME/.zsh_machine" ]]; then
    ZSH_MACHINE="${$(< "$HOME/.zsh_machine")//[[:space:]]/}"
  fi
fi

# 兼容尚未运行新 setup.sh 的旧机器标记。
[[ "$ZSH_MACHINE" == linux_b ]] && ZSH_MACHINE=linux-lar-pc

if [[ -n "$ZSH_MACHINE" ]]; then
  if [[ -r "$ZSH_DOTFILES/zsh/$ZSH_MACHINE.zsh" ]]; then
    source "$ZSH_DOTFILES/zsh/$ZSH_MACHINE.zsh"
  else
    echo "[zshrc] 未找到机器配置: $ZSH_DOTFILES/zsh/$ZSH_MACHINE.zsh" >&2
  fi
fi

# ---- Oh My Zsh：保留 autojump，同时提供 z / zi ----
export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_THEME="${ZSH_THEME:-robbyrussell}"
zstyle ':omz:update' mode disabled
plugins=(git extract)
(( $+commands[autojump] )) && plugins+=(autojump)
(( $+commands[bun] )) && plugins+=(bun)
(( $+commands[fzf] )) && plugins+=(fzf)
for _zsh_plugin in zsh-autosuggestions zsh-syntax-highlighting; do
  if [[ -r "${ZSH_CUSTOM:-$ZSH/custom}/plugins/$_zsh_plugin/$_zsh_plugin.plugin.zsh" ]]; then
    plugins+=("$_zsh_plugin")
  fi
done
unset _zsh_plugin

if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
else
  autoload -Uz compinit
  compinit
  if (( $+commands[fzf] )); then
    eval "$(fzf --zsh)"
  fi
  if [[ -s "$BUN_INSTALL/_bun" ]]; then
    source "$BUN_INSTALL/_bun"
  fi
fi

# ---- 通用补全和目录跳转（未安装则跳过）----
if [[ -s "$HOME/.openclaw/completions/openclaw.zsh" ]]; then
  source "$HOME/.openclaw/completions/openclaw.zsh"
fi
if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh)"
fi
