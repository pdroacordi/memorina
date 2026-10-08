---
id: playtests/2026-10-07-empty-house
type: playtest
title: PZL-05 the empty house - the door needs both plates, but a walked route clears it by about 1 s only with machine-perfect input
status: active
build: 26fd68e + uncommitted PZL-05 (empty_house.room, mechanism.gd second_trigger_path); final layout far plate col 82, 86 cells
area_tested: "Combinado 4, trials_solstice/empty_house at world x 12160 (door col 10, cocoon plate col 32, far plate col 82)"
tags: [solstice, sombra, soltar, pressure-plate, gate, hanging-load, composition, trials, timing, pzl-05]
related: [bugs/a-released-load-presses-ivo-into-the-floor, playtests/2026-09-30-sombra-and-soltar-trials, systems/weight-presence-release, systems/solstice]
created: 2026-10-07
updated: 2026-10-07
ratings: { fun: 2, fluidity: 2, aesthetics: 3 }
screenshots:
  - screenshots/2026-10-07-empty-house/shadow_on_the_far_plate.png
  - screenshots/2026-10-07-empty-house/walking_under_the_cocoon.png
  - screenshots/2026-10-07-empty-house/cocoon_on_its_plate.png
  - screenshots/2026-10-07-empty-house/door_shut_and_open.png
  - screenshots/2026-10-07-empty-house/paced_door_still_up_27.25.png
  - screenshots/2026-10-07-empty-house/paced_door_shut_28.25.png
  - screenshots/2026-10-07-empty-house/tight_through_the_door_26.64.png
  - screenshots/2026-10-07-empty-house/cocoon_blocks_from_the_right.png
  - screenshots/2026-10-07-empty-house/ivo_pressed_into_the_floor_12.2.png
  - screenshots/2026-10-07-empty-house/ivo_still_in_the_floor_31.0.png
  - screenshots/2026-10-07-empty-house/pocket_wall_top_fade.png
---

## What was tested

Every run redirected `APPDATA` to a scratch folder, and the real save's md5 was unchanged
after each one. All `t` values are the runner's unpaused clock. The far plate moved from
col 78 to col 82 mid-session; each run below names the layout it used. The cocoon (col 32)
and the door (col 10) did not move, so the runs placed near them hold for both layouts.

Timelines in `tools/playtest/scripts/`:
- `song_empty_house.json`: the walked solution at a "paced" tempo, close to a calm human.
  - Solstice, then Sombra, on the far plate.
  - Walk left and stop one cell left of the cocoon (x ≈ 13140).
  - Wait 0.6 s, then play Soltar (0.6 s from drawing to the first note, notes 0.4 s apart).
  - Walk out 0.25 s after the Memorina is put away.
- `song_empty_house_tight.json`: the same route at machine-perfect speed.
  - Leave on the first free frame and stop at x 13175.
  - Draw on arrival: 0.3 s from drawing to the first note, notes 0.3 s apart.
  - Walk the instant the Memorina is put away.
- `song_empty_house_no_solstice.json`: the control. The paced route with Sombra alone.
- `song_empty_house_shadow_only.json`: Solstice and Sombra, then straight to the door with
  no Soltar (only the far plate held).
- `song_empty_house_load_only.json`: Soltar beside the cocoon, then to the door (only the
  near plate held).
- `song_empty_house_from_the_right.json`: Soltar from right of the cocoon (where Ivo
  arrives), walk into it, then jump over it.
- `song_empty_house_under_long.json`: Soltar from directly under the cocoon. This is the
  bug repro.
- `song_empty_house_pocket_skills.json`: from the pocket behind the door, double-jump at its
  left wall (`skills` [0, 1]).

Every hold re-sends its press every 0.25 s. See the harness note at the end.

## Findings

- **The door needs both plates.** In every one-plate case Ivo is blocked at x 12520 against
  the shut door (`door_shut_and_open.png`, left):
  - Shadow only (col 78 layout): blocked at t 22.3 while the shadow still held its plate
    (until ~t 27).
  - Load only: the cocoon down on its plate, blocked at t 10.1.
  - Control, no Solstice (col 82): the shadow was gone by t ≈ 15, before Soltar was even
    played. Blocked from t 23.5.
- **The walked route (final layout, col 82) clears the door only at machine speed.**
  - The shadow's pulse starts at t ≈ 10.7. In the paced run the door is still up at t 27.25
    and down by 27.75 (`paced_door_still_up_27.25.png`). So the door stays passable about
    16.7 s after the shadow is cast, which matches the stretched 16.5 s plus the gate's fall.
  - Tight: Ivo crosses x 12474 at t ≈ 26.35, **~1.0 s before the door closes**
    (`tight_through_the_door_26.64.png`, the gate still up behind him).
  - Paced: Ivo reaches x 12620 at t 27.5 and is blocked at x 12520 from t 28.2
    (`paced_door_shut_28.25.png`), **~0.75 s too late**.
  - The difference between the two is ~1.7 s of human-scale delay:
    - note spacing 0.4 vs 0.3 s;
    - a 0.6 vs 0.3 s lead from drawing the Memorina to the first note;
    - pausing before drawing at the cocoon;
    - a beat before walking on.
  - The fixed costs are a 2326 px walk (12.1 s at 192 px/s) and Soltar, which keeps Ivo
    still for ≥ 3.5 s of `t` (notes, then the ~1.8 s ring-out before the Memorina is put
    away). Together they leave about 1 s for everything else. Rolling was not tested; it
    would add slack.
  - These numbers come from the timeline's clock. Whether a person makes it needs a human
    playtest. My inference is that a calm first attempt fails and only a rehearsed, hurried
    run passes.
  - Old layout (col 78) for comparison: tight passed with ~1.5 s to spare; paced failed by
    ~0.5 s. The move to col 82 took ~0.5 s off the walked route.
