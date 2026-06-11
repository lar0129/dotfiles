# ===== macOS 专属配置 =====
# 由 ~/.zshrc 在 $OSTYPE == darwin* 时自动加载

# Homebrew / 工具链动态库
export DYLD_LIBRARY_PATH="/usr/local/opt/mbedtls/lib:$DYLD_LIBRARY_PATH"
export DYLD_FALLBACK_LIBRARY_PATH="/opt/homebrew/lib:$DYLD_FALLBACK_LIBRARY_PATH"

# PATH:Docker / anaconda / mysql / Antigravity
export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
export PATH="/opt/homebrew/anaconda3/bin:$PATH"
export PATH="/opt/homebrew/opt/mysql@8.0/bin:$PATH"
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

# OpenHarmony hdc
alias hdc="$HOME/Library/OpenHarmony/Sdk/13/toolchains/hdc"

# autojump(Homebrew 安装路径)
[ -f /usr/local/etc/profile.d/autojump.sh ] && . /usr/local/etc/profile.d/autojump.sh

# 本机走本地 clash 代理,如需自动开启取消下一行注释
# proxy_on
