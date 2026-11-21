---
id: bugs/orchard-arena-claw-marks-hang-in-the-air-west-of-the-east-face
type: bug
title: orchard_arena's WORLD-38 claw marks are drawn on the open sky west of the east face, not on the wall, and prop_grounding_test does not cover wall decals
status: fixed
severity: low
tags: [props, wind-orchards, world-16, world-38, orchard-arena, decals, prop-grounding]
related: [playtests/2026-11-20-world15-17-guardian-regions-dressing, systems/props]
created: 2026-11-20
updated: 2026-11-20
source_files:
  - scenes/world/rooms/wind_orchards/contents/orchard_arena_contents.tscn
  - scenes/world/environment/props/wind_orchards/claw_marks.tscn
  - tests/scenes/world/environment/props/prop_grounding_test.gd
---

## Symptom

In orchard_arena (room origin (-10240, -1536)) the WORLD-38 hint, three pale claw slashes, floats in the air
about 0-36 px west of the east lintel's face. It should be scratched into the face. Seen at memory 0.25 and in
colour, every time the east end is on screen, including the fight's opening.
Screenshot: `playtests/screenshots/2026-11-20-world15-17-guardian-regions-dressing/orchard_arena_claw_marks_in_the_air.png`.

## Root cause

`Props/ClawMarks` sits at local (1230, 180) with `offset = (-18, -46)` and a 36x46 texture, so it covers local
x 1212..1248, y 134..180. In `orchard_arena.room`, the east face is column 39 (x 1248..1280), solid in rows 0-5
(y 0..192, the lowered lintel over the doorway). The sprite's right edge touches the face, but every opaque pixel
lies in column 38, which is open air.

`prop_grounding_test` checks grounded props, `HUNG` props and `SUPPORTED` pairs. `wind_orchards/claw_marks` is in
none of these lists, so nothing checks that a decal meant to be cut into a rock face overlaps a solid cell. (The caldera's sun tablets, sun relief and lion shadows sit on the cave backdrop on purpose.)

## Fix

**Applied (2026-11-20, before the WORLD-16 commit).** A prop draws behind the ground (z -10 under 0), so marks on col 39 itself would be hidden by its tiles: the claw marks were cut and the face carries ivy instead, mirrored (`flip_h`) so its flat edge meets the wall at x 1248, its foot at y 192 where the doorway starts (`IvyFace`), under the vines over the lowered lintel.


Not fixed (reported by the playtester; no code or scene edited). Move the decal onto column 39, for example to x 1266
(x 1248..1284, 4 px past the room's right edge), or narrow the art so that it fits x 1248..1280. Keep y within 0..192.

## Prevention

Give decals cut into a face (`claw_marks`) their own list in `prop_grounding_test`, with the rule "every
opaque pixel over a solid cell", as `HUNG` does for hanging props.
