# Requirements: Yazi 26.8.15 Compatibility and Difftool Status Handling

## Goal

Make `pane-diff.yazi` compatible with the Yazi 26.8.15 `tab.selected` contract and avoid reporting the normal `git difftool --no-index` difference result as a process failure.

## Functional requirements

1. Resolve a selected Yazi `File` entry through its `.url` before validation and command construction.
2. Preserve compatibility with older selected entries that are already URL-like values.
3. Preserve the existing target-selection rules: one selected item takes precedence over the hovered item, no selection uses the hovered item, and multiple selections are rejected.
4. Preserve rejection of directories, broken links, special files, and unavailable targets.
5. Treat exit code 0 and the `--no-index` difference result exit code 1 as expected outcomes.
6. Continue reporting launch failures, wait failures, and other abnormal exit statuses.
7. Keep file paths as separate `Command("git"):arg` arguments.

## Non-functional requirements

- Keep Yazi-version compatibility logic localized to a small adapter.
- Do not add dependencies, fetcher API changes, shell command construction, or unrelated refactoring.
- Document the Yazi 26.8.15 tested baseline and the retained older URL-entry compatibility.
- Keep the live-validation boundary explicit: Lua mocks do not prove Yazi, split-tabs, or Beyond Compare behavior.

## Acceptance criteria

- A Yazi 26.8.15-shaped selected `File` passes its actual URL path to Git.
- Regular-file validation uses the Yazi 26.8.15 `Url.spec.is_regular` shape and retains the older direct-URL fallback.
- A direct URL-shaped selected value remains supported.
- Selected-file, selected-plus-hovered, hovered-only, multiple-selection, and invalid-target behavior is covered by tests.
- Exit codes 0 and 1 do not create a process-failed notification; another abnormal code does.
- Launch and wait failures still create error notifications.
- `lua ./tests/test_main.lua` and `git diff --check` pass.
- Documentation and the `@since` compatibility comment agree with the supported baseline.
