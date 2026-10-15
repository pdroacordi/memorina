---
id: architecture/reward-slots-reserve-their-place-in-the-room-text
type: architecture
title: A reward slot is a legend entity placed in the .room before the reward system exists, anchored for the reach audit and filled later by slot id
status: active
tags: [rooms, room-map, legend, rewards, collectibles, reachability, level-design, story-06, life-04, world-35]
related: [architecture/rooms-are-text, architecture/room-reachability-audit, architecture/secret-false-walls, systems/rooms, systems/world, systems/notebook]
created: 2026-10-14
updated: 2026-10-15
source_files:
  - resources/world/maps/room_legend.tres
  - resources/world/maps/reach_allowlist.tres
  - scenes/world/rooms/maps/reach/reach_audit.gd
  - tests/scenes/world/rooms/maps/room_files_test.gd
  - tests/scenes/world/rooms/maps/reach/room_kit_test.gd
  - scenes/world/interactables/reward_slot/reward_slot.gd
---

# Reward slots reserve their place in the room text

## Summary

Accepted 2026-10-14: "Yes, invisible markers (Recommended)" (user, on the WORLD-35 board). **Status: built for WORLD-35 step 1** (2026-10-14, "Built" below); the slots in new rooms come with steps 2-6.

WORLD-35 assigns a reward to every exploration dead end, but the systems that give rewards (STORY-06 collectibles, LIFE-04 gold and shop) are not built and LIFE-04 is undecided. A reward slot is a legend entity (`$`) placed in the `.room` now, with params `slot_id` and `kind`. The reach audit anchors it (`reach_role` CONTENT). STORY-06 or LIFE-04 later fills it by changing the scene behind the legend entry and a catalog keyed by `slot_id`. The `.room` files do not change again.

## Context

- The user (2026-10-14): "speaking of dead ends, there is quite a few that i don't fully understand. Are we leaving them there for maybe putting some rewards for trying to explore the map?"
- Today the answer lives in three places that drift apart. Design 04 tables name 5 collectibles. `reach_allowlist.tres` carries 8 entries whose reason is "STORY-06 ... stale once it lands". The roadmap's STORY-06 row names one more slot. Seven song-puzzle goals have no reward anywhere.
- The audit counts a place as served only if something stands on it. An empty goal therefore reads as DEAD_END_POCKET or LEADS_NOWHERE, and the allowlist grows.
- `architecture/rooms-are-text`: anything that means something in a room is a `.room` character from `room_legend.tres`. A slot kept only in a doc breaks that rule.

## Options considered

- **Status quo: allowlist reasons plus design-doc rows.** Rejected. No machine-readable list of slots exists, the world board cannot be drawn from data, and every new slot adds an allowlist entry that must be deleted by hand later.
- **A table of slots in `docs/` or the generator.** Rejected. It drifts from the map, as `MapGuide` showed for the legend (`architecture/rooms-are-text`), and it cannot anchor the audit without a second loader.
- **Build the STORY-06 collectible now and place real pickups.** Rejected. It needs notebook pages, text keys and the user's call on LIFE-04. That is a different item, and building it first would block the layout work.
- **A placeholder legend entity (chosen).** One character and one scene with two exports. The slot is in the text, the audit sees it, and the reward system fills it later without editing a map.

## Decision

- **Legend entry `$`** (kind ENTITY, `reach_role` CONTENT): "A reward slot: a place the layout promises a reward. `slot_id` unique across every map; `kind` COLLECTIBLE (STORY-06) or CACHE (LIFE-04, undecided)."
- **Scene** `scenes/world/interactables/reward_slot/reward_slot.tscn`. The root is a `Node2D` with `class_name RewardSlot`, `@export var slot_id: StringName` and `@export var kind: Kind` (`enum Kind { COLLECTIBLE, CACHE }`, append only). It draws nothing in release. In debug builds it draws one small marker so playtests and stills show it.
- **Tests:**
  - `room_files_test` fails on a duplicate or empty `slot_id`, the same check it runs for `bench_id` and a brute's `save_id`.
  - The generated map guide lists the entry.
- **Filling:**
  - STORY-06 points `$` at its collectible scene, keeping the same two exports, and reads its content from a catalog Resource keyed by `slot_id`. This follows `NotebookCatalog` (`architecture/notebook-entries-are-derived-from-the-save`).
  - If LIFE-04 is cut, CACHE slots become COLLECTIBLE or are deleted. That is a data edit.
