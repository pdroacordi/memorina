---
id: architecture/release-build
type: architecture
title: The release build: one Windows preset, templates, how to export and run it
status: active
tags: [export, release, build, windows, templates, tech-04]
related: [systems/settings, systems/life-benches-death, gotchas/fullscreen-does-nothing-in-an-editor-run]
created: 2026-11-11
updated: 2026-11-11
source_files:
  - export_presets.cfg
  - .gitignore
---

# The release build

## Decisions (user, 2026-11-11)

- Templates: "Pode baixar (Recommended)": the official `Godot_v4.7.2-stable_export_templates.tpz` (1.2 GB, SHA-512 checked against the release's `SHA512-SUMS.txt`), of which only `windows_*` and `version.txt` are installed in `%APPDATA%/Godot/export_templates/4.7.2.stable`.
- Platforms: "Só Windows (Recommended)": one preset.

## The preset (`export_presets.cfg`)

- `Windows Desktop`, x86_64, PCK embedded, no console wrapper, no code signing, S3TC/BPTC textures.
- Exports every resource except `tests/*`, `tools/*`, `docs/*`, `addons/gdUnit4/*`, `reports/*`. Nothing the game loads lives there (checked 2026-11-11: no `res://tools/` or `res://tests/` reference under `scenes/`, `globals/`, `resources/`). `addons/room_maps` stays: its importer is editor-only and costs nothing at runtime.
- Output `builds/windows/memorina.exe` (149 MB on 2026-11-11); `builds/` is git-ignored.

## Export and run

```bash
"$GODOT" --headless --path . --export-release "Windows Desktop" builds/windows/memorina.exe
```

- A release build boots the title (`BootPolicy`: not debug, so `Session.NONE`) and uses `settings.cfg`, not `settings_debug.cfg` (`systems/settings`). Debug-only code (`DebugTrials`, F8-F10) is absent.
- Measured 2026-11-11: the export prints only the known `lake_chasm.room` UID warning and the exit leak lines; the build opened on the title in pt_BR from the OS locale, 1280x720 framed, 311 MB working set after 14 s.
- To run it without touching a player's saves and settings, point `APPDATA` at a scratch folder first.
- The build is the baseline for profiling (TECH-12): measure frame times in it, not in an editor run.
