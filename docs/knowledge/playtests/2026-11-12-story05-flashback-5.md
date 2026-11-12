---
id: playtests/2026-11-12-story05-flashback-5
type: playtest
title: STORY-05 flashback 5 - her lullaby up the river, colour rising with the song while Ivo walks, a hidden swap into the past with no cover, Alba under the old tree with the girl asleep, Ivo sits beside them, the frame pulls back as the dusk deepens, one line, the voice stops before her A and the image fails at once; Ivo kneels in silence
status: active
build: f682233c + uncommitted STORY-05 step 11 tree
area_tested: "lake_waterfall_path into village_garden with flashback 5 due (Memorina, all four guardians restored, flashbacks 1-4 seen): Lure5, Crossing5, SongBloom5, Swap5 and the hidden travel; garden_past: TreeWithDaughter, the Twilight SongTints, the GroundSeat, flashback_5 (camera, held line, music mark, collapse); the travel back and flashback_5_returning."
tags: [story-05, flashback, cutscene, travel, hidden-swap, greyhush, grass, music, alba, playtest]
related: [architecture/story-05-playable-flashbacks, systems/cutscenes, systems/grass, systems/life-benches-death, bugs/a-travel-asked-under-a-cut-to-black-left-ivo-disabled, playtests/2026-11-12-story05-flashback-4]
created: 2026-11-12
updated: 2026-11-12
ratings: { fun: 0, fluidity: 3, aesthetics: 3 }
screenshots:
  - 2026-11-12-story05-flashback-5/c00_colour.png
  - 2026-11-12-story05-flashback-5/c02_colour.png
  - 2026-11-12-story05-flashback-5/s04_swap.png
  - 2026-11-12-story05-flashback-5/s05_swap.png
  - 2026-11-12-story05-flashback-5/swap_diff.png
  - 2026-11-12-story05-flashback-5/l00_sit.png
  - 2026-11-12-story05-flashback-5/l03_wide.png
  - 2026-11-12-story05-flashback-5/l04_line.png
  - 2026-11-12-story05-flashback-5/l06_gap.png
  - 2026-11-12-story05-flashback-5/l07_grey.png
  - 2026-11-12-story05-flashback-5/k00_return.png
  - 2026-11-12-story05-flashback-5/k02_up.png
  - 2026-11-12-story05-flashback-5/zoom_half_rejected.png
---

# STORY-05 flashback 5 playtest

Timeline `tools/playtest/scripts/story05_flashback_5.json` (game clock, 51 s): Ivo starts in lake_waterfall_path at the
garden's opening, walks west into the garden and stops east of the pool (local x 1209), waits for the swap, walks west
across the pool (one jump) to the ground seat, presses Down, and does nothing after. Three runs: the first two found the
problems below, the third is the build reported.

## What happened (third run)

- Garden entered at t 1.2; the crossing recorded at once, the song started, Ivo kept walking (no block seen in the log).
- The colour rose from the waterfall (`c00`: a 48 px strip with its leading ring, `c02`: the room in colour at t 6).
- The swap at t 7.9-8.1, Ivo standing inside `Swap5`: room `village_garden` → `garden_past`, camera centre (960, 204) room-relative before and after, Ivo's pixel, facing and idle clip continuous (`pos_in_clip` 0.3 → 0.5).
- `swap_diff` (`s04` against `s05`, 0.2 s apart, channel sum > 15): only the waterfall's splash and pool surface, Ivo's idle frame and a few single-pixel motes differ. Ground, props, backdrop, grass and grade are the same.
- Walk to the seat, Down at t 13.8: `sit=true state=sit_ground`. The scene: zoom 1.5 on the three (`l00`), the pull back to zoom 1 with the sky over the tree (`l03`), the dusk deepening (`l03` → `l06`), her line at song 33.7 s (`l04`), held 5 s and gone without a press.
- The gap at t 41.7 (song 40.7 s): grey at once (`l07`, second run), black, the present: Ivo kneels (`k00`, `state=kneel`), stands at about 48 s (`k02`, `state=idle`, `pmode` 0). The life notes are back.

## Found and fixed

1. **The grade changed at the swap** (run 1): the past wore a green cast the present did not. A source's tint replaces the region's season tint where it reaches; the song's bloom was white, the past (no source) wore spring's. `Bloom5.tint` is now the season's palette tint.
2. **The grass changed at the swap** (run 1): blade roots are hashed on world art columns, so the twin 102400 px away grew different blades. `Region.twin_shift` → `GrassField` → `hash_shift` in `grass_blades.gdshader`.
3. **Ivo stayed DISABLED after the travel back** (run 2): `bugs/a-travel-asked-under-a-cut-to-black-left-ivo-disabled`. `Game.travel` now awaits a physics frame after the cover.
4. **The widest shot showed past the room** (run 2, `zoom_half_rejected`): at zoom 0.5 the frame showed the void over the top and under the floor, and the backdrop is not drawn outside a band around the zoom-1 frame. The shot now pulls back to zoom 1, the widest this 384 px interior holds; the waterfall is out of it.

## Verdict

The hidden swap holds: standing still, nothing but animation phase changes between the two frames, and the HUD fades at
the garden's entry, not at the swap. The fallback soft white was not needed. Not seen by screenshots: the swap while
running (the director waits for the floor; a run through it is untested), the lures' voice and its rise up the path
(during these runs the lures' `zone` did not resolve, their nodes lacking `node_paths`, so no voice was asked; fixed after, pinned by `flashback_rooms_test`, not replayed), and the voice stopping mid-note (`Music` cut at the mark, by the log's timing).

## Open

- The widest shot is zoom 1 (the room's height); the draft's "a cachoeira" in that shot needs zoom below 1, which needs the past room's backdrop and void handled for it: a user decision.
- The waterfall's splash and pool frames jump at the swap (each room's memory clock).
- The crossing bloom's leading ring draws two broken vertical lines while the strip is narrow (`c00`).
- The lures' voice restarts the song at the garden (a different cue, cross-faded), not one take from the mill.
