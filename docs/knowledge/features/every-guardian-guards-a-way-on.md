---
id: features/every-guardian-guards-a-way-on
type: feature
title: Every guardian's arena guards a way on; seven loops lead back to a bench or the village; every dead end holds a reward slot; long drops land soft
status: active
tags: [world, world-35, layout, loops, shortcuts, reward-slot, secrets, soft-landing, fact-grate, benches, kit-check]
related: [systems/world, systems/rooms, systems/guardians, systems/life-benches-death, architecture/reward-slots-reserve-their-place-in-the-room-text, architecture/room-reachability-audit, playtests/2026-10-15-world35-step7]
created: 2026-10-15
updated: 2026-10-15
source_files:
  - tools/maps/gen_world_shells.py
  - scenes/world/interactables/reward_slot/reward_slot.gd
  - scenes/world/interactables/fact_barrier/fact_grate.tscn
  - resources/save_facts/guardian_restored_summer.tres
  - scenes/world/environment/soft_landing/soft_landing.gd
  - scenes/characters/components/landing_rule.gd
  - scenes/world/environment/props/frozen_lake/snow_drift.tscn
  - scenes/world/environment/props/wind_orchards/leaf_pile.tscn
  - resources/world/maps/reach_kits.tres
---

## Summary

WORLD-35 (2026-10-14 to 2026-10-15). Before it, three of the four guardian arenas were the last room of their region. Now each arena opens onto a new route: the next region, a reward, or a shortcut home. Seven loops end at a bench or in the village. Every exploration dead end holds a reward slot. Long one-way drops land in deep snow or leaves. Contract: `systems/world` (room table) and `systems/rooms` (legend `$`, `g`, `n`). Design: 04 §2 (overview, loops), §3 (rooms).

## Details

**What each guardian leads to** (design 04 §2, "Além da arena"):

| Arena | Way on | Kind |
|---|---|---|
| bloom_hollow (Bloom) | W into woods_hollow_tree, a 4-screen climb by double jump or Enraizar pillars up through orchard_mill_town's well | the Orchards' third entrance |
| lake_frost_arena (Frost) | E into lake_glacier (a 34-cell pool only Congelar crosses, a letter over it), then lake_icefall, a one-way 2.4 s drop through threshold_icefall_foot into deep snow on threshold_bridge's fallen span | reward, then a shortcut home (wayshrine bench one room east) |
| orchard_arena (autumn, GRD-04) | the cliff chimney to the Caldera (wall climb) as before, plus wall climb up the E wall into orchard_crag, E to orchard_ridge, and a soft drop to orchard_leaf_path | next region, two rewards, a loop |
| caldera_arena (summer, GRD-04) | E into caldera_sun_stair, a base-kit stone spiral up to a vault under village_gate_east's road; the `FactGrate` there opens on `guardian_restored_summer.tres` | reward (Sombra shrine), then a shortcut home |

**Loops** (design 04 §2, "Voltas e atalhos"): A and B existed but nothing showed them; C-G are new. All seven were driven windowed in step 7 (`playtests/2026-10-15-world35-step7`).
- A: woods, canopy, terraces, chasm bridge, lake_chasm, high wall, shore, fishing village, waterfall, village mill.
- B: orchard arena, chimney, Caldera, crater, cistern, square.
- C: bloom_hollow, hollow tree, mill town, terraces, canopy, woods_deep.
- D: frost arena, glacier, icefall, bridge, wayshrine, village.
- E: orchard arena, crag, ridge, leaf path, mill town.
- F: terraces, mill town, counterweights lift, orchard_summit, chasm bridge or a drop to the terraces.
- G: caldera arena, sun stair, the grate, gate_east, square.

**New rooms.** There are 10 new world rooms: woods_hollow_tree, woods_crown (optional), lake_glacier, lake_icefall, threshold_icefall_foot, threshold_ravine_cave, orchard_crag, orchard_ridge, orchard_summit and caldera_sun_stair. One new interior: frost_wreck_hold, through the breach of the wreck on frost_shore. The world now has 54 rooms and 15 interiors. No existing room moved or changed size, so `SceneKey` map keys and saves stay valid. Existing rooms only gained openings, slots, secrets or benches, as `.room` edits.

