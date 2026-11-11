---
id: bugs/a-standing-brace-cuts-the-memorina-lower-clip
type: bug
title: The MEM-16 standing BRACE is resolved before MEMORINA_LOWER, so the put-away clip is skipped whenever a song ends facing into a wind
status: resolved
severity: low
tags: [animation, resolver, brace, memorina, wind, mem-16]
related: [playtests/2026-11-11-mem16-gust-feel, systems/animation, systems/air, bugs/a-standing-brace-plays-the-push-walk-cycle-in-place]
created: 2026-11-11
updated: 2026-11-11
source_files:
  - scenes/characters/ivo/player_animation_resolver.gd
  - scenes/characters/ivo/player.gd
---

## Summary

Open (found in review of the uncommitted MEM-16 change). In the resolver's idle branch,
`if _player.is_bracing(): return BRACE` (`player_animation_resolver.gd:110`) comes before the
MEMORINA_LOWER check (line 113). Standing `is_bracing()` is true as soon as the Memorina is no
longer drawn (`player.gd:496`), so on the first frame after a song ends or is interrupted while
Ivo faces a wind of `brace_wind` (60 px/s) or more, BRACE replaces the lower clip. The
instrument disappears with no put-away.

## Details

The common case is a gust breaking a song (its slide makes `is_still()` false). The interrupt
leaves Ivo standing in that same gust, and if he faces into it the lower clip never plays. The
comment on the lower branch reads "any movement cuts it". Facing into the wind while standing is
not movement.

## Fix (proposed)

Move the standing BRACE check below the MEMORINA_LOWER return. Lower holds only for its own
length (`driver.holding`), and BRACE takes over when it ends.

## Prevention

A new idle-branch pose goes below every one-shot that finishes an action (LAND, STAND_UP,
MEMORINA_LOWER), not above.

## Play evidence (2026-11-11, `playtests/2026-11-11-mem16-gust-feel`)

On the fixed code (17:00:29), run `brk`: FREEZE drawn in the calm at forced memory 1, facing east into the coming gust.
The gust broke it on the 4th note (t 7.23, `air` -187). `memorina_lower` then played for 0.35 s while he was already
sliding at 41-52 px/s, and `brace` took over at t 7.58.
