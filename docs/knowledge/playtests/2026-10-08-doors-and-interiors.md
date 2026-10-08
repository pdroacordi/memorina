---
id: playtests/2026-10-08-doors-and-interiors
type: playtest
title: WORLD-09 doors and interiors in the Solstice trials' door_trial - in, out, the sealed hatch, the map anchor and the weather
status: active
build: ce07360 + uncommitted WORLD-09 working tree (door.png art of 16:00:44, re-imported 16:04)
area_tested: "trials_solstice/door_trial and door_trial_inside (world x 18432..19200, floors y 6000 and 8048)"
tags: [doors, interiors, world-09, fade, map, map-anchor, weather, prompt, knock, save-fact, input, look-up]
related: [architecture/doors-and-interiors, bugs/taking-a-door-disables-ivo-inside-his-own-physics-step, systems/rooms, systems/map, systems/input, playtests/2026-10-06-map]
created: 2026-10-08
updated: 2026-10-08
ratings: { fun: 3, fluidity: 3, aesthetics: 3 }
screenshots:
  - screenshots/2026-10-08-doors-and-interiors/a02_prompt.png
  - screenshots/2026-10-08-doors-and-interiors/a06_fade_090.png
  - screenshots/2026-10-08-doors-and-interiors/a09_inside_held.png
  - screenshots/2026-10-08-doors-and-interiors/a10_map_inside.png
  - screenshots/2026-10-08-doors-and-interiors/b03_arrived_hatch.png
  - screenshots/2026-10-08-doors-and-interiors/b07_map_from_hatch.png
  - screenshots/2026-10-08-doors-and-interiors/b09_air_up.png
  - screenshots/2026-10-08-doors-and-interiors/sealed_open_knock_crop.png
---

## What was tested

Design 04 §4 and the plan in `architecture/doors-and-interiors`. Three timelines, `"clock": "real"`,
`"locale": "en"`, fresh `APPDATA` per run, real save md5 unchanged:

- `tools/playtest/scripts/door_front_round_trip.json`: from (18560, 5960), walk to the front door,
  `look_up` held from t 2.0 to 4.5 (through the whole fade), M inside, Up at the inside front door,
  M outside.
- `door_hatch_walk_and_air.json`: walk right onto the outside hatch, raw key `Up`, Up at the sealed
  inside hatch (knock), M, run left and press Up mid-run at the inside front door, then outside: Up
  early in a jump (in reach) and Up just before landing.
- `door_hatch_unsealed.json`: control with `"restored_guardians": [0, 1]`.

The runner's `log` gained room id, `interior`, camera bounds and centre, fade alpha,
`_is_transitioning`, facing, process mode, weather visibility and every loaded door (link, x,
open/sealed, `+prompt`, sprite shake x). Runs A1/B1/B2 used the placeholder door texture; a sibling
replaced `door.png` at 16:00:44, after my 15:58 import. Windowed runs do not re-import, so I re-imported
and re-ran A2/B3/C1. Behaviour was identical; the frames below come from the re-runs.

## Findings

1. **Prompt in reach: works.** The Up-arrow glyph sits above the door, clear of Ivo's head, only while
   his body overlaps (`a02_prompt.png`). It hides the moment the press disables him. The sealed inside
   hatch never shows it.
2. **Up fades and lands at the partner: works.** Press at t 2.00. Fade 0.16 at 2.10, black at ~2.50,
   room swap behind the black at ~2.55, clear at ~3.05, control back at ≤3.10. **About 1.1 s from press to
   control.** Arrival at (18576, 8048) facing right (`arrive_facing` 1). The camera is bounded to the
   interior (18432, 7728, 768x384) and was already snapped when the fade-in began (`a06_fade_090.png`),
   so there is no visible pan.
3. **Up held through the fade does not bounce: works.** `look_up` was held from 2.0 to 4.5 and he
   stayed inside. Feel note: the held Up is still a camera peek, so ~0.3 s after control returns the
   camera drifts up to the ceiling (`a09_inside_held.png`). Players who hold Up through a door will see
   it every time. It is harmless and follows the existing peek rule.
