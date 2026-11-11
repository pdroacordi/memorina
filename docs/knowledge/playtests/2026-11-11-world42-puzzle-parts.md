---
id: playtests/2026-11-11-world42-puzzle-parts
type: playtest
title: WORLD-42 puzzle parts - the pears drop off their stalks onto the plates, the orchard and village plates show their pressed frames, the gates and the lift move, and the pears go back when Soltar's colour leaves; the stalks stop 3-4 px short of the bough, and a raised gate shows through the shelf and the ceiling above it
status: active
build: 4f916be4 + uncommitted WORLD-42 tree. First --import 16:03; pear_tree/pear_limb .png and .tscn and both orchard contents .tscn changed at 16:07-16:08, between the first windy gap run (16:04) and the rest. Re-imported at 16:16 and re-shot both orchard rooms. The tree and limb drew the same, and the stalk gap measured the same.
area_tested: "orchard_windy_gap: Soltar by the pear, Vendaval from the shelf's west end onto the orchard plate, the gate, the return (grey and restored). orchard_counterweights: Soltar from col 14 on the right pear, the orchard plate and the lift, the limb tree (grey and restored). village_empty_house: Soltar on the indoor pear, Ivo on the col 1 plate, the oak door on the upper floor. Summer trial: the default plate, the basalt gate and the seesaw."
tags: [world-42, puzzle-parts, hanging-load, pear, props, pressure-plate, gate, lift, seesaw, soltar, vendaval, region-looks, playtest]
related: [systems/props, systems/rooms, systems/weight-presence-release, bugs/pear-stalks-stop-short-of-the-bough, bugs/a-raised-gate-draws-over-the-solid-above-it, playtests/2026-10-15-world35-step4, playtests/2026-10-10-traversal-orchards-caldera]
created: 2026-11-11
updated: 2026-11-11
ratings: { fun: 0, fluidity: 0, aesthetics: 3 }
screenshots:
  - screenshots/2026-11-11-world42-puzzle-parts/01_windy_gap_pear_drops_stalk_gone.png
  - screenshots/2026-11-11-world42-puzzle-parts/02_stalk_tops_short_of_the_bough.png
  - screenshots/2026-11-11-world42-puzzle-parts/03_windy_gap_gate_rises_through_the_shelf.png
  - screenshots/2026-11-11-world42-puzzle-parts/04_windy_gap_orchard_plate_up_and_pressed.png
  - screenshots/2026-11-11-world42-puzzle-parts/05_windy_gap_colour_sequence.png
  - screenshots/2026-11-11-world42-puzzle-parts/06_counterweights_tree_colour.png
  - screenshots/2026-11-11-world42-puzzle-parts/07_counterweights_plate_pressed.png
  - screenshots/2026-11-11-world42-puzzle-parts/08_empty_house_both_plates_gate_up.png
  - screenshots/2026-11-11-world42-puzzle-parts/09_empty_house_raised_door_over_ceiling.png
  - screenshots/2026-11-11-world42-puzzle-parts/10_summer_trial_plate_gate_seesaw.png
  - screenshots/2026-11-11-world42-puzzle-parts/11_windy_gap_grey_release_flipbook.png
---

## Summary

The puzzles still work with the new parts. In the windy gap, Soltar drops the pear onto the shelf and the stalk
vanishes. Vendaval blows the pear onto the orchard plate, which shows its pressed frame, and the gate rises. When
Soltar's pulse leaves, the pear fades back onto its stalk. The counterweights' right pear presses its plate and the
lift rises. The house pear lands on its village plate, and with Ivo on the other plate the oak door opens. Two defects
were found. Every orchard stalk ends 3-4 px under the bough, so the pear hangs from nothing
(`bugs/pear-stalks-stop-short-of-the-bough`). The open gate in the windy gap and the house slides into the solid
above it and is drawn over it (`bugs/a-raised-gate-draws-over-the-solid-above-it`).

## Setup

Runs went through `tools/playtest/playtest_runner.tscn` with `$GODOT` and a fresh `APPDATA` per run, so no real save
was touched. Each room was run in grey (no guardians) and restored (`restored_guardians [0,1,2,3]`), with `locale en`.
New timelines are in `tools/playtest/scripts/`:

- `world42_windy_gap_puzzle_grey.json` / `_colour`: spawn (-7520, -1762); Soltar at 1.0; the `rv_w5` walk to the
  shelf's west end; Vendaval facing east at 7.9; shots to 33 s.
- `world42_counterweights_release_grey.json` / `_colour`: spawn (-5950, -1642), col 14 beside the right pear,
  400 px from the left pear, so Soltar reaches only the right one; `look_up` 11-13.5 s.
