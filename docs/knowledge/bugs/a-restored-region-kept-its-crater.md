---
id: bugs/a-restored-region-kept-its-crater
type: bug
title: Restoring the Bloom Guardian left Downtown grey for ever
status: fixed
severity: high
tags: [regions, memory-field, guardians, restoration, ownership]
related: [architecture/the-region-owns-its-forgetting]
created: 2026-09-22
updated: 2026-09-22
source_files:
  - scenes/world/rooms/home_village.tscn
  - scenes/world/rooms/home_village/contents/downtown_contents.tscn
  - scenes/characters/guardians/guardian.gd
---

## Summary

`Guardian._lift_region()` faded out its OWN well of forgetting and pushed
`MemoryField.baseline` to 1.0. Downtown had a second, unrelated well - a bare
`MemorySource` named `GreyhushPatch` authored straight into `downtown_contents.tscn`, with
nobody to switch it off. Walk back to Downtown after the lesson and the crater was still
there, contradicting design section 4.1 ("restaurar o guardiao leva o valor dela
permanentemente a 1.0") and `Region.current_baseline()`'s own promise.

## Symptom

Two idioms for one concept, and only one of them knew about restoration. The village's
baseline read 1.0 and a 500 px hole in the middle of it still read 0.10.

## Root cause

Ownership. Nothing owned the region's memory, so each well was switched off - or not - by
whoever happened to have authored it. The guardian's well was a node inside the guardian;
downtown's was a node inside a room; neither was the region's.

## Fix

Both became `MemorySource` children of a `RegionMemory` node in `home_village.tscn`, which
lifts all of them together when `SaveSystem.guardian_restored` fires. See
`architecture/the-region-owns-its-forgetting`.

Measured after, from Downtown: 0.10 -> 1.00 across `lift_time`, with both wells at
`strength = 0.0` and hidden, and the region reading 1.00 on the next visit without a
tween.

## Prevention

When the same concept is authored twice by hand in two different scenes, the second copy
is where the behaviour will be missing. Ask which object OWNS the concept before authoring
an instance of it anywhere - and if the answer is "whoever needed it", that is the bug.
