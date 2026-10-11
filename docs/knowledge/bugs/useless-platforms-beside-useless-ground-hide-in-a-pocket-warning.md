---
id: bugs/useless-platforms-beside-useless-ground-hide-in-a-pocket-warning
type: bug
title: Platforms that lead nowhere become DEAD_END_POCKET warnings when any useless ground or roof is one jump or fall away
status: resolved
severity: medium
tags: [rooms, reachability, audit, level-design, tests]
related: [architecture/room-reachability-audit, systems/rooms]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - scenes/world/rooms/maps/reach/reach_audit.gd
---

## Summary

`ReachAudit._flag_useless` groups every useless surface by WALL_CLIMB edges in both directions. Any group that holds one ground or roof surface becomes a single DEAD_END_POCKET warning, so most platforms that lead nowhere never reach the LEADS_NOWHERE error gate.

## Symptom

TECH-05 review, 2026-10-11, measured on the whole world. 5 LEADS_NOWHERE errors fire, but 20 pocket warnings absorb 70 platform surfaces. Examples: orchard_chasm_bridge holds 17 platforms with 42 ground surfaces, lake_fishing_village 15 with 28, caldera_open_crater 7, and village_bell_tower 5 (a STORY-04/06 slot the architecture entry expected as an allowlisted error). `room_reach_test` passes with all of them in place. The user asked for these platforms to be flagged ("random platforms that lead nowhere", 2026-10-10).

## Root cause

`reach_audit.gd:320-338` grows a connected component over `forward[wall]` and `backward[wall]` among useless surfaces. A backward edge is enough to join a group: a useless ledge Ivo can drop from onto a useless roof joins the roof's group. If any member has `Support.GROUND`, and roofs count as ground (`reach_audit.gd:96`), the whole component is reported as one warning, and its platforms are never candidates for the greedy LEADS_NOWHERE/REDUNDANT_ROUTE pass. The component can also span rooms, but the finding is named after its first surface's room.

## Fix

None yet. The decision belongs to the user (see the pocket clause in `architecture/room-reachability-audit`). Options:
- Build pockets from ground surfaces only and keep each platform in the LEADS_NOWHERE pass.
- Join a platform to a pocket only when the pocket's ground is not a roof.

## Prevention

Add an audit fixture: a useless `====` ledge one jump above a useless stone shelf. It must report LEADS_NOWHERE on the ledge, whatever the shelf reports.

## Resolution (2026-10-11)

A useless group is split by support: its ground and roofs form the DEAD_END_POCKET warning, and every platform in it goes to the LEADS_NOWHERE check with the greedy REDUNDANT_ROUTE demotion (`ReachAudit._flag_useless`). Fixture: `reach_audit_test.test_a_platform_beside_a_dead_end_pocket_still_leads_nowhere`. The new errors are in `reach_allowlist.tres`.
