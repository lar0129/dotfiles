# dotfiles

dotfiles by lar

## 安装共享 shell 配置

支持 Debian/Ubuntu 和 macOS（macOS 需先安装 Homebrew）：

```bash
# 只安装 shell 配置和工具
bash setup.sh --shell-only

# 同时选择这台 PC 的机器配置
bash setup.sh --shell-only --machine linux-lar-pc

# 完整安装，还包括原有 Neovim / nvimdots / tmux 配置
bash setup.sh
```

共享安装包括 Oh My Zsh、autojump、命令建议、语法高亮、zoxide、fzf 和 Bun。
已有工具会跳过；fzf 低于 0.51.0 时会升级。zoxide/fzf 优先通过 Homebrew 安装，
没有 Homebrew 时使用官方安装器；Bun 使用官方安装器。
安装器会创建权限为 `600` 的 `~/.zshrc.local`，保留已有私密内容，并连接仓库的 `.zshrc`。

- `z 关键词`：跳转常用目录。
- `zi 关键词`：用 fzf 交互选择目录；`zi` 由 zoxide 提供，无需单独安装。
- `Ctrl-R`：搜索命令历史；`Ctrl-T`：选择文件；`Alt-C`：选择目录。
- `bun`：JavaScript 运行时与包管理器，启用 Oh My Zsh 的 Bun 补全。
- 原有 autojump 的 `j` 命令保留。

安装方式参考 [zoxide](https://github.com/ajeetdsouza/zoxide#installation)、
[fzf](https://github.com/junegunn/fzf#installation) 和 [Bun](https://bun.com/docs/installation)。

## zsh 配置约定：共享、机器专属、私密

| 位置 | 内容 | 提交 Git |
| --- | --- | --- |
| `.zshrc` | 通用 alias、插件、代理函数、Bun/zoxide/fzf，以及按安装情况加载的 nvm/Homebrew/OpenClaw 补全 | 是 |
| `zsh/<机器名>.zsh` | 磁盘和缓存路径、本机工具接入、默认代理策略 | 是 |
| `~/.zsh_machine` | 选择本机配置的名称 | 否 |
| `~/.zshrc.local` | `GH_TOKEN`、`IPADS_PROXY_URL` 等凭据及本机变量覆盖 | 否 |

加载顺序：私密变量 → 通用工具路径 → 机器配置 → Oh My Zsh、补全和 zoxide。
私密变量提前加载，因此可以覆盖 `BUN_INSTALL`、`NVM_DIR`、`CLASHCTL_HOME` 和代理地址。
仓库路径通过 `~/.zshrc` 软链接解析，clone 在任意目录都可用。

- **macOS**：自动选择 `zsh/mac.zsh`。
- **Linux**：读取 `~/.zsh_machine`。`linux_a` 是 GPU/NVMe 机器，`linux-lar-pc` 是 lar PC。
- 原来的 `linux_b` 已更名为 `linux-lar-pc`；运行 setup 会迁移旧标记，shell 也兼容旧名称。
- 没有机器标记时，Linux 只加载共享配置。临时覆盖可用 `ZSH_MACHINE=linux-lar-pc zsh`。

新增机器时，在 `zsh/` 添加只包含机器差异的文件，再运行
`bash setup.sh --shell-only --machine <机器名>`。
clashctl 和 Wave/Codex 通知 hook 留在 `linux-lar-pc`，只在对应脚本存在时加载。

私密配置示例见 [`.zshrc.local.example`](.zshrc.local.example)。手动配置时：

```bash
# 仅在 ~/.zshrc.local 尚不存在时复制
test -e ~/.zshrc.local || install -m 600 .zshrc.local.example ~/.zshrc.local
```

`proxy_on` 默认使用本机 `7890` 端口，可通过 `LOCAL_HTTP_PROXY` / `LOCAL_SOCKS_PROXY` 覆盖。
`ipads_proxy_on` 从私密配置读取 `IPADS_PROXY_URL`；未设置时提示配置，不含内置账号密码。
代理切换保留已有 `NO_PROXY/no_proxy` 规则，并合并本机地址；`proxy_off` 清理大小写代理变量。

## tmux

`.tmux.conf` 使用 catppuccin 主题(`v2.1.3`),由 `setup.sh` 克隆到 `~/.config/tmux/catppuccin`。
