---
id: bugs/the-mill-loft-is-unreachable-from-the-lowered-drawbridge
type: bug
title: With the loft at mill row 0 (top -1536), the 6-cell drawbridge ends 112 px short of it under the counterweights' solid floor, so no jump from the bridge reaches the loft - the counterweights shortcut is cut off
status: resolved
severity: medium
tags: [world-05, wind-orchards, drawbridge, soltar, counterweights, shortcut, level-design]
related: [playtests/2026-10-10-traversal-orchards-caldera, bugs/the-mill-loft-is-reached-by-double-jump-without-soltar, bugs/the-raised-mill-drawbridge-stands-through-the-windy-gap]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - scenes/world/rooms/wind_orchards/contents/orchard_mill_town.room
  - scenes/world/rooms/wind_orchards/contents/orchard_counterweights.room
---

## Summary

The fixes moved two things:
- **The loft** to mill town row 0 (S46-51: x -6208..-6016, top -1536). That is the floor of the counterweights'
  mouth.
- **The drawbridge** to a 6-cell span from the inn roof's east end. Lowered, it reaches x -6512..-6320 at
  y -1344.

Above the bridge's end, the mill town's top (-1536) is the counterweights' solid floor (S0-5 rows 21-23,
x -6400..-6208). The loft's own underside (-1504) covers x -6208..-6016. The only column that opens upward is
x -6016..-5952 (mouth cols 12-13 over mill cols 52-53). That column is ~300 px east of the bridge's end and 352 px
above the pit floor. So a jump from the bridge is capped 54 px under the loft's top, and nothing else reaches it.

## Symptom

Working tree on 5062946, `--import` 01:27:51.
`traverse_orchards_caldera_rv_l2_soltar_bridge_to_loft.json`:
- Ivo plays Soltar on the roof's east end and the bridge falls east. He walks it to (-6343.7, -1344).
- He jumps (0.45 s) and makes a second press at +0.55 s with right held. Peak feet -1481.9: the head meets the
  counterweights' floor at -1536.
- The second jump adds nothing under the ceiling. He drifts east under the loft and falls to the pit
  (-6115, -1184).

Frame: `playtests/screenshots/2026-10-10-traversal-orchards-caldera/rv_loft_bridge_end_capped_by_counterweights.png`.

## Impact

Medium. The loft and the counterweights (Outono Lógico 1, the shortcut to the terraces) are unreachable from the
mill town. The counterweights can still be entered from the terraces' upper hill through the drop column's east
opening, but the lift chamber and the loft cannot. The shortcut no longer connects the mill town to the
terraces.

## Fix

Options:
- Lengthen the bridge so it ends under the open column (x ≥ -6016). From hinge x -6512 that is ~16 cells, and
  its raised height must then stay inside the mill town. Or put the hinge further east.
- Or open the counterweights' floor over the bridge's end (mouth cols 3-5), so a jump from the bridge rises into
  the mouth beside the loft.
- Or lower the loft back to mill row 1 or 2 and re-check the no-Soltar double jump from the roof
  (`rv_l1`, with second presses at +0.45..+0.75 s).

## Prevention

Check every shortcut leg in both directions with the intended song after a geometry change, not only the gate it
closes.

## Resolution (2026-10-10, re-verified)

The loft is now a one-way at mill row 0 (cols 46-51), the inn roof runs to col 38, and the bridge is hinged at
(38, 5), 6 cells long. Working tree on 5062946 with the coordinator's second round of fixes, `--import` at 02:37:17; nothing changed after it.
- **The Soltar route reaches the loft and the counterweights**
  (`traverse_orchards_caldera_rv2_l1_soltar_bridge_end_to_loft_{55,75}.json`). From the lowered bridge's end, a
  double jump with right held rises through the one-way. Ivo stands on the loft at (-6106.1, -1536) or
  (-6046, -1536), 2 of 2, and the room becomes orchard_counterweights.
- **No skip without Soltar** (`..._rv2_l2_no_soltar_{roof,oneway}_double_jump_{55,75}.json`). From the roof,
  the raised bridge stops him at x -6458, peak -1481.9. From the row-3 one-way he lands back on the roof at
  (-6458.1, -1344). None of the 4 reaches the loft.
- **The raised bridge stays inside the mill town.** It stands at x ~-6448 from -1344 up to the room's top
  (-1536); its face stops him at x -6458.
