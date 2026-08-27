# Design: Yazi 26.8.15 Compatibility and Difftool Status Handling

## Scope

Update the existing Lua plugin, its mock tests, and English documentation. No dependency, public plugin command, or fetcher behavior changes are required.

## Selected-entry normalization

Add a local `resolve_url` helper at the selection boundary. It returns `entry.url` for the Yazi 26.8.15 `File` shape and returns the entry itself for the older direct URL shape. `validate_url` receives only this resolved value, so regular-file validation and string conversion do not operate on the `File` wrapper.

The helper is intentionally version-free: the presence of `.url` selects the new representation, while the fallback preserves the earlier representation. The active-pane-first ordering and separate command arguments remain unchanged.

For the resolved URL, validation reads `spec.is_regular` on Yazi 26.8.15 and falls back to the older direct `is_regular` field when no spec is present. This avoids the 26.8.15 deprecation warning without introducing version branches.

## Difftool exit-status handling

`git difftool --no-index --no-prompt -- <file1> <file2>` can finish with status code 1 when the compared files differ. `monitor_diff` therefore accepts a successful status or code 1, while retaining an error notification for every other non-success status. Launch and wait errors remain separate error paths.

The child status API does not expose whether an external tool independently chose code 1, so the implementation documents and recognizes only the code 1 result of this fixed `--no-index` invocation. Codes other than 1 are never suppressed.

## Test seams and traceability

- Mock selected entries model both Yazi 26.8.15 `File` values and older direct URL values.
- Mock child statuses cover 0, 1, and another abnormal code, plus launch and wait failures.
- Existing path-preservation and target-validation cases remain in the same test harness.
- User-facing documentation describes the compatibility adapter, status semantics, and live Yazi/Beyond Compare acceptance boundary.
