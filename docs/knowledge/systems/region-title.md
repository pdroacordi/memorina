---
id: systems/region-title
type: system
title: The region title: a region's name and epithet, once, on the first entry
status: active
tags: [ui, hud, region, save, i18n, tween]
related: [systems/rooms, systems/life-benches-death, systems/songs-and-the-memorina, systems/screens, systems/notebook, architecture/notebook-entries-are-derived-from-the-save, gotchas/a-killed-tween-never-emits-finished, gotchas/a-control-is-culled-by-its-own-rect, gotchas/scene-state-lists-only-the-properties-a-scene-file-sets, playtests/2026-10-14-ui10-region-title]
created: 2026-10-14
updated: 2026-10-14
source_files:
  - scenes/ui/region_title/region_title_policy.gd
  - scenes/ui/region_title/region_title_watcher.gd
  - scenes/ui/region_title/region_title.gd
  - scenes/ui/region_title/region_title.tscn
  - scenes/ui/region_title/region_title_ornament.gd
  - scenes/world/rooms/region.gd
  - globals/player_data.gd
  - globals/save_ledger.gd
  - globals/save_system.gd
  - scenes/world/game.tscn
---

# The region title

**Never break:** The first room of a world build is recorded silently, never titled, and the village never titles (`shows_title = false`). A region's title plays once; it reaches the save at the next bench or death, and a death keeps it shown (`SaveLedger.rewind`). Every titled region's name and epithet fit the 300 pack px box in every language of the CSV (`region_title_fit_test`). The title's tween is pausable and scaled, never `set_ignore_time_scale`.

## Summary

UI-10. On the first entry into a region, its name fades in large in the upper middle of the screen over a drawn rule, with a short epithet under it; it holds and fades out while play continues. The pieces follow the notebook's watcher → HUD split (`architecture/notebook-entries-are-derived-from-the-save`): a pure policy decides, a watcher applies it against the save, a HUD node draws.

## Data

