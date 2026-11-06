# AeroSpace Config

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
