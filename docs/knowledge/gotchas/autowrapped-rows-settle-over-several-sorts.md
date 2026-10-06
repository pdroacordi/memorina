---
id: gotchas/autowrapped-rows-settle-over-several-sorts
type: gotcha
title: Autowrapped Labels in a VBoxContainer reach their final heights only after several sorts
status: active
tags: [container, label, autowrap, layout, scroll]
related: [systems/notebook]
created: 2026-10-06
updated: 2026-10-06
source_files:
  - scenes/ui/notebook/notebook.gd
---

## Summary

An autowrapped `Label`'s minimum height depends on its width, which the container gives it only when
it sorts. Rows built in one frame first report tall heights, then settle a sort or more later. Row
geometry read once with one `call_deferred` can come from a layout that is about to change.

## Details

- Measured in 4.7.2 (UI-03, 2026-10-06), on the notebook's eight song rows in an 81 px VBox. A
  deferred read after the rows were built saw every row at y 0, heights 29 to 49 px, and the list
  0 px tall. The settled layout was heights 9 and 19 px at y 0, 12, 24 … 124.
- Fix used: frame the list from `Rows.sort_children` (deferred), so the last sort wins.

## Gotchas / pitfalls

- A `ScrollContainer` scroll set from the stale geometry is clamped against the stale content
  height, so it lands on the wrong row.
- `get_combined_minimum_size()` in a test needs a few idle frames for the same reason
  (`notebook_text_fit_test` awaits four).
