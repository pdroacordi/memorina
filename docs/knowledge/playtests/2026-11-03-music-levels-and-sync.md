---
id: playtests/2026-11-03-music-levels-and-sync
type: playtest
title: Music levels and sync measured by bus peaks (regions, Bloom fight, title, pause, lesson cues, call notes)
status: active
tags: [music, audio, buses, ducking, guardian-calls, note-cues, regions, title, pause]
related: [systems/music, systems/songs-and-the-memorina, systems/guardians, bugs/region-scenes-set-music-before-their-script-so-no-region-plays-a-theme]
created: 2026-11-03
updated: 2026-11-03
source_files:
  - globals/music/music.gd
  - globals/music/music_mix.gd
  - scenes/world/rooms/region_music.gd
  - scenes/characters/guardians/guardian_music.gd
  - scenes/characters/components/song_performance.gd
  - tools/playtest/scripts/audio_probe.gd
---

## What was run

Windowed runs (`$GODOT` console exe, not headless), with `APPDATA` redirected per run. A new dev-only probe,
`tools/playtest/scripts/audio_probe.gd`, logs every 0.1 real s:

- the max bus peak over the window (`AudioServer.get_bus_peak_volume_{left,right}_db`, the louder of L/R) for Master,
  Music, Notes and Sfx;
- the `Music` autoload's decks: cue, position, `stream_paused`, `volume_db`, gain, stems and duck.

Drivers: `audio_probe_driver.gd` (the runner or the title) and `audio_fight_driver.gd` (the GRD-08 talk bot plus the
probe). No game code was touched.

| Run | What | Build |
|---|---|---|
| region1-3 | village lane west (-1100, 280) walking west into woods_edge, pause | HEAD 74e19fb9 |
| region4 | same walk; the probe patches each Region's `music` at runtime; `restore_guardian(BLOOM)` at 16.9 s; pause | HEAD plus a sibling's uncommitted `music.gd` (13:13) and `guardian_music.gd` (13:12) |
| bloom1 | Bloom fight bot (`BOT_GOD=1`) at (-6560, 284): pause during the first lucid lead-in, two calls, restore, lesson | same as region4 |
| title1 | boot with `--title`, empty save, Enter at 8.7 s (New game) | same as region4 |

## Findings

### FAIL: no region theme ever plays (scenarios a and b as shipped)

`Region.music` is null at runtime in all six regions. Each region `.tscn` writes `music =` above `script =`, so the value
is dropped before the script exists. Results:

- zero music requests;
- the Music bus reads -200 dB for 20 s across the village and the woods;
- silence after the title's New game and after the Bloom restore.

Filed as `bugs/region-scenes-set-music-before-their-script-so-no-region-plays-a-theme`.

### Regions with the cue patched in at runtime (region4: what the design does once fixed)

| Phase | Music peak max / median (dBFS) | Stems / deck |
|---|---|---|
| Village fade-in (3.0-4.6 s) | -13.9 / -19.9 | base 1.0, memory 0.64 (memory 0.8 squared), gain rising 1/3 per s |
| Seam crossfade (4.6-7.7 s) | -10.4 / -15.0 | woods gain 0.03 to 1.00 in 3.0 s; village 0.61 to 0 in ~1.8 s (it was still fading in) |
| Woods, grey (7.7-16.9 s) | -4.9 / -11.4 | memory stem 0.16 (memory 0.4 squared) |
| Memory lifting (16.9-26.5 s) | -4.3 / -10.1 | region memory 0.40 to 1.00, linear over 6.0 s; stem 0.16 to 0.95 by 26.5 s |
| Woods restored (29.7-33 s) | -7.4 / -10.6 | memory stem 1.00 |

- **Crossfade on the border: PASS.** It takes 3 s, both decks are audible together, and there is no gap. The new region's
  theme starts from 0.
- **Memory stem rises without a restart: PASS.** The playback position rose steadily from 12.63 to 24.68 s through the lift.
- **The stem trails the memory.** It reaches 1.0 about 4.4 s of unpaused time after the memory does, 10.4 s after the
  restore, because each `memory_changed` restarts a 4 s follow. That matches "follows over 4 real seconds", but the whole
  rise takes ~10 s, not ~4 s.
