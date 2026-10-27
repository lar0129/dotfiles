# ===== lar PC 专属配置 =====
# ~/.zsh_machine 内容为 linux-lar-pc 时加载；凭据放在 ~/.zshrc.local。

# clashctl 只在本机加载一次，并允许私密配置覆盖安装路径。
export CLASHCTL_HOME="${CLASHCTL_HOME:-$HOME/clashctl}"
if [[ -r "$CLASHCTL_HOME/scripts/cmd/clashctl.sh" ]]; then
  source "$CLASHCTL_HOME/scripts/cmd/clashctl.sh"
fi

# Wave Terminal 的 Codex 桌面通知依赖本机 hook。
if [[ -n "${WAVETERM_JWT:-}" && -r "$HOME/.codex/hooks/cache_waveterm_jwt.py" ]] && (( $+commands[python3] )); then
  command python3 "$HOME/.codex/hooks/cache_waveterm_jwt.py" >/dev/null 2>&1
fi
