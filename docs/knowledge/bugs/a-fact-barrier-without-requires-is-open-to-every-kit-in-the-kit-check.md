---
id: bugs/a-fact-barrier-without-requires-is-open-to-every-kit-in-the-kit-check
type: bug
title: A FactBarrier with no requires never opens in the game, but the kit check treats it as open for every kit
status: resolved
severity: low
tags: [tech-08, kit-check, reachability, fact-barrier, audit]
related: [architecture/room-reachability-audit, systems/rooms]
created: 2026-10-14
updated: 2026-10-14
source_files:
  - scenes/world/interactables/fact_barrier/fact_barrier.gd
  - scenes/world/rooms/maps/reach/reach_world_loader.gd
  - resources/world/maps/reach_kit.gd
---

## Symptom

Found in the TECH-08 review (2026-10-14, uncommitted). An `X` placed without `requires` is solid forever in the game:
`FactBarrier.is_open_for` returns `requires != null and ...`. In the kit check, every kit walks through it. No placement
does this today; all five `X` cells set `requires`.

## Root cause

`FactBarrier.reach_needs()` (`fact_barrier.gd:30-32`) returns an empty array when `requires` is null, and its doc
comment says "(never opens)". `ReachWorldLoader._need` packs that into an empty need. `ReachKit.holds` returns true for
an empty need (`reach_kit.gd:38-44`, "an empty need always does"). So `ReachGrid.for_kit` never adds the wall, which is
the opposite of what the comment claims.

## Fix

Fixed 2026-10-14, before commit. `ReachKit.NEVER` (-1) is a packed fact no kit holds; `ReachKit.holds` fails on it.
`ReachKit.opened_by(facts)` turns a gate's facts into its need, and an empty list into `[NEVER]`. `ReachWorldLoader._need`
uses it for every `reach_needs()` answer, so a FactBarrier with no `requires` is solid for every kit, as in the game.
`FactBarrier.reach_needs` now builds a typed array. Its old ternary returned an untyped one, which the typed
`opened_by` rejected. `reach_kit_check_test` checks that a barrier instanced without `requires` stays shut for the base
kit and for a kit holding every skill, song and item. The legend's `required_params` still rejects an `X` with no
`requires` in a room file.

## Prevention

Watch for an empty set that means "always" in one place and "never" in another. Pick one meaning, and test the null
case.