4. **Back out through `trial_front`: works.** He arrives at (18608, 6000) with his facing kept
   (`arrive_facing` 0). The map anchor clears: the map opened outside centres on Ivo.
5. **Sealed inside hatch: knocks and nothing else.** No fade, no `transitioning`, no prompt. The sprite
   x went 0.4 → 1.0 → -0.3 → 0.9 → 0 over ~0.2 s. Feel note: Ivo stands in front of the 32 px door
   and covers most of it, so only ~6 px of frame on each side visibly shakes
   (`sealed_open_knock_crop.png`). No sound is attached yet. Until `knocked` gets a sound, I expect a
   player to read this as a dropped input. The iron bar on the sealed frame does read in the grey
   (crop, left), and is the clearer signal.
   Control: with both guardians restored, the inside hatch is open, prompts, and leads out to the
   outside hatch (18992, 6000).
6. **Outside hatch → inside hatch facing left: works.** He walked in facing right and arrived at
   (19056, 8048) facing -1 (`b03_arrived_hatch.png`). The raw `Up` key works the same way as the
   `look_up` action.
7. **Map inside: works.** It centres on the building's door: `map_centre` (18608, 6000) after the front
   door and (18992, 6000) after the hatch, while Ivo stood at y 8048. The rectangle shifts accordingly
   (`a10_map_inside.png` vs `b07_map_from_hatch.png`). `map_seen` stayed at
   `door_trial.tscn:60` in every run; the interior never got a key. The map has no "you are here"
   mark, so the anchor shows only as where the room patch sits on screen.
8. **No weather inside: works (log).** `RegionWeather` is visible outside, hidden inside, and visible
   again after exiting. The summer particles are sparse single dots, so the frames are weak evidence
   here; the log is the proof. The `CPUParticles2D` keeps emitting while hidden, which is cheap and
   fine.
9. **Up while walking enters; Up in the air does not.**
   - Running left at 192 px/s, his body overlaps the inside front door for x 18593 → ~18545, so the
     prompt is lit for ~0.28 s. A press in that window entered. He freezes in the run pose under the
     fade and arrives standing, with velocity zeroed.
   - A first attempt pressed ~0.1 s before overlap (x 18612). It did nothing and was not buffered:
     the request is consumed on the next physics frame whether or not a door is in reach.
   - Feel (inferred from these numbers, not felt): entering on the move reads as the design's
     gesture. At full run the window is short enough that an early press will sometimes be lost. A
     ~0.1 s buffer, like jump's, would forgive it. A human should confirm before anyone changes it.
   - Mid-air: Up at y 5954 (in reach, prompt lit, `b09_air_up.png`) and Up 0.35 s before landing both
     did nothing, and nothing fired on landing.
   - Minor: the prompt stays lit while he is airborne in reach, even though the press is refused
     there.
10. **Bug, low: two engine errors per trip.** `body->get_space() is null` from `character.gd:57`
    because Game disables Ivo inside his own physics step. See
    `bugs/taking-a-door-disables-ivo-inside-his-own-physics-step`. There is no visible effect.
11. Observations about the test bed, not defects: the interior uses the same grey brick as the outside,
    so only the barred hatch tells you that you moved (dressing is WORLD-11). The open door is dark on
    grey at memory 0.35 and is easy to miss at the 1x view. The HUD note row stays bright over the
    black, as on every existing fade.

## Ratings rationale

- **Fun 3**: a door is plumbing. It does what design 04 §4 says with no surprise either way, and the
  sealed hatch's "no" has no sound yet. The number is low-confidence and inferred.
- **Fluidity 3**:
  - For: ~1.1 s press-to-control (0.5 s out + 0.5 s in, the same `Fade` as walk-ins), no bounce, no
    pan, and entry on the move works.
  - Against: the unbuffered press at a ~0.28 s run window, and a knock that is hard to see.
  - Whether 1.1 s feels quick enough when going in and out repeatedly, and what the input latency
    feels like, cannot be judged from frames. It needs a human playtest.
- **Aesthetics 3**:
  - For: the new door art reads in the grey, the barred seal is legible, and the prompt is placed
    well.
  - Against: Ivo is still the placeholder, and the test bed has no interior dressing.