- **The world board** (WORLD-35) reads slots from the `.room` text, never from a hand list.

## Consequences

- When the slots land, every allowlist entry whose reason says "STORY-06 ... stale once it lands" goes stale, and `room_reach_test` fails until they are deleted. Delete them in the same change.
- A slot alone gives nothing to the player. In release it draws nothing. The trade-off: the map edits that came with the slots do show.
  - Five new false walls (WORLD-35 step 1) open onto empty niches in release until STORY-06 or LIFE-04 fills them.
  - lake_waterfall_path's wall ledges are merged flush.
  - The rest of the change is the audit, the board and the debug markers.
- `kind` holds no reward data. Content belongs to the filling system's Resource, so no slot carries text and nothing here needs `tr()`.
- Do not use a slot for a teaching creature (CORE-04) or a flashback trigger (STORY-05). Those systems have their own behaviour and get their own legend entries when designed.

## Built (WORLD-35 step 1, 2026-10-14)

- **As decided, with two additions.**
  - `kind` is written as its number (0 COLLECTIBLE, 1 CACHE).
  - `room_files_test` also rejects a `kind` outside the enum.
  - `room_kit_test.test_every_reward_slot_is_reached_by_some_kit` fails when no kit reaches the surface under a slot. It mirrors the audit's anchor lookup (`ReachAudit.ANCHOR_DROP`) on each kit report.
  - `room_files_test` also fails on a slot with no ground or one-way in the cell under it. room_kit_test's ANCHOR_DROP lookup would accept a floating slot.
  - The debug marker is a 12 px diamond (gold for COLLECTIBLE, brown for CACHE) 22 px above the floor at z `RoomMapNode.SECRET_Z - 10`, drawn only when `OS.is_debug_build()`. That z keeps it under a closed secret's world copy (`playtests/2026-10-14-world35-step1`).
- **21 slots in today's rooms:** plan section 2.6 slots 1-14 and 23-29. Slots 15-22 lie in rooms that steps 2-6 build. Nine cells differ from the board: five because the board's cell floated above the floor or missed the room's own words, and the four niches:
  - woods_pond 11,5 (board 10,4).
  - woods_root_caves 3,16, the header's "col 3, standing on row 17".
  - village_empty_house 2,3: the header's reward alcove at cols 1-3, behind the gate. The board had 20,3.
  - village_tavern_cellar 17,8 (board 17,6).
  - woods_deep 25,32: the WORLD-31 pocket's floor. The board's 30,34 is in the hole to the root caves.
  - The four secret niches, carved where a hollow fits: frost_cliffs 10,39, lake_ice_caves 27,8, orchard_terraces 18,17, caldera_chimney_base 9,2.
- **caldera_chimney_base moved off the route** (orchestrator call, 2026-10-14; `bugs/the-caldera-chimney-base-false-floor-lies-on-the-only-route`). Step 1 first made a false floor on the only floor between the room's openings, so every player fell in. It is now a double-jump nook in the ceiling block, a shelf under a `[secret]` hollow with a stone back wall. Design 04 section 1's rule for secrets: "Not impossible to find, but with only subtle hints".
- **lake_shore's secret is cols 11-13.** Cols 14-15 stay a visible landing for the Congelar return. The far bank still holds the secret (design 04 section 3.5).
- **Allowlist.**
  - Five entries went stale and were deleted: caldera_dry_moat 26,4; lake_high_wall 16,20 and 16,29; village_bell_tower 12,3; woods_hut 10,4.
  - Four "STORY-06 ... stale once it lands" entries still match an error. Their reasons now give the real cause:
    - lake_high_wall 15,17, 16,23 and 16,26: the double jump from the raised ice skips them on the way to the slot.
    - woods_hut 7,6: a full jump also reaches the loft.
  - So "stale once it lands" held for five of nine entries. The audit's union can skip a step a kit without the double jump needs on the way: the lake kit (Redoma) climbs every rung of lake_high_wall's ladder.
- **LIFE-05: the fourth life note is in `caldera_temple_sanctum`.** The user chose "A fourth note somewhere late", then "Caldera temple sanctum" (user, 2026-10-14). The slot lies behind Verão Espacial 1's Sombra gate in caldera_temple_gate (cols 28-33).
  - The slot keeps kind COLLECTIBLE, since no new kind is needed.
  - LIFE-05 keys the note by the `slot_id` `caldera_temple_sanctum`, as STORY-06 keys its content. The catalog that fills `$` gives that id a life note instead of a letter.
  - Whether that slot also holds a letter is STORY-06's call.

