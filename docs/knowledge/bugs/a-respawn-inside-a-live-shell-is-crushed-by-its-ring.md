---
id: bugs/a-respawn-inside-a-live-shell-is-crushed-by-its-ring
type: bug
title: Redoma forgets Ivo once he falls out through its bowl, so a respawn inside the live shell is crushed by the ring
status: fixed
severity: high
tags: [redoma, bell-jar, frost-shell, collision-exception, respawn, hazard, pzl-06, trials]
related: [playtests/2026-10-08-wall-of-water, architecture/the-bell-jar-closes-once, systems/bell-jar, bugs/temporary-song-floors-are-remembered-as-safe-ground, bugs/solstice-regrows-a-closed-bell-jar]
created: 2026-10-08
updated: 2026-10-08
source_files:
  - scenes/world/memory/song_effects/shell/frost_shell.gd
  - scenes/characters/ivo/player.gd
  - scenes/characters/components/safe_ground_tracker.gd
---

## Summary

`FrostShell` excepts a body only once, at `_close`, and drops the exception for good when
the body is more than `radius + CLEARANCE` (220 px) from the centre (`_let_out`,
`frost_shell.gd:103-109`). A fall into water under the shell's dry pocket takes Ivo past
that distance. The respawn then puts him back on the bank inside the shell (the safe ground
he left), and the ring is now solid to him from inside. When it contracts, `_refit` moves the
segments through his capsule, and he is shoved through the stone bank into the pool (1 HP).
Reproduced 4 times in the PZL-06 playtest, on the code as of 09:12.

## Symptom

Water trial section 3 (`trials_solstice`, `ShellSpawn`); minimal timeline
`tools/playtest/scripts/song_bell_jar_respawn_inside_shell.json` (Redoma only):

- t 8.0: Ivo walks off the bank into the dry pocket. He falls through the bowl (still
  excepted) into the water below it, 1 HP, and respawns at (16688, 6000), the shell's centre.
- t 17.1-17.5, standing still, with velocity 0 and `floor=true`: y 6000.1, then 6020.8 (inside
  the stone bank), then (16716, 6050) in the pool, `hurt`, a second HP lost. He respawns at
  t 18.3 once the shell is gone (`playtests/screenshots/2026-10-08-wall-of-water/shell_crushes_ivo_respawned_inside.png`).

The same chain follows every way of falling out through the bowl or leaving the disc:

- A short jump from the bank, after Congelar, lands in the pocket. Ivo falls into the water and
  respawns on the bank at x 16624, and the contracting ring later carries him off it (3 HP to 1).
- A jump onto the raised ice lands 225 px from the centre, and the exception drops.
  Walking back, he falls into the water once the ring has shrunk off the ice's end. He
  respawns at the centre and the ring sinks him 33 px into the bank, then into the pool.
- A jump made too early falls through the unset ice into the raised water. Back in the shell,
  he runs into the pocket and **lands on the inside of the bowl** (y 6138, `floor=true`),
  which no longer lets him out. The water just beyond the ring hurts him there (3 HP to 1).

## Root cause

`_close` (`frost_shell.gd:80-95`) is the only place an exception is added: "everything may
leave" is granted to whatever was inside at the moment the shell closed. Nothing re-grants it to
a body that comes back inside by `Character.teleport` (`Player.respawn`,
`player.gd:1025`), which is how every hazard respawn arrives. `SafeGroundTracker` records the
stone bank under the shell as safe, correctly. So the respawn point is inside a ring that is
solid to him. A shrinking `StaticBody2D` whose segment shapes are rewritten each frame does
not push him like a moving body: the solver separates him from overlapping segments as they
pass through him, toward the shell's centre and down into the stone.

## Fix

Not fixed. Options:

- Re-except any Player/Props body found inside the disc, not just at `_close`. A per-frame
  `intersect_shape` with `INSIDE_MASK` while closed, or a hook on teleport, both work.
  "Inside" must be the clean disc minus the ring's thickness, so a body standing on the ring
  from outside is not let through.
- Or never drop the exception while the body is inside `radius` (only once it is clear),
  plus the re-grant above for a body that arrives by teleport.

## Prevention

A scene test: close a shell, teleport a body to its centre, contract it, and assert the body's
position never enters the ground and the body is never on the ring's inner surface. No suite
under `tests/` covers `FrostShell` today.

## Resolution

Fixed before commit (2026-10-08): `FrostShell._adopt` runs every physics frame while the shell is closed and lets every Player or Props body wholly inside the ring (within radius - CLEARANCE) pass it, as at closing: nothing enters through the ring, everything inside may leave. `song_bell_jar_respawn_inside_shell.json` now costs only the fall's 1 HP and Ivo stands on the bank.