**Benches.** orchard_mill_town_bench (two rooms from the orchard arena; it was five) and caldera_chimney_base_bench (where a chimney arrival lands; it was 11 screens from the crater bench). Nine world benches in all.

**Reward slots** (`$`, `RewardSlot`; `architecture/reward-slots-reserve-their-place-in-the-room-text`). 30 slots: 18 COLLECTIBLE (STORY-06) and 12 CACHE (LIFE-04, undecided). In release they draw nothing; in debug builds each draws a small diamond. `caldera_temple_sanctum` will hold LIFE-05's fourth life note.

**Secrets.** There are 8 world secrets, 6 of them new: threshold_bridge's ravine wall (down into threshold_ravine_cave, the first secret, base kit), lake_shore's far niche (design 04 §3.5), and niches in frost_cliffs, lake_ice_caves, orchard_terraces and caldera_chimney_base.

**Soft landings** (`n`, `SoftLanding`, `LandingRule`; `systems/rooms` "Soft landing"). A landing inside the zone is a plain landing, never the 0.75 s hard landing. There are three:
- the snow drift under the icefall, the user's "Straight drop into deep snow (Recommended)";
- the leaf piles under the ridge's drop and the summit's drop (orchestrator calls following that choice).

**The grate** (`g`, `fact_grate.tscn`). The `FactBarrier` script under a horizontal floor shape, flush in the road at gate_east cols 29-32. `SaveSystem.progress_changed` refreshes it, and a death rewinds `restored_guardians`, so the grate closes again with them. Before GRD-04 it is always closed: the stair shows the way home and the shut grate.

**One-way drops** (icefall, ridge, summit, the well into the tree). Each lands where a base-kit walk leads on. Wall climb climbs back up the icefall, the crag and the ridge: the plan's backtrack payoff.

## Why

- The user, 2026-10-14: "why would I actually want to fight a guardian, if it's region is a dead end? It protects nothing.", "speaking of dead ends, there is quite a few that i don't fully understand. Are we leaving them there for maybe putting some rewards for trying to explore the map?", "We should explore more vertically. Create more branches of exploration, more things that connect."
- Every way on uses only what that guardian or an earlier one gives, so the design order (04 §2) and every entrance gate are unchanged.
- Kit rule (`bugs/a-redoma-first-player-is-trapped-in-the-summer-caldera`): every new entrance has an exit for each kit that can use it. TECH-08's kit check (11 kits) holds it: 0 kit traps.
- The slots are text, so the audit, the world board and STORY-06 read one source (`architecture/rooms-are-text`).

## Gotchas / pitfalls

- **A loop's middle floors read as DEAD_END_POCKET.** The reach audit's song union opens the grate, so the Caldera is reached from both ends. A floor that touches no exit then "dominates none". The 42 pockets after step 7 are classified in `architecture/reward-slots-reserve-their-place-in-the-room-text` ("Final audit"). Do not "fix" a loop floor.
- **The union cannot see order.** With the grate open, the union finds a second way between the Caldera and the village, and three caldera_cistern LEADS_NOWHERE entries are allowlisted for it. The kit check, not the union, decides traps.
- **A room stacked over a gap clips the jump under it** (`gotchas/a-room-stacked-over-a-gap-clips-the-running-jump`). The ridge's crest, the icefall foot's rock and the crag's overhang were raised for this. Check jump apexes under any new room's floor.
- **A Redoma shell is standable ground up to 192 px over its origin** (`gotchas/a-redoma-shell-is-standable-ground-up-to-192-px-over-its-origin`). A one-way lip must stand more than 462 px up (shell plus double jump) to be one-way for a Redoma kit; the summit's west lip (448-480 px) is accepted as two-way.
- **GRD-04 must hold the fight in on both sides** of orchard_arena and caldera_arena (`systems/guardians`, GRD-05). Both now have an opening on each side; walking out abandons the call, as at bloom_hollow and lake_frost_arena.
- **The region cuts on the new crossings are snaps, not glides**: the mill-town well, threshold_icefall_foot and the grate. FallReach never shows the other region early.
