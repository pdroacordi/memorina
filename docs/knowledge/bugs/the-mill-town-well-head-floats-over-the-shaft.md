---
id: bugs/the-mill-town-well-head-floats-over-the-shaft
type: bug
title: orchard_mill_town's well head stands over the open shaft, its stone drum on nothing
status: fixed
severity: low
tags: [props, world-16, placement, floating]
related: [systems/props, bugs/guardian-region-props-placed-inside-ground-cells-draw-nowhere]
created: 2026-11-20
updated: 2026-11-20
source_files:
  - scenes/world/rooms/wind_orchards/contents/orchard_mill_town_contents.tscn
  - scenes/world/environment/props/wind_orchards/well_head.tscn
---

## Summary

`Props/WellHead` (`orchard_mill_town_contents.tscn:38`, at (224, 288)) is grounded on the open shaft (cols 5-8,
x 160..288, air on rows 9-11). The board places it "over the Hollow Tree well (posts on its lips)", but its
posts end above a stone drum, and the drum's whole opaque bottom row (x 168..273) is over air.

## Symptom

Status: open (WORLD-16 review, 2026-11-20). A 106 px stone drum hangs in the mouth of the shaft with 8 px of
gap at each side, and Ivo drops through it into the well. `prop_grounding_test` passes because it checks only the
art, not the cell under the origin.

## Root cause

The village well head's posts reach its shaft's lips (cols 27 and 32); this one's art is a drum with a roof, not
two posts, and the 128 px shaft is wider than its drum.

## Fix

**Applied.** Fixed 2026-11-20 before the WORLD-16 commit: the well head is cut at w90 (176x104 px), its stone drum 139 px wide over the 128 px shaft, placed at (228, 288) so each end of the drum rests about 5 px on a lip, as the village well head's posts do. `region_prop_placement_test` lists it in `NOT_ON_GROUND` with that reason.


Not fixed. Either draw a well head whose posts stand on the lips (x 158..160 and 288..290), or place this one
on the street beside the shaft and leave the shaft's mouth open.

## Prevention

The placement case proposed in `bugs/guardian-region-props-placed-inside-ground-cells-draw-nowhere`: a grounded
prop's opaque bottom row must stand over ground, a ledge or water.
