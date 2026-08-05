# Yazi Split Pane Diff Plugin

このリポジトリは、Yazi の `terrakok/split-tabs.yazi` で2ペインのファイルを外部 Diff ツールへ渡す `pane-diff.yazi` プラグインです。

実体と利用手順は [`pane-diff.yazi/README.md`](pane-diff.yazi/README.md) にあります。

## 依存関係

- Git Bash または WSL（Yazi と Git を同じ環境で実行）
- Yazi 26.5.6 以上と、同じバージョンの `ya`
- `terrakok/split-tabs.yazi`
- Yazi と同じ環境の PATH 上にある `git` と、Git に設定した外部 Diff ツール
- Lua（テスト実行時のみ。Yazi 実行時は不要）

バージョン確認:

```bash
yazi --version
ya --version
git --version
git difftool --tool-help
```

## インストール

```bash
ya pkg add terrakok/split-tabs
git clone https://github.com/hironei/yazi_split_pane_diff_plugin.git
cd yazi_split_pane_diff_plugin

if command -v cygpath >/dev/null 2>&1 && [ -n "${APPDATA:-}" ]; then
    yazi_config_dir="$(cygpath -u "$APPDATA")/yazi/config"
else
    yazi_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/yazi"
fi

plugin_dir="$yazi_config_dir/plugins/pane-diff.yazi"
mkdir -p "$plugin_dir"
cp -R ./pane-diff.yazi/. "$plugin_dir/"
```

## 設定

Yazi を実行する環境の `keymap.toml` に次を追加します。Git Bash では Windows 版 Yazi の `%AppData%/yazi/config/keymap.toml`、WSL では `${XDG_CONFIG_HOME:-$HOME/.config}/yazi/keymap.toml` が対象です。

```toml
[[mgr.prepend_keymap]]
on = [ "g", "d" ]
run = "plugin pane-diff"
desc = "Compare files in split panes"
```

Git Difftool の設定例:

```bash
git config --global diff.tool winmerge
git config --global difftool.winmerge.cmd '"C:/Program Files/WinMerge/WinMergeU.exe" "$LOCAL" "$REMOTE"'
git config --global difftool.prompt false
```

詳細なインストール手順、設定、比較対象の決定ルール、制約は [`pane-diff.yazi/README.md`](pane-diff.yazi/README.md) を参照してください。

```text
pane-diff.yazi/
├── main.lua
├── README.md
└── LICENSE
```

モックテストは次で実行できます。

```bash
lua ./tests/test_main.lua
```
