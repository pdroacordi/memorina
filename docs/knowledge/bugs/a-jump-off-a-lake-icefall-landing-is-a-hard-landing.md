---
id: bugs/a-jump-off-a-lake-icefall-landing-is-a-hard-landing
type: bug
title: A jump off any 9-row landing of lake_icefall, or off its lip onto threshold_bridge's span, lands at 800 px/s or more, so the shortcut's "no hard landing" holds only for walking off
status: resolved
severity: low
tags: [world-35, rooms, hard-landing, frozen-lake, threshold, icefall]
related: [systems/world, playtests/2026-10-14-world35-step3, gotchas/a-one-screen-shaft-cannot-shut-out-wall-climb]
created: 2026-10-14
updated: 2026-10-15
source_files:
  - scenes/world/rooms/frozen_lake/contents/lake_icefall.room
  - resources/characters/ivo/ivo_landing_stats.tres
---

## Summary

WORLD-35 step 3 (uncommitted, on a665105). The orchestrator call "no hard landing happens on the way to the bench"
was met by keeping every fall at 9 rows (288 px, about 751 px/s) under the 800 px/s `hard_land_speed`. That
leaves 38 px of margin. Any jump off a ledge adds its rise to the fall, so a player who jumps down the
switchback, which players do, gets the 0.75 s hard-landing recovery.

## Symptom

Scratch timelines (review, 2026-10-14), Frost kit:

- Off the entry floor: Ivo at (7360, -1634), right held, jump at the edge. Apex feet -1761, landing on the
  row-18 landing at -1344 (417 px). Last sampled fall speed 822 px/s one frame before contact; state `land`,
  no movement for the recovery.
- Off the bottom lip: Ivo at (7230, -34), left held, jump on the lip. His head stops under the row-54
  landing (feet -106), col 0 holds him east of x 7083 until his head clears row 57, and he lands on the fallen
  span at (7006, 256), 362 px down. Last sampled fall speed 800.3 px/s before contact; he stands still in `land`
  for about 0.75 s with left held.

The 9-row legs (entry floor to row 18, 18 to 27, 27 to 36, 36 to 45) have 7 rows of headroom over each open
end, so a full jump (144 px) is always possible there.

## Root cause

The fall heights were measured from walking off an edge. The margin (326 px for 800 px/s against 288 px of
drop) is smaller than any jump.

## Fix

Resolved 2026-10-15. The switchback is gone. The user chose "Straight drop into deep snow (Recommended)": "One long
drop down the shaft that lands in a drift of deep snow at the bottom, which breaks the fall: no stun, about 2 s.
Needs a small 'soft landing' rule (a snow/water cell that cancels the hard landing)." (2026-10-15).
- lake_icefall is one straight shaft with nothing to stand on between its mouth and threshold_bridge's fallen span.
- A `SoftLanding` zone (`n`, 6 cells wide, 6 tall) lies over the span under the snow drift prop, and `LandingRule`
  never makes a landing inside one hard (`systems/rooms` "Soft landing").
- A jump at the mouth only adds height to a fall that ends in the zone.
- Measured: `world35s3_a_glacier_crossing` lands at 1000 px/s and runs on at once, jumping 28 frames (0.47 s) later,
  inside the 0.75 s a hard landing would hold.

## Prevention

When a rule says "no hard landing", measure the fall from the highest point a jump reaches over the edge, not from
the edge.
