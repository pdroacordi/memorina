---
id: bugs/leaving-a-redoma-shell-downward-catches-ivo-on-its-ring
type: bug
title: Redoma lets Ivo go by his feet, 28 px past the ring - falling out through the bowl, his head is still inside, so he hangs on the ring until it contracts (6.6 s in the village cistern)
status: resolved
severity: medium
tags: [redoma, bell-jar, frost-shell, collision-exception, cistern, world-05, summer-caldera]
related: [playtests/2026-10-10-traversal-orchards-caldera, bugs/a-respawn-inside-a-live-shell-is-crushed-by-its-ring, architecture/the-bell-jar-closes-once, systems/bell-jar]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - scenes/world/memory/song_effects/shell/frost_shell.gd
  - scenes/world/rooms/home_village/contents/village_cistern.room
---

## Summary

`systems/bell-jar`: "nothing enters, everything may leave". `FrostShell._let_out` drops a body's collision
exception once `body.global_position` is more than `radius + CLEARANCE` (192 + 28 = 220 px) from the centre.
For Ivo, `global_position` is his feet, and his body reaches 54 px above them. When he leaves through the
bottom of the disc, his feet pass 220 px while his head is still ~26 px inside the ring. The exception goes, the
ring segments are solid again, and his capsule rests on them. `_adopt(radius - CLEARANCE)` does not take him
back, because his body is outside 164 px. He hangs in the air at terminal velocity until the contraction moves
the ring off him. That is the design's intended way into the Caldera.

## Symptom

HEAD 5062946, imported 00:23:06.
`tools/playtest/scripts/traverse_orchards_caldera_c1_village_cistern_redoma_drop_to_caldera.json`. Ivo plays
Redoma on the slab's east edge (1005, 672), drops to the shelf (1059, 800), walks west into the mouth and falls
down the dry shaft:

```
t 8.10  feet (932.4, 868.2)  vel (−192, 343)  falling
t 8.20  feet (935.3, 880.4)  vel (0, 441)
t 8.20-14.80  feet (935.3..941.9, 880.4)  vel (0, 1000)  floor=false  - not moving for 6.6 s
t 14.90 feet (945.7, 900.3)  falling again; t 15.30 room=caldera_cistern_bottom; t 15.80 lands on the dais
```

Distance check: the centre is about (1005, 671), so the feet at (935.3, 880.4) are 220.7 px away, the let-out
threshold. At x 935 the ring's bottom is at y 671 + sqrt(192² − 69.7²) ≈ 850. That is between his head (826)
and his feet (880).

Frames: `playtests/screenshots/2026-10-10-traversal-orchards-caldera/cistern_redoma_shell_holds_ivo_in_the_shaft.png`.
Ivo hangs in a falling pose on the ring's arc in the shaft from 8.5 s to 11.5 s and later.

## Impact

Every player who takes the Redoma route into the Caldera hangs mid-air for ~6.6 s on the way down. It reads as
a freeze or a broken fall. Any other downward exit from a shell has the same shape: a ledge under the disc's
edge, or a drop into a pit.

## Fix

Suggested: in `_let_out`, test the body's extent, not its origin. Drop the exception once no point of the body
is within `radius` (plus a small margin). For the Player, test `Player.body_rect()` against the disc: the
distance from the centre to the rect's nearest point must be greater than `radius + margin`. Props bodies need
their own shape's bounds. A simpler stopgap is a `CLEARANCE` of at least the tallest body (54 px + margin),
measured from the body's centre. `_adopt`'s re-adoption radius would need the same treatment.

## Prevention

A unit test: a body 54 px tall inside a closed shell, moved straight down out of the disc in small steps, never
collides with the ring.

## Resolution (2026-10-10, re-verified)

`FrostShell._is_clear` now lets a `Character` out only when its whole `body_rect()` is clear of the ring
(`clear_of`, plus `RING_GAP` 2 px). Working tree on 5062946 with the coordinator's fixes, `--import` at 01:27:51; nothing changed after it.
- **On the terraces crown**
  (`traverse_orchards_caldera_rv_s1_redoma_on_crown_drop_out_through_the_bowl.json`). Redoma is played on the
  crown at (-4110, -1792). Ivo walks off east onto r9 (-4017, -1632) inside the disc, then off r9 down to the
  block (-3928, -1504), 340 px from the centre. He falls through the ring at once: no airborne sample is held
  in place.
- **The original route cannot be re-run.** The cistern shaft is now sealed by its new ledges
  (`bugs/the-village-cistern-shaft-is-sealed-by-its-new-ledges`). Walking west from the shelf, Ivo lands on V15
  (972, 864) inside the disc and can go no lower.

## Re-verification 2 (2026-10-10)

Working tree on 5062946 with the coordinator's second round of fixes, `--import` at 02:37:17; nothing changed after it. On the cistern route, the drop from V16 to V18 leaves the Redoma disc downward with no hang
(`traverse_orchards_caldera_rv2_c2_village_cistern_redoma_descent.json`). The rest of the descent is blocked by
the V16/V18 corner (`bugs/the-village-cistern-shaft-is-sealed-by-its-new-ledges`).
