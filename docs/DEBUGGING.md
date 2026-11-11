# Forever debugging

## First fix: incompatible in the addon list

The original TOC used Interface: 0. The current `QuickParty/QuickParty.toc`
uses 16001 from wowlua 0.13.11's Forever flavor metadata (2026-10-29).

Copy the updated `QuickParty` folder over the installed copy, then completely
exit and restart the game so it rescans the manifest. Enable Quick Party in the
addon list. In a character session, run:

```text
/console scriptErrors 1
/reload
/qp show
```

If still incompatible, run `/dump GetBuildInfo()` while logged in and report
all return values. The fourth is your installed client's interface number.
Also verify the folder is exactly `Interface/AddOns/QuickParty/QuickParty.toc`
inside the Forever client, with no extra nested QuickParty folder.

If the addon loads but a button fails, report the exact Lua error and which
button/target/group state caused it. `/etrace` can inspect the actual game
events. Do not infer API failure from the pre-login incompatible label: Lua
has not loaded at that point.

## Optional wowlua tool

Official resources:

- https://wowlua.dev/docs/guide/install
- https://wowlua.dev/docs/reference/manifest
- https://wowlua.dev/docs/guide/testing
- https://wowlua.dev/docs/guide/debugging

The tool calls Forever `camelot` (alias `forever`). This repository explicitly
targets only that flavor. It does not require converting the addon to a new
language. The existing plain Lua folder remains directly installable.

This checkout has a checksum-verified portable Windows tool under ignored
`.tools/wowlua/wowlua-v0.13.11-x86_64-pc-windows-msvc/wowlua.exe`. From the
repository root in PowerShell:

```powershell
$env:WOWLUA_HOME = Join-Path (Get-Location) '.tools/wowlua-home'
$wowluaTool = '.tools/wowlua/wowlua-v0.13.11-x86_64-pc-windows-msvc/wowlua.exe'
& $wowluaTool check --offline --flavor camelot
& $wowluaTool test --flavor camelot
& $wowluaTool build --offline --flavor camelot
```

The startup test fetches matching Blizzard UI definitions if they are not
already cached; later runs can use `--offline`. It checks the emulated client,
not the live server. Real invitation failures and party-message delivery still
need in-game tests.

For extra in-game instrumentation, copy the complete generated
`dist/dev/QuickParty` folder instead of the source `QuickParty` folder. This
dev build includes `/wl` tools and an additional diagnostics SavedVariable;
the source addon does not. Use one complete folder version at a time. Copying
only the generated TOC will reference missing generated files.