## Built (WORLD-35 step 2, 2026-10-14)

- **Two slots in the woods' new rooms**, both CACHE: `woods_hollow_tree_cache` (plan slot 19, woods_hollow_tree 14,22, in the side hollow off the row-23 knot; the double jump or Enraizar) and `woods_crown_cache` (the optional woods_crown's slot, 12,8, on the branch over the hole; the double jump).
- **Total: 23 slots, 14 COLLECTIBLE and 9 CACHE.** Every one is reached by some kit (`room_kit_test`).
- **Still to come with their rooms:** plan slots 16 and 22 (step 3: lake_glacier, threshold_ravine_cave), 15, 20 and 21 (step 4: orchard_ridge, orchard_crag, orchard_summit), 17 (step 5: caldera_sun_stair) and 18 (step 6: frost_wreck_hold); the optional `lake_falls_head_letter` waits for MEM-10.

## Built (WORLD-35 step 3, 2026-10-14)

- **Two slots in the lake and threshold's new rooms**: `lake_glacier_alcove` (plan slot 16, COLLECTIBLE, lake_glacier 19,5, on a one-way ledge over the pool's middle, one jump from the ice and 16 cells from either lip; only kits with Congelar reach it, by the kit check. First placed on a shelf over the east lip, which wall climbers without Congelar reached up the icefall: review, 2026-10-14) and `threshold_ravine_cache` (plan slot 22, CACHE, threshold_ravine_cave 3,7, in the hollow under the ledge; the base kit, through the bridge's ravine secret).
- **Total: 25 slots, 15 COLLECTIBLE and 10 CACHE.** Every one is reached by some kit (`room_kit_test`).
- **Still to come with their rooms:** plan slots 15, 20 and 21 (step 4), 17 (step 5) and 18 (step 6); the optional `lake_falls_head_letter` waits for MEM-10.

## Built (WORLD-35 step 4, 2026-10-15)

- **Three slots in the orchards' new rooms**: `orchard_ridge_letter` (plan slot 15, COLLECTIBLE, orchard_ridge 12,3, on the knoll; Soltar + Vendaval through orchard_windy_gap's gate, or wall climb up the crag), `orchard_crag_cache` (plan slot 20, CACHE, orchard_crag 7,6, on the spire's top; wall climb) and `orchard_summit_cache` (plan slot 21, CACHE, orchard_summit 26,11, on the tor by the crest; the lift, or the walk from orchard_chasm_bridge with the double jump). The kit check reaches the ridge and the crag with the four autumn kits only, and the summit from the woods kit on.
- **Total: 28 slots, 16 COLLECTIBLE and 12 CACHE.** Every one is reached by some kit (`room_kit_test`).
- **Still to come with their rooms:** plan slots 17 (step 5) and 18 (step 6); the optional `lake_falls_head_letter` waits for MEM-10.

## Built (WORLD-35 step 5, 2026-10-15)

- **One slot in the sun stair**: `caldera_sun_stair_shrine` (plan slot 17, COLLECTIBLE, caldera_sun_stair 17,44, in the shrine alcove on the stair's floor; Sombra on the plate six cells from the gate, design 02 Verao Espacial 1). The kit check reaches it with the four summer kits only.
- **Total: 29 slots, 17 COLLECTIBLE and 12 CACHE.** Every one is reached by some kit (`room_kit_test`).
- **Still to come with its room:** plan slot 18 (step 6); the optional `lake_falls_head_letter` waits for MEM-10.

## Built (WORLD-35 step 6, 2026-10-15)

- **One slot in the wreck's hold**: `frost_wreck_letter` (plan slot 18, COLLECTIBLE, frost_wreck_hold 17,3, on the bow plank; the base kit, two jumps up the listing planks or one from the bow floor). The kit check reaches it with every kit, base included.
- **Total: 30 slots, 18 COLLECTIBLE and 12 CACHE.** Every slot of plan section 2.6 is placed, plus the optional `woods_crown_cache`. Every one is reached by some kit (`room_kit_test`).
- **Still to come:** only the optional `lake_falls_head_letter`, with MEM-10.
