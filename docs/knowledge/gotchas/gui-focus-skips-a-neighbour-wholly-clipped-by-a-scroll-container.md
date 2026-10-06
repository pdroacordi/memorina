---
id: gotchas/gui-focus-skips-a-neighbour-wholly-clipped-by-a-scroll-container
type: gotcha
title: ui_up / ui_down focus search does not reach a control wholly scrolled out of a ScrollContainer when the focused control is flush with the clip edge
status: active
tags: [godot, gui, focus, scrollcontainer, input, menu]
related: [bugs/the-notebook-list-cannot-scroll-back-up-past-a-hidden-row, gotchas/gui-focus-moves-once-per-stick-tilt, systems/notebook]
created: 2026-10-06
updated: 2026-10-06
source_files:
  - scenes/ui/notebook/notebook.gd
---

## Summary

In Godot 4.7.2 the automatic focus neighbour search ignores a control that lies wholly
outside a ScrollContainer's visible rect when the focused control touches that edge. A menu
that scrolls by whole rows, with the top row flush with the clip top, cannot reach the rows
above it with Up.

## Details

Measured headless (`-s` script) on 2026-10-06. A ScrollContainer was 100x50, with a
VBoxContainer (separation 0) of six 20 px focusable PanelContainers. One `ui_up` /
`ui_down` press and release was sent through `Input.parse_input_event`:

| scroll | focused (rows y) | press | result |
|---|---|---|---|
| 40 | Row2 (40..60, flush top), Row1 (20..40) wholly clipped | up | stays on Row2 |
| 30 | Row2, Row1 partly visible | up | Row1 |
| 0 | Row1, Row0 visible | up | Row0 |
| 10 | Row2 (40..60, flush bottom), Row3 wholly clipped | down | stays on Row2 |
| 40 | Row3, Row4 partly visible | down | Row4 |

A wholly clipped neighbour was reached once in the notebook: Down from a row whose bottom was
above the clip bottom, with a gap below it. The failure needs both conditions: the neighbour
wholly clipped, and the focused control flush with that edge.

`ScrollContainer.follow_focus` does not help, because focus never moves.

## Gotchas / pitfalls

- Any list that hides rows outside the window and aligns the window to a row edge hits this.
  Use explicit `focus_neighbor_top` / `focus_neighbor_bottom`, or move focus in script.
- Tests that call `grab_focus` directly never see it. Drive `ui_up` / `ui_down` through
  `Input.parse_input_event` to cover it.