- **The full memory stem raises the median bus peak by only about 1 dB.** Only listening can tell whether that is audible
  as "colour returning".

### Guardian fight (Bloom, bloom1)

| Phase | Music max / median | Notes max / median | Music - Notes (windows with Notes > -20 dB) |
|---|---|---|---|
| Fight start (DORMANT to PRESSURE at 3.19 s) | deck fades in to 0 dB in 1.0 s | silent | - |
| PRESSURE 1 | -3.6 / -7.2 | silent | - |
| Lucid, before the first note (duck -6, lead 0) | -11.5 / -13.9 | silent | - |
| Call 1 (6 notes) | -12.0 / -15.6 | -6.9 / -8.6 | median -7.5 dB, worst -1.0 dB |
| Echo 1 (player's answer) | -13.2 / -15.4 | -6.0 / -28.5 | median -7.7, worst +3.6 (a note's tail) |
| RELAPSE (lead back over 1 s, unducked) | -4.9 / -8.1 | -13.2 / -23.4 | median +7.8, worst +11.1 |
| PRESSURE 2 | -2.8 / -7.2 | -14.1 / -29.5 | +8.1 (the relapse groan's tail) |
| Lucid 2, before the first note | -7.8 / -13.9 | silent | - |
| Call 2 | -12.2 / -15.4 | -6.9 / -8.6 | median -7.2, worst -2.3 |
| Echo 2 | -11.9 / -14.9 | -6.0 / -29.1 | median -8.2, worst +1.5 |
| Restored (46.59 s) | released: deck 0 to -5.2 dB in 0.07 s, silent by 47.8 s | - | - |

- **Fight music starts on DORMANT to PRESSURE: PASS.**
- **Lucidity: PASS.** At `lucid_landed` the lead stem goes from 1 to 0 and the duck reaches -6.0 dB within 0.5 s. The median
  bus peak drops 6.7 dB (-7.2 to -13.9).
- **Call end: PASS.** `call_ended` returns the duck to 0 and the lead to 1.0 in about 1 s.
- **Music stays under the notes: PASS.** During calls and echoes the Notes peaks sit 7-8 dB (median) above Music. In no
  window did Music exceed a live call note.
- **Concern (not a fail): the RELAPSE groan may be buried.** `mistake_low` on Notes peaks at -13 dB while the music is
  back at full (-5), 8-11 dB under the music. If the groan is meant to read, it does not. Needs ears.
- **No clipping.** Master peaked at -2.8 dBFS over the fight. The loudest peak anywhere this session was -2.0 dBFS (Sfx,
  after the title).
- **Silence after the restore.** The Bloom region's theme should take over at REGION layer, but cannot because of the
  region bug.
- **The lesson is much quieter than the fight.** Song of the Green Reaching peaks at -15.2 on Notes (median -22.8), and
  Music is silent (the tree is frozen). That is about 16 dB below the fight music's median a second earlier. Only listening
  can tell whether the drop reads as an intended quiet or as a mastering mismatch.

### Call notes and the HUD pop: PASS

For all 12 call notes, `Guardian.call_note_sung` and `Player.call_note_sounded` fired on the same process frame. The second
drives `GuardianCallHud.on_call_note_sounded` (the light and the pop). Frames: 2171, 2261, 2861, 2955, 3053, 3153, 6214,
6305, 6396, 6490, 6581, 6676.

At each signal the voice was already playing the right sample on the Notes bus (position 0.003 s): `call_bloom_down_c`,
`left_d`, `right_e` or `up_g`. Notes were 0.55-0.56 s apart.

### Lesson glyphs vs `note_cues`: PASS on the clock; the audio alignment is low confidence

`Song.note_cues` = 0.64, 1.04, 1.43, 1.83, 2.22, 2.61 (`resources/songs/root.tres`).

| Note | Cue (s) | Glyph lit at stream pos (latency-corrected) | Lit - cue | Notes-bus rise estimate | Lit - rise |
|---|---|---|---|---|---|
| 1 | 0.64 | 0.641 | +1 ms | 0.53-0.66 (-62 to -30 dB) | inside the attack |
| 2 | 1.04 | 1.042 | +2 ms | 0.885 (+4.3 dB) | +157 ms |
| 3 | 1.43 | 1.434 | +4 ms | 1.358 (+2.9 dB) | +76 ms |
| 4 | 1.83 | 1.830 | 0 ms | 1.805 (+2.5 dB) | +25 ms |
| 5 | 2.22 | 2.224 | +4 ms | 2.174 (+4.8 dB) | +50 ms |
| 6 | 2.61 | 2.612 | +2 ms | 2.634 (+2.5 dB) | -22 ms |

- Each glyph lights within one frame (0-4 ms) of its cue on the corrected playback clock. Output latency read 10 ms.
- The "rise" column is not a reliable onset. It comes from the smoothed bus peak meter on a legato flute, and notes 2-6
  move the meter only 2.5-5 dB.
- To check that the cues match the audible attacks, run an offline onset analysis of the decoded track, or listen.

### Title (title1): PASS

- `menu_title` fades in to full gain in about 1.5 s. The Music peak runs -4.5 to -12 dB (median about -8).
- Enter (New game) releases it: gain falls from 0.98 to 0.18 in 0.4 s. Then the load hitch (2 s with no frame) and silence.
- Not tested: "plays under the slot screen". An empty save starts a new game directly, so the slot screen never opened.

### Pause menu: PASS

Checked in two runs:

- On Escape the live deck goes `stream_paused=true` and its position freezes: 13.58 s in the fight, 21.96 s in the woods.
  Every bus reads -200 dB.
- On resume it continues from 13.90 / 22.18 s at the next window, with no restart.
- The stem fade and the duck freeze with it: the memory stem held 0.95 through a 3 s pause.

## What measurement cannot show

- **Whether any of this sounds good.** That includes the balance between the fight bed and a flute, whether a -6 dB duck
  is enough, whether the region themes keep the grey feeling empty, and whether the lesson's sudden quiet is pleasant.
- **Loudness.** Peak dB is not loudness; no LUFS was measured.
- **Clicks.** The probe cannot hear a click at a loop point or in a crossfade.

No screenshots were kept: no frame illustrates a sound.

## Not reached

- the Frost, Summer, Autumn and mentor fights;
- the finale crossfade;
- cutscene music;
- the slot screen.

## Re-check after the fix (region5, same day)

The six region scenes now set `music` after `script` (working tree, uncommitted). I re-ran the region timeline with
`AUDIO_RESTORE="17:1"` and **without** `AUDIO_FIX_REGION`, so the cue comes from the scene itself.

| Phase | Music peak max / median (dBFS) | Stems / deck |
|---|---|---|
| Village (3.0-4.6 s) | -9.1 / -12.7 | `region_home_village` from the world load, gain 1.0 by ~3.6 s, memory stem 0.64 |
| Seam crossfade (4.6-7.7 s) | -7.3 / -13.3 | woods gain 0.19, 0.53, 0.86, 1.00 one second apart (3 s); village 0.81, 0.47, 0.14, then stopped |
| Woods, grey (7.7-16.9 s) | -4.9 / -11.3 | memory stem 0.16 |
| Memory lifting (16.9-26.5 s) | -4.2 / -10.0 | stem 0.16 to 0.94 by 25.9 s; position 12.61 to 21.66 s, rising steadily |
| Woods restored (29.7-33 s) | -7.4 / -10.6 | memory stem 1.00 at 29.9 s (about 10 s after the restore, 3 s of it paused) |

- **The theme plays from the scene: PASS.** The bug is fixed.
- **Crossfade at the border: PASS.**
- **The memory stem rises without a restart: PASS.**
- **Pause still holds the position.** It held at 21.95 s and resumed from 22.67 s.
- The numbers match the runtime-patched run (region4) within about 1 dB. The stem's lag behind the memory (about 4 s) is unchanged.
