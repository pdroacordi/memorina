---
id: playtests/2026-10-09-foreground
type: playtest
title: Foreground - a column at Ivo's depth covers him and fades while he stands behind it; a near branch draws over the world, greyed
status: active
tags: [foreground, mem-12, playtest, fade, parallax]
related: [systems/foreground, architecture/foreground-layer]
created: 2026-10-09
updated: 2026-10-09
source_files:
  - tools/playtest/scripts/foreground_demo.json
  - tools/playtest/scripts/foreground_fade.json
---

## Summary

MEM-12 in the real game (windowed, `tools/playtest`), the spring trial's two placeholder pieces.

- **Draw order.** The column is drawn over Ivo when he passes it and over the step behind it; the
  near branch at the top of the frame draws over the trees. Both read greyed like the world around
  them (the creature composite's shader). `screenshots/2026-10-09-foreground/walk_sheet.png`.
- **The fade.** Standing behind the column (start at x 7360) it is translucent and Ivo shows
  through; walking out, it is opaque again. A brush of the column's edge (under the 15% coverage)
  does not fade it, as intended. `screenshots/2026-10-09-foreground/fade_pair.png`.
- **Placement.** The branch at scroll (1.4, 1.2), authored at y -250, was above the frame once its
  vertical parallax applied: author near pieces against the frame they will be seen in, not the
  room's grid.

## Not covered

- The F9 lesson: the dim's hole for an uncovered creature and the bars over the foreground.
- A pulse edge crossing a piece (season swap and haze on the piece against the world behind it).
- Smoothness of a 1.4 branch while panning (no jitter was visible in stills; a capture can't judge).
