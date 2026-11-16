---
id: playtests/2026-11-16-snd01-sound-effects
type: playtest
title: SND-01 sound effects from a cue log - menus, doors, jump, combat, muffle and death all fire on time; footsteps are silent on real room ground (quadrant lookup)
status: active
build: b191ba84 (imported 2026-11-16 before the first run; no file under scenes/resources/globals changed after the import)
area_tested: "tools/playtest/scripts/snd01_cue_log_driver.gd (a -s driver around the runner, logs every SfxEmitter.cue_played) with three timelines: snd01_sound_cues.json (solstice trial earth, door trial stone, front door, pause menu, notebook, forced death), snd01_water_and_combat.json (forced shallow water, the frost_shore crab), snd01_boar_and_real_floors.json (threshold_bridge boar kill, lake_shore floor)."
tags: [snd-01, audio, sfx, footsteps, menu-sounds, muffle, playtest]
related: [systems/sound-effects, architecture/sound-effects-system, bugs/ivo-steps-and-soft-landings-are-silent-on-room-ground, gotchas/tilemaplayer-body-rid-names-a-physics-quadrant-not-a-cell, gotchas/an-audio-player-that-cannot-process-still-starts-a-voice]
created: 2026-11-16
updated: 2026-11-16
ratings: { fun: 0, fluidity: 0, aesthetics: 0 }
screenshots:
  - screenshots/2026-11-16-snd01-sound-effects/a02_door_fade.png
  - screenshots/2026-11-16-snd01-sound-effects/a03_pause.png
  - screenshots/2026-11-16-snd01-sound-effects/a06_notebook_page.png
  - screenshots/2026-11-16-snd01-sound-effects/b01_wading.png
  - screenshots/2026-11-16-snd01-sound-effects/c01_fight.png
---

# SND-01: sound effects, verified from a cue log

## Summary

Nothing was heard. Every result below comes from a cue log. A dev-only `-s` driver,
`tools/playtest/scripts/snd01_cue_log_driver.gd`, hooks `node_added` and connects to every `SfxEmitter` (group
`sfx_emitters`). Each `[sfx]` line prints:
- the cue path, real ms, frame, owner, bus, pause and `Engine.time_scale`;
- Ivo's pos, vel, clip, clip position, `floor_surface()`, process mode and hp;
- a cross-check: the surface of the `Solid` cell under his feet, looked up by position, beside the cell that `get_coords_for_body_rid` names.

`[muf]` prints every change of the `SfxWorld` low-pass, and `[voices]` lists every SFX player still playing,
every 0.5 s. Four windowed runs, each with a redirected `APPDATA`. No SCRIPT ERROR. The only engine output was
the usual lake_chasm invalid-UID warning and the "resources still in use at exit" message.

**One real bug, already filed by the reviewer:** Ivo's footsteps and soft landings are silent on real room
ground (`bugs/ivo-steps-and-soft-landings-are-silent-on-room-ground`, `step_surface_probe.gd:22`). This run adds
the in-game evidence. Everything else fired at the right moment.

Ratings are 0 because sound feel cannot be judged from a log.

## Verified from the cue log

| Check | Result |
|---|---|
| Run on earth (solstice trial) | `step_earth` on clip contacts 0 and 0.417 s of the 0.667 s run, so 3 steps/s, with gaps alternating 0.417 / 0.25 s; the first step plays as the clip starts. |
| Run on stone (door trial) | `step_stone`, same cadence, `surf=STONE`. |
| Partial stick tilt (0.55, 84 px/s) | Still the `run` clip at the same 3 steps/s. `WALK` is chosen only for a scripted stroll (`is_strolling` needs the `ScriptedController`), so the walk contacts (2.5/s) are never heard in play. |
| Shallow water (**forced**: a `water_shallow.tscn` body added by the driver at x 10700..10860) | `step_water` on both contacts inside it and `step_earth` as he left it. A jump taken inside it reported `surf=SHALLOW_WATER`. No splash fired on walking in (the forced body has no floor data); not judged. |
| Jump and landing | `jump` on the press; `land_earth` (soft) on touchdown 1.15 s later. A hard landing was not tested. |
| Sword on the boar (threshold_bridge) | `swing` on each phase, `struck` (BodySounds) twice, then `creature_death` on the killing hit, with no `struck` after it. |
| Sword on the crab (frost_shore) | Every frontal hit gave `blocked` (front guard) and Ivo's `hurt` on its pinches. The crab never died, so no kill there. |
| Front door | `door_open` (SfxWorld) on the Up press, with Ivo still PAUSABLE (pmode 0). `door_close` 0.50 s later with Ivo DISABLED (pmode 4) during the fade, at the inside door. Both voices were still playing together 0.4 s after the close (open at 0.96 s, close at 0.42 s), so the open cue is not cut by the fade. |
| Pause menu | Escape gave `open` with paused=true and ts=0.00. Down gave `move`, Enter on Settings gave `confirm`, Escape gave `back`, Up gave `move`, and Enter on Resume gave `close` (not `confirm`), with paused=false on the same frame. |
| Notebook | E gave `open` (paused). Right twice gave `page` twice. Escape gave `close` ~0.4 s later, as the book lands shut. |
| Muffle | Cutoff on: 3200 Hz in the trials (memory 0.35; the formula gives 3.2 kHz), 2800 on threshold_bridge, 1400 on frost_shore, 11400 in village_house. |
| Death (**forced**: `Health.take_damage(999)` from the driver) | `death` once. After the `game.tscn` swap, the muffle was off at 20000 Hz on the first frame (`_exit_tree`), then 11400 from the next frame in the new room. `[voices]` showed nothing playing after the death voice ended (0.34 s). |

## Bug: footsteps on real room ground (in-game evidence)

The reviewer's entry was confirmed in game.
- On threshold_bridge, Ivo ran and fought for ~4 s with no step cue. The driver's cross-check printed
  `surf=NONE true=STONE cell=(24, 5) rid_coords=(1, 0)(NONE)`.
- On lake_shore, a 2 s run right and a 3 s run left gave **zero** step cues.
- On frost_shore, the steps sounded at x < 8832 (quadrant (0,0) maps to cell (0,0), a stone wall) and went silent
  from x 8834 (quadrant (1,0) maps to cell (1,0), air).
- The trials sounded correct only by coincidence. Their origins put the floor row at layer row 0, so quadrant (0,0)
  and (1,0) land on floor cells.

Treat any "steps work" claim from a trial as void until the fix. Re-check on lake_shore and threshold_bridge.

## Not judged (needs a human ear)

- Loudness and mix: steps at -8 dB against the music, menu levels, the muffle curve's depth at 1.2-3 kHz, the door
  open and close overlap, and whether the 0.417 / 0.25 s run cadence (from the art's contacts) sounds like a limp.
- Positional panning of the boar and the splash.
- Latency between a press and its sound. Only the frame of `play()` is known (the jump's `play` is on the press
  frame).
- Not covered: the hard landing, climbing, the knock, takes, the bench rest, the notice slide, guardians, and a
  splash in a real pool.

## Screenshots

- `a02_door_fade.png`: the fade into the door trial interior, when `door_close` starts.
- `a03_pause.png`: the pause menu under the hold.
- `a06_notebook_page.png`: the notebook after two page turns.
- `b01_wading.png`: the **forced** shallow body (drawn as a floating grey slab: no floor data).
- `c01_fight.png`: threshold_bridge stone, where the steps were silent.
