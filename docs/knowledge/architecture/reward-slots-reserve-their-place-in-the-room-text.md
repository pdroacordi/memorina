---
id: architecture/reward-slots-reserve-their-place-in-the-room-text
type: architecture
title: A reward slot is a legend entity placed in the .room before the reward system exists, anchored for the reach audit and filled later by slot id
status: active
tags: [rooms, room-map, legend, rewards, collectibles, reachability, level-design, story-06, life-04, world-35]
related: [architecture/rooms-are-text, architecture/room-reachability-audit, architecture/secret-false-walls, systems/rooms, systems/world, systems/notebook]
created: 2026-10-14
updated: 2026-10-14
source_files:
  - resources/world/maps/room_legend.tres
  - resources/world/maps/reach_allowlist.tres
  - scenes/world/rooms/maps/reach/reach_audit.gd
  - tests/scenes/world/rooms/room_files_test.gd
---

# Reward slots reserve their place in the room text

## Summary

Accepted 2026-10-14: "Yes, invisible markers (Recommended)" (user, on the WORLD-35 board).

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
- A slot alone gives nothing to the player. Until STORY-06 or LIFE-04 ships, the release build looks exactly as it does today. Only the audit, the board and debug markers change.
- `kind` holds no reward data. Content belongs to the filling system's Resource, so no slot carries text and nothing here needs `tr()`.
- Do not use a slot for a teaching creature (CORE-04) or a flashback trigger (STORY-05). Those systems have their own behaviour and get their own legend entries when designed.
