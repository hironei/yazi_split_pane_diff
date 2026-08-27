# Yazi Split Pane Diff

This repository contains `pane-diff.yazi`, a Yazi plugin that sends one file from each of two panes to an external Diff tool configured through Git's `difftool`.

The plugin and its usage guide are in [`pane-diff.yazi/README.md`](pane-diff.yazi/README.md).

## Quick start

1. [Install the packages](pane-diff.yazi/README.md#installation) in the environment where Yazi and Git run.
2. Add the [keymap](pane-diff.yazi/README.md#keymap) to `keymap.toml`.
3. Configure a [Git Difftool](pane-diff.yazi/README.md#git-difftool-configuration).
4. Open two panes, place the cursor on one file in each pane, and press `g`, then `d`.

The detailed manual includes target-selection rules, troubleshooting, known limitations, and the live-validation boundary. Remaining unsupported capabilities are tracked in [Issue #2](https://github.com/hironei/yazi_split_pane_diff/issues/2), while the Yazi 26.8.15 compatibility work is tracked in [Issue #4](https://github.com/hironei/yazi_split_pane_diff/issues/4).

## Requirements

- Git Bash or WSL, with Yazi and Git running in the same environment
- Yazi 26.8.15 and the matching `ya` version (the 26.5.6 API is retained where the older selected-URL shape is naturally compatible)
- `terrakok/split-tabs.yazi`
- `git` and a Git-configured external Diff tool available in the same environment's `PATH`
- Lua only for running the repository's tests; Lua is not required by Yazi at runtime

Check the installed versions:

```bash
yazi --version
ya --version
git --version
git difftool --tool-help
```

## Installation

```bash
ya pkg add terrakok/split-tabs
ya pkg add hironei/yazi_split_pane_diff:pane-diff
```

`ya pkg` downloads and installs the plugin and records the package in `package.toml`. Run `ya pkg upgrade` to update it.

## Configuration

Add the following to the `keymap.toml` used by your Yazi environment. For Git Bash, this is `%AppData%/yazi/config/keymap.toml` for Windows Yazi. For WSL, it is `${XDG_CONFIG_HOME:-$HOME/.config}/yazi/keymap.toml`.

```toml
[[mgr.prepend_keymap]]
on = [ "g", "d" ]
run = "plugin pane-diff"
desc = "Compare files in split panes"
```

Example Git Difftool configuration:

```bash
git config --global diff.tool winmerge
git config --global difftool.winmerge.cmd '"C:/Program Files/WinMerge/WinMergeU.exe" "$LOCAL" "$REMOTE"'
git config --global difftool.prompt false
```

See [`pane-diff.yazi/README.md`](pane-diff.yazi/README.md) for detailed installation steps, configuration, target-selection rules, difftool status handling, limitations, and live-validation boundaries.

```text
pane-diff.yazi/
├── main.lua
├── README.md
└── LICENSE
```

Run the mock tests with:

```bash
lua ./tests/test_main.lua
```

## Contributing

Keep file paths as separate command arguments and preserve the active-pane-first behavior. For plugin changes, run the Lua mock tests and `git diff --check`. Update the English README and plugin manual when behavior, setup, or limitations change. Live Yazi, external Diff GUI, Windows focus, and IME checks must be reported separately from automated test results.
