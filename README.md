# Yazi Split Pane Diff Plugin

このリポジトリは、Yazi の `terrakok/split-tabs.yazi` で2ペインのファイルを外部 Diff ツールへ渡す `pane-diff.yazi` プラグインです。

実体と利用手順は [`pane-diff.yazi/README.md`](pane-diff.yazi/README.md) にあります。

## 依存関係

- Windows 11（初期対象）
- Yazi 26.5.6 以上と、同じバージョンの `ya`
- `terrakok/split-tabs.yazi`
- PATH 上の `git` と Git に設定した外部 Diff ツール
- Lua（テスト実行時のみ。Yazi 実行時は不要）

バージョン確認:

```powershell
yazi --version
ya --version
git --version
git difftool --tool-help
```

## インストール

```powershell
ya pkg add terrakok/split-tabs
git clone https://github.com/hironei/yazi_split_pane_diff_plugin.git
Set-Location .\yazi_split_pane_diff_plugin

$pluginDir = Join-Path $env:APPDATA "yazi\config\plugins\pane-diff.yazi"
New-Item -ItemType Directory -Force $pluginDir | Out-Null
Copy-Item -Recurse -Force .\pane-diff.yazi\* $pluginDir
```

## 設定

`%AppData%\yazi\config\keymap.toml` に次を追加します。

```toml
[[mgr.prepend_keymap]]
on = [ "g", "d" ]
run = "plugin pane-diff"
desc = "Compare files in split panes"
```

Git Difftool の設定例:

```powershell
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

```powershell
lua .\tests\test_main.lua
```
