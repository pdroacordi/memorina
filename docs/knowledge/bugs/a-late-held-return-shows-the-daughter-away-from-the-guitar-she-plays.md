---
id: bugs/a-late-held-return-shows-the-daughter-away-from-the-guitar-she-plays
type: bug
title: The Try-again return heard at 0.6 plays her guitar notes at the guitar while she is drawn standing by the drawings and the guitar is hidden
status: fixed
severity: medium
tags: [story, staging, fact-staging, opening, village, priority]
related: [systems/story, architecture/the-opening-is-staged-by-save-facts, bugs/the-memorina-before-the-song-hides-the-guitar-and-keeps-the-elders-audience]
created: 2026-10-15
updated: 2026-10-15
source_files:
  - scenes/world/rooms/home_village/contents/village_house_contents.tscn
  - resources/dialogue/story/daughter_guitar.tres
---

## Summary

FIXED 2026-10-15, medium (STORY-03 phase B review, 2026-10-15). The Daughter staging's first stage is Standing at 2 or more guardians restored. It outranks AtGuitar (Memorina + `guitar_try_again`), so a `daughter_return` heard late, at 0.6, plays at an empty spot. WallGuitar still hides the guitar because `daughter_return` is unheard.

## Symptom

Save: `baker_errand` and `daughter_song` heard, `morning_song` = `guitar_try_again`, Memorina owned, two guardians restored, `daughter_return` not heard (Ivo never went home between the lighthouse and the 0.6 step). The review's probe gives Daughter = Standing (x 44, by the drawings) and WallGuitar = none. The guitar's Talkable (col 9) has `daughter_return` pending and auto-starts. The `daughter_guitar` beat faces `Props/Daughter/AtGuitar/Girl` (hidden, x 290) and plays her four notes on the strings. Then "That's a strange one." is said from x 290, where nobody stands, and no guitar is drawn anywhere until the talk's end puts it back on the wall. The brief asks that "the return talks heard late still work". The talk runs, but its scene contradicts it.

## Root cause

`village_house_contents.tscn:238`: the Daughter's `stages` list `story_2` (≥2 guardians → Standing) first, ahead of `story_11` (Memorina + `guitar_try_again` → AtGuitar). WallGuitar's `story_22` (Memorina + `guitar_try_again`, unless `daughter_return` → none) has no matching ≥2 guard, so the two stagings disagree about where the guitar is.

## Fix

Fixed 2026-10-15. The Daughter staging's first stage is AtGuitar (`mentor_gift` heard, `guitar_try_again`, unless `daughter_return` heard), above Standing at 0.6; WallGuitar's matching "none" stage has the same gates. A held return heard late, at 0.6, finds her at the guitar, and after it she stands by the drawings with the guitar on the wall. Test: `opening_test.test_a_late_held_return_finds_her_at_the_guitar`.

## Prevention

For every FactStaging that a pending talk's beat or speaker point refers to, test the pending talk's save at each later memory step (`opening_test`, the 0.6 case), not only in script order.
