---
id: playtests/2026-10-11-lighthouse-helix
type: playtest
title: WORLD-26 follow-ups - the lighthouse's two flights of one turning tower in stone and iron, the joint as the user chose it, and the tall bell tower front
status: active
build: f2abf02 + WORLD-26 follow-up working tree (the joint after "Walk left into it")
area_tested: "frost_edge/lighthouse_interior (1x4, slim, in void, two flights joined at the mentor's floor); home_village/village_square (the bell tower front)"
tags: [helix, stair, lighthouse, rotation, joint, facade, bell-tower, world-26]
related: [systems/helix-stair, systems/props, playtests/2026-10-11-bell-tower-helix, architecture/walkable-helix-stair, bugs/left-and-right-cannot-take-ivo-down-past-the-lighthouse-joint]
created: 2026-10-11
updated: 2026-10-11
ratings: { fun: 3, fluidity: 4, aesthetics: 3 }
screenshots:
  - screenshots/2026-10-11-lighthouse-helix/a01_foot.png
  - screenshots/2026-10-11-lighthouse-helix/a02_quarter_turn.png
  - screenshots/2026-10-11-lighthouse-helix/a03_lower_mid.png
  - screenshots/2026-10-11-lighthouse-helix/a04_below_the_mentor_floor.png
  - screenshots/2026-10-11-lighthouse-helix/c00_right_half.png
  - screenshots/2026-10-11-lighthouse-helix/c01_down_from_the_right_half.png
  - screenshots/2026-10-11-lighthouse-helix/a05_up_through_the_joint.png
  - screenshots/2026-10-11-lighthouse-helix/a07_head.png
  - screenshots/2026-10-11-lighthouse-helix/a08_attic_gallery.png
  - screenshots/2026-10-11-lighthouse-helix/a10_mentor_room.png
  - screenshots/2026-10-11-lighthouse-helix/a12_back_on_the_floor.png
  - screenshots/2026-10-11-lighthouse-helix/motion_sheet.png
  - screenshots/2026-10-11-bell-tower-front/a00_street_west_of_the_tower.png
  - screenshots/2026-10-11-bell-tower-front/a01_at_the_tower_door.png
---

## What was tested

`tools/playtest/scripts/lighthouse_helix_climb.json`, after the joint fix ("Walk left into it", user, 2026-10-11), every route through the joint in one run:
1. Right held from the door up the lower flight and off its head onto the mentor's floor's right half.
2. Left back into the axis: it boards the lower flight going down.
3. Up: back up and on through the joint, up the upper flight; right onto the attic gallery.
4. Left down the upper flight and off its foot into the mentor's room (left half).
5. Right into the axis: it boards the upper flight; Down rides through the joint; left on down to the floor and off the lowest foot.

Stills at the foot, a quarter turn, mid, under the mentor's floor, on the right half, going down from it, up through the joint, the head, the attic, the mentor's room and the floor; six frames 0.25 s apart on the lower flight (`motion_sheet.png`). The joint going down is traced (27.9-28.7 s).

The re-recorded `traverse_opening_k2_lighthouse_hatch_knock.json` (the sealed hatch at x 24400 knocks, sprite x -0.7 at 2.31 s) and `traverse_opening_n6_lighthouse_exit.json` (out to `lighthouse_base` at 2.0 s, back in at 4.1 s) pass on the new layout.

`tools/playtest/scripts/village_square_bell_tower_front.json`: Ivo walks right past the bell tower door in the square.

## Measured

| Step | t (s) | Feet | State |
|---|---|---|---|
| Boarded at the foot | 1.86 | 24320, 13425 | run |
| Off the lower head onto the right half | 8.65 | 24424, 12800 | idle |
| Left into the axis, riding down | 10.53 | 24320, 12895 | run |
| Up, through the joint onto the upper flight | 11.66 | 24320, 12785 | run |
| On the attic gallery | 18.85 | 24408, 12160 | idle |
| Off the upper foot in the mentor's room | 26.65 | 24219, 12800 | idle |
| Right into the axis, on the upper flight | 27.93 | 24320, 12785 | run |
| Down through the joint, then left | 29.11 | 24320, 12905 | run |
| Off the lowest foot onto the floor | 35.26 | 24203, 13440 | run |

Down through the joint: `u` 0.13 on the upper flight, then 12.53 on the lower (its head_u 4π = 12.57) in the next traced frame. The feet kept falling one riser at a time, with no stop and no snap.

## What the stills show

- The tower turns as one body across the joint: in `a04` and `a05` the upper flight's spiral above the mentor's floor continues the lower one's below it. The wall courses are counted from the lowest foot, so the bricks continue behind the gallery band.
- The right half (`c00`) is open floor; the upper flight's first steps rise behind it.
- The iron rail on the well side reads as a thin dark line with balusters; the stone and iron steps are dark slabs against the cold stone wall.
- The frost edge sits at memory 0.05, so the greyhush desaturates the whole interior: the palette shows only as values, and the void outside the shell is the greyhush's lifted dark grey (as `architecture/room-void-outside-the-shell` predicted).
- The bell tower front rises out of the top of the frame and its door fills the recess.

## What screenshots cannot show

The one-step pause where Up rides on at the lower head is invisible at 60 fps in the log. Camera feel up the shaft matches the bell tower's (`playtests/2026-10-11-bell-tower-helix`).

## Notes

- Left and right alone cannot cross from the mentor's room to the right half: that needs Up or Down at the axis. The user's choice accepts this; each half behaves as a bell tower end.
- Attic headroom is 64 px (the hatch's ceiling); a jump there bumps the ceiling at once. Nothing up there needs a jump.
- The legacy tileset draws the galleries' `-` cells as thin wood lines over the view's iron gallery face; the frost edge's own tiles will replace them.
