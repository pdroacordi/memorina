---
id: bugs/a-jump-across-a-horizontal-seam-loses-its-height-in-the-fade
type: bug
title: A jump that crosses a horizontal room seam freezes for the ~1 s walk-in fade, and a jump released during it is cut short
status: resolved
severity: high
tags: [rooms, room-transition, seam, fade, jump, double-jump, world-05, blocker]
related: [playtests/2026-10-09-traversal-woods-lake, bugs/walking-across-a-room-seam-fades-back-and-forth, systems/rooms, systems/input]
created: 2026-10-09
updated: 2026-10-09
source_files:
  - scenes/world/game.gd
  - scenes/characters/ivo/player.gd
---

## Summary

When Ivo's feet cross a room's top edge mid-jump, `Game` disables him for the walk-in fade (~1 s,
`pmode=4`). His velocity is kept. A jump button released during the fade is applied when he resumes,
and it cuts the rise (variable jump height). A normal press (0.3-0.4 s) is always released inside the
freeze, so every vertical climb whose last jump crosses a seam loses ~50-100 px of height. Holding jump
through the whole fade (~1.5 s) gives the full height.

## Symptom

Build 6fa077a, `skills: [0]`. Second jump of a double jump from woods_canopy's launch branch
(y -1024) straight up its 7-row hole into orchard_terraces (floor y -1248):

| Timeline | Second press | Peak | Result |
|---|---|---|---|
| `traverse_woods_lake_g_canopy_branch_to_terraces_tap.json` | 0.35 s | y -1193.8 | 54 px short; falls back, second fade |
| `traverse_woods_lake_g_canopy_branch_to_terraces_held.json` | 2.0 s | y -1278 | lands on the terraces at y -1248 |

```
tap:   t=4.50 pos=(-4124.9,-1166.2) vel=(0,-434) fade=0.50 pmode=4   (frozen ~1 s at the seam y -1152)
       t=5.40 pos=(-4106.1,-1188.3) vel=(0,-92.1)                     (resumes; rise already cut)
held:  t=5.40 pos=(-4106.1,-1220.9) vel=(0,-309.1)                    (same freeze; rise kept)
```

The same happens on the woods_deep → woods_canopy double jump (row 4 branch, y -640, up to the
canopy floor y -864). With a 0.35 s second press the peak is y -809.8, 54 px short
(`traverse_woods_lake_e_deep_climb_to_canopy.json`). Held 2.0 s, the peak is y -892.5 and he lands
(`..._e2_canopy_jump_held_through_fade.json`).

**The Frozen Lake's entrance has the same problem.** village_mill's slab (y 32) is the only way up to
lake_waterfall_path's bench stub (y -96). That is a 128 px rise, and every jump crosses the seam at y 0
after 32 px:
- a 0.45 s press peaks at y -37.9 and falls back into the mill
  (`traverse_woods_lake_k2_mill_floor_trail_slab_stub.json`);
- a 1.6 s press peaks at y -105 and lands on the stub with 9 px to spare
  (`traverse_woods_lake_k3_slab_stub_jump_held.json`).

So the whole lake region, its bench included, cannot be entered with a normal jump.

It also cuts the jump off the top of woods_root_caves' root shaft. Ivo leaves the hold at y 402, crosses
y 384 at once, and peaks at y 339.8 instead of ~259. A second jump from the corner he lands on
gets him out (`..._i2_caves_climb_and_jump_out.json`).

## Impact

- village_mill → lake_waterfall_path (the lake's only entrance, base kit) fails for a normal press.
- Both double-jump gates into the orchards from the woods (deep → canopy → terraces) fail for a normal
  press. The player must hold jump through a frozen second. Nothing tells them to.
- The jump hangs motionless mid-air for ~1 s at every horizontal seam it crosses. Seen here:
  - village_mill → lake_waterfall_path;
  - woods_deep → woods_canopy → orchard_terraces;
  - woods_root_caves → woods_deep;
  - lake_well → lake_fishing_village (the well softlock, `bugs/the-fishing-village-well-has-no-way-out`).

## Suggested fix

Keep the jump's held state across the freeze, so a release during the fade does not cut it. Or better,
do not disable Ivo for a seam crossing: swap the room and camera bounds without a fade when the new
room abuts the old one. A fade belongs to doors, not to walking (or jumping) across a seam.

## Resolution (2026-10-09)

Fixed by the uncommitted WORLD-05 seam work on ea47690. `Game._physics_process` makes the room under Ivo's
feet current without disabling him. Inside a region the camera glides (`GameCamera.set_bounds(bounds, true)`,
0.45 s); across a region seam it cuts. Re-verified with normal presses (`playtests/2026-10-09-traversal-woods-lake`,
Re-verification). `fade` stays 0 and Ivo is never disabled:

| Jump | Press | Peak before | Peak now | Result |
|---|---|---|---|---|
| village_mill slab → lake_waterfall_path stub (`traverse_woods_lake_k2_mill_floor_trail_slab_stub.json`) | 0.45 s | -37.9 | -105.9 | lands and sits on the bench, 2 of 2 |
| woods_deep r04 → woods_canopy (`..._e_deep_climb_to_canopy.json`) | 0.35 s second | -809.8 | ~-880 | lands at -864, 2 of 2 |
| canopy branch → orchard_terraces (`..._g_rv_branch_to_terraces_tap_steer{04,06,08}.json`) | 0.35 s second | -1193.8 | -1264.8 | lands at -1248, 7 of 7 |
| root caves top rung → ledge (`..._i10_rv_caves_root_climb_ledge_to_deep.json`) | 0.4 s | 339.8 | 305.7 | the ledge (384), then woods_deep (288) |

The original `g_…_tap` timeline still "fails". Its steer starts at T+1.4 s, timed for the old fade, so it
begins after the jump has fallen back below the floor. That is a timeline artefact.

Follow-ups:
- `bugs/crossing-a-seam-upward-takes-ivo-out-of-the-frame`: the camera now lets Ivo leave the frame at
  upward seams.
- `bugs/a-running-neighbour-rooms-backdrop-draws-over-the-current-room`.
