# ===== Linux B 专属配置(占位模板)=====
# 由 ~/.zshrc 在 ~/.zsh_machine 内容为 "linux_b" 时自动加载

# clashctl
[ -f "$HOME/clashctl/scripts/cmd/clashctl.sh" ] && . "$HOME/clashctl/scripts/cmd/clashctl.sh"

# nvm: keeps npm global tools, such as codex, on PATH.
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# OpenClaw completion
[ -s "$HOME/.openclaw/completions/openclaw.zsh" ] && source "$HOME/.openclaw/completions/openclaw.zsh"

# Homebrew is loaded after nvm to match ~/.bashrc precedence for node/npm.
if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"
fi