- `Region.name_key` (existing) and **`Region.epithet_key`**: the translation key of the line under the name, `REGION_<ID>_EPITHET` in `i18n/translations.csv`. The epithet is data on the region scene, never a branch in code.
- **`Region.shows_title`** (default true) is false on `home_village.tscn` (the user's village decision below) and on the five trial scenes (`REGION_TRIALS`, reached by F10). The village keeps `REGION_HOME_VILLAGE_EPITHET` as data; nothing shows it.
- **`PlayerData.announced_regions: Array[StringName]`** holds region `SceneKey`s. `SaveSystem.is_region_announced(key)` / `announce_region(key)` mirror `mark_notebook_read`: no `progress_changed`, since nothing derives progress from it.
- **Death-proof:** `SaveLedger.rewind` merges the live ids into the committed save before copying it back, beside `notebook_read`, so both deaths keep it. It reaches disk at the next bench or death; a quit before either shows the title once more next session (only benches save).
- An old save loads an empty array. **Seeded from the map:** on the first `room_changed` of a world build the watcher marks as announced every titled region that has a room key with cells in `map_seen`, so a save made before this change, or a dev slot, does not replay titles for regions already explored. Later in the same world the map is not read again.

## Decision and trigger

- **`Game.room_changed(room)`** → `World/RegionTitleWatcher.on_room_changed` (a connection in `game.tscn`, like `MapRevealer` and `RegionWeather`). It fires after a walk-in region cut, after `_land_in` (bench arrival, door) and after a hazard respawn into another room. A door never crosses a region, so a door never titles.
- **`RegionTitlePolicy.decide(shows_title, first_of_world, announced) -> Action`** (pure):
  - `shows_title` false or already announced → NONE (not recorded).
  - The first `room_changed` of a world build → RECORD: a new game, a loaded bench and the world rebuilt after a death never title.
  - Otherwise ANNOUNCE, which records too.
- `RegionTitleWatcher` (pausable, draws nothing) holds `_seeded`, records through `SaveSystem.announce_region`, and on ANNOUNCE emits **`announced(name_key, epithet_key)`** → `CanvasLayer/RegionTitle.show_title`.
- Recorded at ANNOUNCE time, not when the fade ends: a death mid-title still counts it.
- A new game starts in `village_house`; the village has no title, so the first title a player sees is Threshold Road past the east gate.

## The HUD (`RegionTitle`, `scenes/ui/region_title/region_title.tscn`)

- `CanvasLayer/RegionTitle` sits after `Foreground` and before `LessonCinematic` (a lesson's bars and dim cover it) and before `Fade` (a hazard, death or door fade covers it). It is above `Greyhush`, so it draws in colour. Full rect, `mouse_filter` IGNORE, process mode INHERIT (pausable from `Game`).
- It never reads the save or the world: `show_title(name_key, epithet_key)` is its whole interface.
- **Look** (the 2x rule from `systems/screens`): one `Art` root 320x180 at `scale = 2`, a `Card` under it that rises, all in pack px.
  - Name: `memorina_title_outline_font_size_20.ttf` at 20 (40 screen px), cream (0.96, 0.9, 0.72) with a 2 px outline (0.13, 0.08, 0.05), centred in a 300 px box at (10, 26).
  - Rule (`RegionTitleOrnament`, drawn in `_draw`): a 5 px diamond with a 1 px line each side, each `name_width / 2 + 12` px long (capped so it fits 300 px), the outer 6 px dithered every other pixel, every pixel shadowed 1 px below in the outline colour. Line row at y 50. Its rect covers the shadow row.
  - Epithet: `memorina_text_font_size_8.ttf` at 8, same colours with a 2 px outline, in the same box at y 56. An empty `epithet_key` leaves the line empty.
- **Timing** (exports, scaled seconds): `lead_in` 0.3, `fade_in` 0.8 with a `rise` of 3 pack px, `hold` 2.5, `fade_out` 1.0, on `Art.modulate.a`. About 4.6 s in all.
- **One tween, pausable and scaled** (`create_tween()` bound to the node): it stops under a performance freeze (tree paused) and a menu hold (paused, scale 0) and resumes from the same frame. The world map (block, world running) lets it continue under its dim. No input block, no hold.
- **A second `show_title` while one shows:** the tween is killed and `modulate.a` is set explicitly (`gotchas/a-killed-tween-never-emits-finished`), the current card fades out over `fade_out * alpha * 0.5`, the text swaps, and the new one fades in without the lead-in.
- **A hazard fade right after entry** plays the title behind the black (accepted, rare).
- Text through `tr()` into the Labels; no `\n` in these keys.

## Text

`REGION_HOME_VILLAGE`, `REGION_THRESHOLD`, `REGION_FROST_EDGE`, `REGION_SPRING_WOODS`, `REGION_FROZEN_LAKE`, `REGION_WIND_ORCHARDS`, `REGION_SUMMER_CALDERA` (names, existing) and the same ids with `_EPITHET` (new, 2026-10-14, drafts the user may change). After editing the CSV, `--import` rebuilds `translations.<locale>.translation`, which are committed.

## User decisions, 2026-10-14

- "when we enter a new region for the first time, can we show a floating title for dramatic effect or something like that."
- "Big title, first visit (Recommended)": "On the first entry into a region, its name fades in large in the upper middle of the screen with a thin ornament and a smaller line under it (e.g. the season), holds about 2.5 s and fades out. Play continues underneath. Saved per region, so it shows once."
- The village: "No village title (Recommended)": "The game opens in the village without a title; the first title is Threshold Road when you leave it. The village is home, not a discovery." Built as `shows_title = false` on the village, plus the silent first room of every world build.
- The second line: "A short epithet", not the season. Drafts (en / pt_BR):
  - Home Village: "Where the songs were first sung" / "Onde as canções nasceram"
  - Threshold Road: "The road past all you remember" / "A estrada além de tudo o que você lembra"
  - Frost Edge: "Where the world forgot itself first" / "Onde o mundo se esqueceu primeiro"
  - Bloom Woods: "Roots that still remember spring" / "Raízes que ainda lembram a primavera"
  - Frozen Lake: "Still water, stopped in time" / "Água parada, presa no tempo"
  - Wind Orchards: "Every leaf waiting to fall" / "Cada folha à espera de cair"
  - Summer Caldera: "A summer buried under stone" / "Um verão enterrado sob a pedra"
- Survives a death: decided by the orchestrator for the user's "saved per region, so it shows once" (the plan's B-Q2 recommendation); the announced ids are merged in the rewind like `notebook_read`.

## Tests

`tests/scenes/ui/region_title/region_title_policy_test.gd` (the table), `region_title_watcher_test.gd` (fixture regions: first room silent, keys emitted, the save holds the `SceneKey`, back and forth once, a rebuilt world quiet, an untitled region unrecorded even as the first room, regions with rooms in `map_seen` recorded at the first room and only then), `region_title_test.gd` (hidden at rest, translated text, fade in / hold / out, the rule spans the name, a second title replaces the first, a `WorldFreeze.freeze()` stops it), `region_title_fit_test.gd` (every `shows_title` region placed in `game.tscn`, read through `SceneState`: both keys named, filled and inside the box in every CSV locale; the village is untitled), and additions to `save_ledger_test`, `player_data_test` and `save_system_notebook_test`. Playtest: `tools/playtest/scripts/region_title_*.json`.
