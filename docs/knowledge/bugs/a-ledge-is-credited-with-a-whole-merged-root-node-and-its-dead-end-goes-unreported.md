---
id: bugs/a-ledge-is-credited-with-a-whole-merged-root-node-and-its-dead-end-goes-unreported
type: bug
title: A ledge whose pillar touches a needed root shaft or curtain is credited with the whole merged transit node, and ReachAudit reports nothing for it
status: resolved
severity: medium
tags: [rooms, reachability, audit, roots, tests]
related: [architecture/room-reachability-audit, systems/rooms, bugs/useless-platforms-beside-useless-ground-hide-in-a-pocket-warning]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - scenes/world/rooms/maps/reach/reach_audit.gd
  - scenes/world/rooms/maps/reach/reach_grid.gd
  - tests/scenes/world/rooms/maps/reach/reach_audit_test.gd
---

## Summary

TECH-06's "roots go with their ledge" credits a platform or shelf with every TRANSIT node that touches a root span ending in its slab. TRANSIT nodes are 4-connected floods across all spans and currents. A small ledge therefore owns a whole shaft or pillar curtain. If that node dominates an anchor, `_flag_useless` skips the ledge with `continue`, so a dead end is reported as nothing at all: no LEADS_NOWHERE, no REDUNDANT_ROUTE.

## Symptom

Found in the TECH-06 review, 2026-10-11, with a scratch fixture run on the real `ReachAudit` and `ReachFixture.rooted_grid`. The room is a 4-wide earth shaft (walls at cols 4 and 9, rows 4-20, earth floor at row 21) and its only way up to a bench on the block east of it. A 2-cell earth shelf sticks out of the east wall into the shaft at row 12, cols 7-8. It is classified `Support.SHELF`, it is reached, and it leads nowhere. The audit returns **no findings**. An instrumented copy shows the shelf credited with one 58-cell transit node: the whole shaft, joined to the 8-row pillars under the shelf.

Real world on 2026-10-11: no ledge is kept by a useful root yet, so no allowlist entry is affected. But the over-crediting is already present:
- woods_hut's two STORY-06 ledges are each credited with an 87-cell node, the room-wide pillar curtain between its earth floor and ceiling;
- woods_deep's ledges are credited with nodes of 25-35 cells.

## Root cause

- `reach_audit.gd:458-467` (`_grown_from`): for each `ReachGrid.Root` with an end in the slab, every TRANSIT node on the root's cells is added. `_node_for` (`reach_audit.gd:290-306`) floods TRANSIT cells into one node across span boundaries, so a 2-cell pillar under a shelf shares a node with the shaft it stands in, with adjacent pillar columns, or with a current.
- `reach_audit.gd:392-396`: a ledge whose credited node is useful (a dominator or an anchor) is skipped before the greedy pass. Removing the shelf in the game would leave the shaft in place. The architecture revision says a merged node "leans to REDUNDANT_ROUTE". That is true only when the node is not a dominator. When it is one, the ledge disappears from the report.

## Fix

Open. Options:
- Keep TRANSIT nodes per span, so a ledge owns only the nodes of spans that end in its slab.
- Or credit a node only when every span crossing its cells ends in the ledge's solid.
- Either way, send a ledge with useful roots through the `_cuts` check instead of `continue`, so an over-credited ledge shows as a REDUNDANT_ROUTE warning rather than vanishing.

## Prevention

Add a `reach_audit_test` fixture: a dead-end earth shelf inside an earth shaft that is the only way to content. It must report LEADS_NOWHERE, or at least REDUNDANT_ROUTE, never nothing.

## Resolution (2026-10-11)

`_grown_from` credits a ledge with a transit node only when every root crossing the node's cells has an end in the ledge's island or slab and no current runs through it (`_made_only_by`, with a cell-to-roots map built once). The `continue` for a ledge with a useful node stays: with that rule the node goes when the ledge goes, so the ledge is needed. A ledge whose pillars merge into a shaft is credited with nothing and is judged like any platform.
- `reach_audit_test.test_a_shelf_in_a_needed_root_shaft_still_leads_nowhere` is the review's fixture: LEADS_NOWHERE 7,11. With the old crediting it returns no findings.
- `test_a_ledge_whose_roots_lead_to_content_is_fine` and `test_removing_a_ledge_removes_the_roots_it_grows` still pass: a lone island's pillar is its own.
- World: no finding changed (366 surfaces, 60 findings). woods_deep 50,14 stays REDUNDANT_ROUTE, and woods_hut's two STORY-06 ledges stay LEADS_NOWHERE, allowlisted.

