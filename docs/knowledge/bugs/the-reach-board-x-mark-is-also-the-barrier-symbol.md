---
id: bugs/the-reach-board-x-mark-is-also-the-barrier-symbol
type: bug
title: A reach board's X (unreachable) mark is also the barrier's legend symbol, so a barrier reads as a finding
status: resolved
severity: low
tags: [rooms, reachability, tools, boards]
related: [architecture/room-reachability-audit]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - tools/maps/reach_boards.gd
  - scenes/world/rooms/maps/reach/reach_finding.gd
---

## Summary

`reach_boards.gd` writes finding marks over the raw `[grid]` rows. `X` means UNREACHABLE there, but it is also the barrier entity's symbol in `[grid]`, so every barrier shows up as an unreachable mark.

## Symptom

TECH-05 review, 2026-10-11. `village_mill.txt` shows `X` at col 30, row 4, under a header that says "X unreachable". The mill has no UNREACHABLE finding: that cell is the river-trail barrier.

## Root cause

`ReachFinding.MARKS` (`reach_finding.gd:19-25`) uses `X`, `N`, `r`, `p`, `v`. `_write_text` (`reach_boards.gd:67-73`) copies `map.rows` unchanged and replaces only the cells that carry a mark. Legend symbols that match a mark (`X` today) stay in the output and cannot be told apart from marks.

## Fix

None yet. Either blank every entity symbol to `.` before drawing the marks, or pick marks that `RoomLegend` never defines, and assert that at startup.

## Prevention

Assert in a test that no `ReachFinding.MARKS` value is a `RoomLegend` symbol.

## Resolution (2026-10-11)

Board marks are punctuation no legend character uses (`ReachFinding.MARKS`: `!` unreachable, `*` leads nowhere, `+` redundant route, `:` dead-end pocket, `&` no way back, `?` unpaired door); `reach_grid_test.test_no_board_mark_is_a_legend_symbol` holds it.