- `world42_empty_house_release_grey.json` / `_colour`: spawn (8336, 12280); Soltar; walk and jump left onto the
  col 1 plate (x 8043); `look_up` 11.5-13 s.
- `world42_caldera_trial_parts.json`: summer trial; Ivo walks onto the plate, then teleports to the seesaw.

## Findings

| # | Check | Result | Evidence |
|---|---|---|---|
| 1 | Windy gap: the pear hangs from the tree's bough | **Reads wrong**: the stalk stops 4 game px under the leaves, over open sky (bough underside y 84, stalk top 88 in room space). The pear hangs from the bough's leafy tip, past the end of the wood. | `02`, `bugs/pear-stalks-stop-short-of-the-bough` |
| 2 | Windy gap: Soltar drops the pear onto the shelf, and the stalk vanishes | **Works.** It hangs at 5.2 s and rests on the shelf at 5.4 s, its foot in the leaf litter, with no stalk left in any later frame. | `01`, `11` |
| 3 | Windy gap: Vendaval blows it onto the orchard plate; pressed frame; gate | **Works.** The pear slides east from 12.3 s and stops on the plate by 13.2 s. The plate flattens from a raised slab to a 2 px strip under the pear, and the gate rises 13.2-13.8 s. | `04`, `05` |
| 4 | Windy gap: the open gate | **Defect.** The gate rises through the shelf and stands 64 px above it, drawn over the shelf's stone and in front of the tree trunk. Ivo stood on the gate's column (x -7583.5) after playing the gale. The gate lifted him to y -1823.1 and lowered him at ~24.5 s. | `03`, `bugs/a-raised-gate-draws-over-the-solid-above-it` |
| 5 | Windy gap: the pear returns when the grey comes back | **Works.** It fades on the plate at 24.0 s and is back on the bough with its stalk by 24.5-25.0 s (colour run ~25.5). The gate closes. Vendaval's colour still holds around the shelf until ~27.5 s, because only Soltar's pulse holds the pear. That is correct by `systems/weight-presence-release`, but a player may read it as "the colour is still here, why did it go back". | `05`, `11` |
| 6 | Counterweights: Soltar on the right pear; orchard plate; lift | **Works.** The pear lands on plate_lift (5.6-5.9 s) and the plate shows its pressed strip. The lift rises out of frame 6.2-7.7 s. The left pear stays hung. `look_up` peeks only ~88 px, so the lift's top stop is not in frame. | `07` |
| 7 | Counterweights: the tree reads as one tree, nothing floating | **Mostly.** In colour it reads well: a trunk springs from the floor at the west wall, curves up and becomes one limb that runs across the shaft into the east wall, leafy all along. Its foot meets the floor and nothing floats. In grey, the trunk and limb are low-contrast greys on the dark rock backdrop, and the stalks are about the rock's colour, so the pears look hung from nothing. Both stalks also stop 3 px short of the limb. | `06`, `02` |
| 8 | Empty house: the pear under the indoor tree; village plates; oak door | **Works.** The pear hangs from the crown's left tip with a 1 px gap that reads as attached, and drops onto the col 12 plate. With Ivo on the col 1 plate both plates show pressed and the oak door (col 4, upper floor) opens. The closed door fills floor to ceiling and matches the lower front door's look. | `08` |
| 9 | Empty house: the open door | **Defect (minor).** The open door goes into the ceiling row, and its lower iron band is drawn over the ceiling planks. It shows best with `look_up`. | `09` |
| 10 | Summer trial: default plate, basalt gate, seesaw | **Works.** Ivo presses the plate and the gate rises; open, it overlaps the stone column hung over it (a test bed). The seesaw plank lies level on a cone-topped stone fulcrum, with the pivot about two thirds along the plank. It reads, but the pivot is off-centre. | `10` |

## Notes

- **The existing `world42_counterweights.json` spawns Ivo in the lift shaft.** At (-6200, -1640), cols 6-13, he
  drops past the lift into the pit under it. That timeline shows the tree but not Ivo on the floor. The new
  `_release` timelines spawn at x -5950.
- The HUD's three notes sit over the upper-floor oak door when the house camera is at its west end (`08`). This is
  HUD placement and predates WORLD-42.
- Release timing varied about ±0.5 s between grey and colour runs (song-driven). Every time above is the grey run's.

## What screenshots cannot show

Feel is not rated (fun and fluidity 0 = not judged). Not judged from frames:

- how the pear's fall and slide feel;
- whether the gale's push reads as wind;
- the plate's click;
- the gate's and the lift's speed. Inferred from timing only: the gate takes ~0.6 s and the lift 3.5 s, as authored.

The aesthetics score of 3 reflects the stalk gap, the open gate drawn over stone, and the grey counterweights being
hard to read. The region looks themselves (the orchard sandstone gate with its carved X, the oak door, the plank
plates) fit their rooms.
