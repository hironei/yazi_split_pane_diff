# Git Difftool examples

`pane-diff.yazi` runs the following argument-safe command:

```text
git difftool --no-index --no-prompt -- <active-file> <other-file>
```

## WinMerge

```bash
git config --global diff.tool winmerge
git config --global difftool.winmerge.cmd '"C:/Program Files/WinMerge/WinMergeU.exe" "$LOCAL" "$REMOTE"'
git config --global difftool.prompt false
```

## Visual Studio Code

```bash
git config --global diff.tool vscode
git config --global difftool.vscode.cmd 'code --diff "$LOCAL" "$REMOTE"'
git config --global difftool.prompt false
```

## Beyond Compare

```bash
git config --global diff.tool bcompare
git config --global difftool.bcompare.cmd '"C:/Program Files/Beyond Compare/BCompare.exe" "$LOCAL" "$REMOTE"'
git config --global difftool.prompt false
```

Use `git difftool --tool-help` to check the tools Git can find. The plugin does not invoke `cmd.exe /c`, `sh -c`, or a shell-built command line.
