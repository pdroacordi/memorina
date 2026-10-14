---
id: bugs/the-woods-deep-pit-shaft-traps-a-kit-without-the-double-jump
type: bug
title: The shaft to woods_deep's root-caves pit is a one-way drop for a kit without the double jump, and Redoma takes a Lake-first kit down into woods_root_caves
status: resolved
severity: high
tags: [tech-08, kit-check, softlock, progression, spring-woods, woods-deep, woods-root-caves, redoma, enraizar]
related: [architecture/room-reachability-audit, systems/rooms, bugs/a-redoma-first-player-is-trapped-in-the-summer-caldera]
created: 2026-10-14
updated: 2026-10-14
source_files:
  - scenes/world/rooms/spring_woods/contents/woods_deep.room
  - scenes/world/rooms/spring_woods/contents/woods_root_caves.room
  - resources/world/maps/reach_allowlist.tres
  - resources/save_facts/knows_root.tres
---

## Summary

Found by the TECH-08 kit check on its first run (HEAD 0128b8d). Two KIT_TRAP findings, first allowlisted as open decisions:

- **+Memorina** (no double jump, no songs), `woods_deep 40,32`, 4 cells. The shaft at cols 42-43 (rows 28-30) drops onto the
  pit's east bank (cols 40-43, feet row 32). The way out up the shaft needs feet row 27: 5 rows, and a single jump rises 4.
  West of the bank is the pool (cols 33-39) under a 2-row tunnel: a hazard without Redoma, and no room to jump it. Any fall
  down the east side of the room reaches the shaft (7 ways in, from 44,3 down to 45,29).
- **+Lake** (Redoma, Congelar, roll; no double jump), `woods_deep 24,32`, 70 cells over woods_deep and woods_root_caves.
  Same drop, then Redoma walks the pool the Enraizar bridge is meant to span (header: "Enraizar bridge, earth banks cols
  32/40"), and the hole at cols 28-31 drops into woods_root_caves. Its only way back is Enraizar up the hole (design 04
  section 3.4: "Enraizar (retorno)"). Design 04 section 2 lets the Lake come before the Woods.

Neither pocket holds a bench, so a player can still load the last save; the session is lost.

## Root cause

The room was built for a player who already owns the Bloom Guardian's gifts (double jump or Enraizar). Nothing stops an
earlier kit from falling in, and Redoma is a second key to the pit that the header did not plan for.

## Options weighed (first run)

- **+Memorina:** open `woods_deep` col 44 at rows 28 and 29 (the trunk between the shaft and the east corridor). From the
  bank, a single jump reaches the block top at row 30 (cols 44-46), then drops into the corridor. Checked in a scratch copy:
  the kit check passes for +Memorina, and the union audit is unchanged (63 findings). A stone step at (43,30) also fixes it,
  but the union audit flags the step as LEADS_NOWHERE: the union holds every song, so it cannot tell that only song-less kits
  need the step. The col-44 opening changes the shaft's look and removes its Enraizar shaft at rows 28-29 (the double jump
  climbs it anyway). Re-run the woods timelines after it.
- **+Lake:** the open item. With the col-44 opening the pocket shrinks to woods_root_caves (59 cells, entered from the hole).
  Options:
  1. A barrier before the hole that opens with Enraizar (a new `SaveFact` `knows_root.tres`; the slab at row 30 needs a
     one-cell notch, since a barrier stands three rows tall and the tunnel has two). The pit then needs what its header says.
  2. A way out of the root caves without Enraizar. This changes design 04 section 3.4's "Enraizar (retorno)".
  3. Keep Redoma as a second key and give the root caves a Redoma or Congelar way back.

## Fix (2026-10-14)

- **+Memorina** (orchestrator call, the recommended option): `woods_deep` col 44 is open at rows 28 and 29, where the trunk
  stood between the shaft and the east corridor. From the bank a single jump reaches the block top at row 30 (cols 44-46),
  then drops into the corridor. The `[back]` pocket wall (rows 31-33, WORLD-31) is untouched; the opened cells show the
  backdrop like the shaft beside them. The shaft loses its Enraizar span at rows 28-29; the double jump climbs it anyway.
  A stone step at (43,30) was rejected: the union audit flags it LEADS_NOWHERE, because the union holds every song and
  cannot tell that only song-less kits need the step.
- **+Lake**: user, 2026-10-14, "Root wall that opens with Enraizar (Recommended)": "A tangle of roots before the hole that
  only opens once Ivo knows Enraizar, so he can't drop in without the song that brings him back. Keeps the design's
  "Enraizar (retorno)" true; needs a small notch in the tunnel ceiling and a new save fact." Built:
  - a FactBarrier `X` at col 32, row 32 (on the west bank, rows 30-32), with `requires` set to
    `res://resources/save_facts/knows_root.tres` (new: SONG, `Enums.Song.ROOT`) and art
    `assets/sprites/world/props/spring_woods/root_wall.png` (443079b);
  - a notch at slab cell (32,30), so the barrier fits the 2-row tunnel. Row 29 above it is solid, so the wall cannot be
    hopped. The `[back]` wall shows through the notch.
  - The Enraizar bridge still forms: its earth end (32,33) keeps air above it in the map, since an entity cell is not solid.
    With Enraizar the wall is gone, and the bridge and the hole work as before.
- Both KIT_TRAP allowlist entries are removed. The kit check finds 0 traps in all eleven kits. The lake kit and
  lake-then-Caldera no longer reach woods_root_caves; the woods kit still does (`room_kit_test`).
- The union audit's errors are unchanged. One warning moved: woods_canopy's 292-cell DEAD_END_POCKET splits into 170
  cells and a 102-cell woods_root_caves pocket, because the wall is an anchor (GATE).
- Playtest stills: `playtests/2026-10-14-tech08-kit-traps`.

## Prevention

`room_kit_test` (TECH-08) checks every kit stage on every change. It fails on any new kit trap, and on an allowlist entry
that no longer matches one.