- **The cocoon lands on its plate and stays.**
  - It drops ~0.4 s after Soltar's pulse opens and sits square on the plate
    (`cocoon_on_its_plate.png`).
  - The door stayed up until the shadow ended in every solution run, so the cocoon stayed
    for the whole walk out.
  - Ivo walks under the hanging cocoon with his head clear (`walking_under_the_cocoon.png`).
- **Played from the right of the cocoon** (the side Ivo arrives on), the fallen cocoon
  blocks the corridor: Ivo stops at x 13226 and cannot push it
  (`cocoon_blocks_from_the_right.png`). One jump clears it (44 px tall, jump peak ~139 px)
  and it stays on the plate. That jump costs ~0.5 s of a ~1 s budget, so the left side is
  the place to play Soltar, and nothing on screen says so.
- **Bug: Soltar played from directly under the cocoon presses Ivo into the floor**, a
  soft-lock that outlasts the pulse (`ivo_pressed_into_the_floor_12.2.png`,
  `ivo_still_in_the_floor_31.0.png`). Filed as `bugs/a-released-load-presses-ivo-into-the-floor`.
  The task brief itself suggested "beside or under", so players will stand there.
- **Legibility.**
  - The view is 640 px wide. The door is 704 px from the cocoon's plate and ~2300 px from
    the far plate, so the player never sees it rise while arranging the plates. It comes
    on screen ~320 px before Ivo reaches it.
  - Neither plate is on screen with the other, nor with the door. The corridor reads as
    long and empty, which suits "a casa vazia", but the only feedback that the setup
    worked is the door itself, at the end of the walk.
  - The shadow on the far plate reads well: a dark silhouette with a warm rim, with
    Solstice's rays on its disc (`shadow_on_the_far_plate.png`).
  - The gate reads as a carved slab under the wall column and slides up into it
    (`door_shut_and_open.png`). A ~5 game px pale seam shows between the column and the
    shut gate. That is cosmetic.
- **Bounds and camera.** The camera stops at the room's left bound (x 12160): the
  two-cell left wall fills the first 64 px. On the right, the end wall frames the far
  plate. There is no void past either edge. Camera smoothing cannot be judged from frames.
- **The pocket behind the door is a dead end.** It is 8 cells between the door and a 7-cell
  wall, and a single jump peaks ~139 px, short of the 224 px wall. The door is shut from
  that side once the plates let go, so a successful run ends shut in the pocket until F10.
  That is the same as the Solstice trial's corridor and is acceptable for a debug trial. A
  real room would need an exit.
- **Unconfirmed: hanging at the region seam.** With double jump and wall climb unlocked,
  Ivo clears the pocket's left wall and hangs at x ≈ 12160 (the seam with the Solstice
  trial room), above both walls. The screen fades to black, and for over 5 s his x creeps
  from 12165 to 12154 in `fall_start` (`pocket_wall_top_fade.png`). This looks like
  repeated `Game._on_player_entered_room` fades, each one freezing him. It was seen once
  and not filed. It needs a probe that logs `_current_room` across the seam.
- Not a finding: Ivo is still the placeholder rainbow figure. The `water_trial.room` import
  error from another session's work does not touch this room.

## Ratings rationale

- **Fun 2 (low confidence, inferred from timing).** The composition is legible on paper:
  shadow on one plate, cocoon on the other, walk out with nobody on either, as §8.4
  asks. But a walked route has ~1 s of slack only for scripted input, and a calm pace
  fails by ~0.75 s. The failure shows only at the door, ~2300 px after the setup, with
  nothing on screen to explain it. Standing under the cocoon soft-locks the game.
- **Fluidity 2 (inferred).** The route is a long straight walk, a stop, six notes, and a
  walk on, with every second counted. Input latency and camera feel were not judged.
- **Aesthetics 3.** The shadow, the pulses, the cocoon and the gate read well against the
  grey. The corridor is long and empty, but the two plates and the door never share a
  screen.

## Harness note

Another Godot window opening (a concurrent playtest) takes focus from the runner. Godot
then releases held actions: Ivo stopped mid-corridor with `move_left` still "held". Every
hold now re-sends its press every 0.25 s. One 0.2 s stall still showed in one run.

## Follow-up (2026-10-07)

The user chose "Solístico dura mais": `SolsticeAura.duration` 2.5 -> 3.0. Re-run of `song_empty_house.json`
(the paced walked route, col 82): Ivo is through the door (x 12236, in the pocket) at t 34. The
load bug is fixed (its mask sees Ivo): `song_empty_house_under_long.json` leaves him standing on the
floor.
