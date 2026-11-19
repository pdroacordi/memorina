---
id: bugs/the-frost-arena-ceiling-leaves-26-px-over-the-golems-head-so-a-pogo-bounce-falls-back-into-contact
type: bug
title: In lake_frost_arena Ivo's head meets the ceiling with his feet 202 px up, 26 px over the golem's 176 px top, so a pogo bounce bonks at once and drops him back into contact; without the double jump the head cannot be reached at all
status: resolved
severity: medium
tags: [guardians, frost, grd-14, pogo, ceiling, arena, contact, playtest]
related: [playtests/2026-11-18-grd14-frost-feel, bugs/a-pogo-on-the-frost-golems-head-stops-it-attacking, systems/guardians]
created: 2026-11-18
updated: 2026-11-18
source_files:
  - scenes/world/rooms/frozen_lake/contents/lake_frost_arena.room
  - scenes/characters/guardians/frost_guardian/frost_guardian.tscn
---

## Summary

"O pogo é a brecha" (user, 2026-10-29) makes bouncing on a guardian a valid way out of its moves. Against the Frost golem
in its own arena the bounce has almost no room:
- The arena's ceiling row is 256 px above the floor (`arena_bounds()` y -1920, floor y -1632, one 32 px row).
- Ivo's 54 px body meets it when his feet are 201.9 px up.
- The golem's capsule top is 176 px.

That leaves 26 px over the head. The pogo reaches 28 px below the feet. Each bounce bonks the ceiling within ~0.05 s and
falls straight back onto the head, where the golem's contact hurts him. With only a single jump (apex 141.5 px) the head
cannot be reached at all. Frost may be the first guardian, so for that player the brecha does not exist in this fight.

## Symptom

- **Single jump, `PL_POGO=1`, `skills: []`, 90 s** (`pogo1`): 32 tries, 0 pogo hits, pressure 0.00 at the end.
- **Double jump, closed-loop pogo, `PL_PG=1`, `skills: [0]`** (`pg2`, `pg3`, 90 s each; the driver steers over the head
  and presses down + attack while falling 200-250 px up):
  - The highest feet position in ~50 jumps was 201.9 px.
  - Two pogos landed: t 7.111 with the feet 186 px up, and t 11.600 at 189 px.
  - The first bounce: vy -385, then 0.0 at 7.195 with the feet 201.9 px up (the head on the ceiling). Ivo falls back
    onto the head and takes contact at 7.545 (dy 170, `atk=` empty).
  - The second pogo was followed by contact at 12.017.
  - Rising beside the golem to get over it cost 12 more contact hits: a body 68 px wide and 176 px tall, beside a
    double jump that clears its top only 26 px before the ceiling.
- Frame: `playtests/screenshots/2026-11-18-grd14-frost-feel/pogo_ceiling.png` (Ivo on the head, the ceiling row above).

## Root cause

The arena's ceiling row is one row too low for a 176 px guardian plus a pogo bounce. The body drop's 72 px apex is
already capped by the same ceiling (`systems/guardians`).

## Fix

Fixed in GRD-14 (2026-11-18) without raising the ceiling. The arena already spans its whole 384 px screen (rooms are
whole 640x384 screens, `systems/world`), so raising the ceiling means lowering the floor a row or two. That moves both
doorway sills to `lake_ice_caves` and `lake_glacier`, the FightWalls and the golem's spawn, a world edit out of
proportion to the fix.

Instead the golem's head is a standable top (the entry's second option): its `ContactHitbox` capsule is 156 px tall
(top at y -156), 20 px under the 176 px hurtbox. An Ivo bounced off the head can fall from the ceiling's 202 px (feet)
to 150 px, 52 px (about 0.33 s), and strike the head again before the contact box reaches him. The pogo needs the double
jump here: a single jump's 141.5 px apex is under the head. `frost_guardian_kit_test.test_a_pogo_has_room_over_the_head`
pins it.

## Prevention

Add an arena test: for each guardian, ceiling height minus body height must be at least Ivo's body height plus a pogo
bounce's rise.
