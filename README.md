# dotfiles

dotfiles by lar

## zsh 配置约定:跨平台 + 机器专属

`.zshrc` 只放**跨平台**配置(oh-my-zsh、通用 alias、`proxy_on` / `ipads_proxy_on` / `proxy_off` 等代理函数、通用环境变量)。
机器专属配置(PATH、缓存目录、工具链等)放在 `zsh/<机器名>.zsh`,由 `.zshrc` 末尾按需加载:

- **macOS**:`$OSTYPE == darwin*` 时自动加载 `zsh/mac.zsh`,无需任何标记。
- **Linux(多台)**:读 `~/.zsh_machine` 文件的内容(如 `linux_a`、`linux_b`),加载对应的 `zsh/<内容>.zsh`。
  该标记文件**不提交到 git**,每台机器各放一份,一次性创建:

  ```bash
  echo linux_a > ~/.zsh_machine   # 在 A 机上执行;B 机写 linux_b
  ```

- 临时覆盖:`ZSH_MACHINE=linux_b zsh`。
- 仓库目录通过解析 `~/.zshrc` 软链接得到(`${${(%):-%x}:A:h}`),clone 在任意路径都可用。

新增一台机器时:复制一份 `zsh/linux_b.zsh` 作模板改名提交,并在该机 `~/.zsh_machine` 写入对应名字即可。

## tmux

`.tmux.conf` 使用 catppuccin 主题(`v2.1.3`),由 `setup.sh` 克隆到 `~/.config/tmux/catppuccin`。
