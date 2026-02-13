# Oracle Panel System

A persistent floating terminal panel built into the aerospace window manager for ambient intelligence / agent orchestration.

## Custom AeroSpace Build

We run a patched AeroSpace built from source at `/Users/liebl/Documents/tools/AeroSpace`, checked out at tag `v0.20.2-Beta` with a `set-gap` command added. The patch adds ~150 lines across 6 files:

- `Sources/Common/cmdArgs/impl/SetGapCmdArgs.swift` (new)
- `Sources/AppBundle/command/impl/SetGapCommand.swift` (new)
- `Sources/Common/cmdArgs/cmdArgsManifest.swift` (modified)
- `Sources/AppBundle/command/cmdManifest.swift` (modified)
- `Sources/Common/cmdHelpGenerated.swift` (modified)
- `Sources/Cli/subcommandDescriptionsGenerated.swift` (modified)

Rebuild: `cd ~/Documents/tools/AeroSpace && swift build`

Sign and install:
```bash
codesign --force --sign - --entitlements resources/AeroSpace.entitlements .build/debug/AeroSpaceApp
codesign --force --sign - .build/debug/aerospace
cp .build/debug/AeroSpaceApp /Applications/AeroSpace.app/Contents/MacOS/AeroSpace
cp .build/debug/aerospace /opt/homebrew/bin/aerospace
codesign --force --deep --sign - /Applications/AeroSpace.app
```

If accessibility prompt appears after re-signing: `tccutil reset Accessibility bobko.aerospace`, then re-grant in System Settings. If `open /Applications/AeroSpace.app` fails, launch directly: `/Applications/AeroSpace.app/Contents/MacOS/AeroSpace &`

Brew backups at `aerospace.bak` / `AeroSpace.bak`. Restore with `brew reinstall aerospace`.

## Architecture

- Single floating wezterm window that follows across workspaces via `exec-on-workspace-change` hook
- `aerospace set-gap` for instant gap changes without config reload
- Three zoom levels: sidebar (380px), half (854px), full (1718px)
- Window hidden by shrinking to 1x1 at screen bottom-right, shown by restoring size/position

## Scripts

- `oracle-toggle.sh` -- `alt-o`. Visible+focused: hide. Visible+unfocused: focus. Hidden/missing: show/launch. Remembers zoom level.
- `oracle-zoom.sh` -- `alt-shift-o`. Cycles sidebar -> half -> full -> sidebar.
- `oracle-launch.sh` -- Spawns wezterm, detects aerospace window ID (--pid filter with app-name fallback), floats it. One-time cost.
- `oracle-follow.sh` -- Called by `exec-on-workspace-change`. Moves oracle to focused workspace. Only acts when visible.

## State Files (/tmp, ephemeral)

- `/tmp/aerospace-oracle-id` -- aerospace window ID
- `/tmp/aerospace-oracle-pid` -- wezterm-gui PID
- `/tmp/oracle-visible` -- exists when shown
- `/tmp/oracle-zoom-state` -- current zoom level (sidebar/half/full)

## Wezterm Integration

In `.wezterm.lua`, `WEZTERM_ORACLE=1` env var triggers:
- `gui-startup` handler for window creation
- `font_size` override: 13pt instead of 20pt

## Aerospace Config Notes

- `alt-h` uses `--ignore-floating` to skip the oracle when navigating left
- `alt-j/k/l` do NOT use `--ignore-floating` so `alt-l` returns from oracle to tiled windows
- `[[on-window-detected]]` rule for "oracle" title auto-floats as backup
- `exec-on-workspace-change` runs sketchybar update + oracle-follow.sh

## Known Issues

- Window detection in launch script can fail if wezterm takes too long to register; fallback grep for `wezterm-gui` app name resolves this
- osascript resize has ~200ms latency; a native aerospace command for floating window positioning would eliminate this
- `set-gap` only changes in-memory gaps; after aerospace restart, gaps revert to config file values
- macOS clamps window positions, so hiding uses 1x1 shrink at bottom-right rather than off-screen move

## Future Work

- Upstream `set-gap` as a PR to AeroSpace
- Add native aerospace command for floating window position/size (eliminate osascript)
- Build the oracle intelligence layer: agent status, summaries, natural language commands
- Consider a `pin-window` aerospace command to make a window follow across workspaces natively
