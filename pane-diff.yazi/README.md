# pane-diff.yazi

Yazi の `terrakok/split-tabs.yazi` で表示した2ペインのカーソル位置、または明示選択したファイルを、Git に設定した外部 Diff ツールで比較するプラグインです。

## 依存関係

| 依存関係 | 必須条件 |
| --- | --- |
| 対象環境 | Git Bash または WSL（Yazi と Git を同じ環境で実行） |
| Yazi | 26.5.6 以上 |
| `ya` | Yazi と同じバージョン（`split-tabs.yazi` の導入に使用） |
| `terrakok/split-tabs.yazi` | 2ペイン表示に必須 |
| Git | Yazi と同じ環境の `git` が PATH にあり、外部 difftool が設定済み |
| Lua | 実行時は不要。リポジトリのモックテスト実行時のみ必要 |

最低限、次のコマンドが成功することを確認してください。

```bash
yazi --version
ya --version
git --version
git difftool --tool-help
```

Yazi 26.5.6 の公式 API と `split-tabs.yazi` の現行実装を基準にしています。Yazi の API は変更される可能性があるため、更新後に動作確認してください。

## インストール

### 1. split-tabs.yazi を導入

Yazi の `ya` パッケージマネージャーで導入します。

```bash
ya pkg add terrakok/split-tabs
```

### 2. pane-diff.yazi を導入

`ya pkg` のサブディレクトリ指定で導入します。

```bash
ya pkg add hironei/yazi_split_pane_diff_plugin:pane-diff
```

`ya pkg` がリポジトリからプラグインを取得し、Yazi のプラグインディレクトリへ配置します。導入情報は `package.toml` に記録されます。更新時は `ya pkg upgrade`、削除時は次を実行します。

```bash
ya pkg delete hironei/yazi_split_pane_diff_plugin:pane-diff
```

### 3. インストール確認

Git Bash で Windows 版 Yazi を使う場合は `%AppData%/yazi/config/plugins/pane-diff.yazi/main.lua`、WSL で Linux 版 Yazi を使う場合は `${XDG_CONFIG_HOME:-$HOME/.config}/yazi/plugins/pane-diff.yazi/main.lua` が存在することを確認します。

同じ設定ディレクトリの `package.toml` に、`hironei/yazi_split_pane_diff_plugin:pane-diff` が記録されていることも確認できます。

Yazi の設定を変更した後は、Yazi を再起動してください。

## キーマップ

Yazi を実行する環境の `keymap.toml` に追加します。Git Bash では Windows 版 Yazi の `%AppData%/yazi/config/keymap.toml`、WSL では `${XDG_CONFIG_HOME:-$HOME/.config}/yazi/keymap.toml` が対象です。

```toml
[[mgr.prepend_keymap]]
on = [ "g", "d" ]
run = "plugin pane-diff"
desc = "Compare files in split panes"
```

`g` プレフィックスが既存設定と競合する場合は、例えば次のように変更してください。

```toml
[[mgr.prepend_keymap]]
on = "D"
run = "plugin pane-diff"
desc = "Compare files in split panes"
```

設定例は [`examples/keymap.toml`](../examples/keymap.toml) にもあります。

## 基本操作

1. `split-tabs.yazi` を有効にして2ペインを表示します。
2. 各ペインで比較したいファイルにカーソルを合わせます。
3. `g` → `d` を押します。

Diff ツールには、実行時のアクティブペインを第1引数、反対側ペインを第2引数として渡します。したがって、アクティブペインを切り替えると引数の順序も反転します。物理的な画面左・右の順序は保証しません。

## 比較対象の決定ルール

各ペインで次の優先順位を使います。

1. 明示選択が1件なら、そのファイルを使います。
2. 明示選択がないなら、カーソル位置のファイルを使います。
3. 明示選択が2件以上なら起動しません。
4. カーソル位置に項目がなければ起動しません。
5. ディレクトリ、解決できないシンボリックリンク、通常ファイルでない項目は起動しません。

選択状態、カーソル位置、Yazi のカレントディレクトリは変更しません。

## Git Difftool の設定

Git 管理外のファイルも比較できるよう、`--no-index` を付けて次の相当コマンドを起動します。

```text
git difftool --no-index --no-prompt -- <active-file> <other-file>
```

例えば WinMerge を Git の difftool に設定する場合:

- Git Bash: Windows 側の WinMerge など、Git Bash から起動できるツールを設定します。
- WSL: WSL 内で起動できる Linux 用 Diff ツールを設定します。Windows 側の実行ファイルを使う場合は、WSL から呼び出せるコマンドを別途用意してください。

```bash
git config --global diff.tool winmerge
git config --global difftool.winmerge.cmd '"C:/Program Files/WinMerge/WinMergeU.exe" "$LOCAL" "$REMOTE"'
git config --global difftool.prompt false
```

設定例の詳細は [`examples/difftool.md`](../examples/difftool.md) を参照してください。パスは `Command:arg` に個別の引数として渡すため、空白・日本語・括弧を含む Windows パスをシェルのクォート処理なしで扱います。

## 通知とトラブルシューティング

- タブ数が2でない: `split-tabs.yazi` を有効にしてください。
- 比較対象がない、複数選択、ディレクトリ: 対象を1ファイルにしてください。
- `git` が見つからない、Git の difftool が未設定: `git --version` と `git difftool --tool-help` を確認してください。
- プロセス起動失敗: Diff ツールの設定、実行ファイルの PATH、Git の difftool 設定を確認してください。

外部プロセスは非同期で起動し、Yazi の非同期 API で終了状態を監視します。プロセスの起動失敗、終了状態の取得失敗、異常終了は通知します。Diff ツールの終了を待つ処理は Yazi 本体の操作をブロックしません。

## 直接起動への拡張

現在の初期実装は Git Difftool 固定です。WinMerge、VS Code、Beyond Compare などを直接起動する場合は、`launch_diff` のコマンドと引数だけを差し替えてください。ファイルパスを文字列連結したシェルコマンドへ変換しないでください。

```lua
Command("code")
	:arg { "--diff", file1, file2 }
	:spawn()
```

## 既知の制約

- 3ペイン以上、3ファイル以上、ディレクトリ再帰比較、Yazi 内部での Diff 表示には対応しません。
- 非アクティブペインの操作や複数選択ファイルの一括比較には対応しません。
- `split-tabs.yazi` の内部状態を直接変更せず、Yazi が公開する `cx.tabs` から2タブを取得します。プラグイン側から `split-tabs.yazi` の物理的な左右対応を取得する公開 API は確認できないため、左右順序は保証しません。
- Yazi の状態情報だけでは、比較直前の削除を事前検出できません。その場合は Git/Diff ツール側の終了状態を Yazi 通知へ出します。

## テスト

Lua のモックテストを次のコマンドで実行できます。

```bash
lua ./tests/test_main.lua
```

Yazi 本体、`split-tabs.yazi` の実画面、Git の実 Difftool GUI、Windows の IME・フォーカス挙動はこのモックテストの対象外です。

## ライセンス

MIT License。全文は [`LICENSE`](LICENSE) を参照してください。
