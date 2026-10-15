---
id: bugs/the-memorina-before-the-song-hides-the-guitar-and-keeps-the-elders-audience
type: bug
title: The Memorina taken before the daughter's song hides the house guitar for good and leaves the elder's children on his bench for good
status: fixed
severity: medium
tags: [story, staging, fact-staging, save-fact, opening, village, debug]
related: [systems/story, architecture/the-opening-is-staged-by-save-facts, systems/dialogue, bugs/a-late-held-return-shows-the-daughter-away-from-the-guitar-she-plays]
created: 2026-10-15
updated: 2026-10-15
source_files:
  - scenes/world/rooms/home_village/contents/village_house_contents.tscn
  - scenes/world/rooms/home_village/contents/village_elder_contents.tscn
  - resources/dialogue/story/daughter_near.tres
  - resources/dialogue/story/elder.tres
---

## Summary

FIXED 2026-10-15, medium (STORY-03 phase B review, 2026-10-15). `daughter_song` is `unless MEMORINA`, so once Ivo owns the Memorina the song can never be heard. The stagings assume the song came first. With the errand heard and no song, `WallGuitar` stays on its "none" stage, so the guitar is gone from the house permanently. With no `elder_story` (it needs `daughter_song`), the elder's audience stays on the bench permanently, including at 0.6 when `elder_empty` tells the story to an empty room.

## Symptom

Probed with `FactStaging`'s rule over each save (`SaveFact.gates_pass` on every stage, first that holds):

| Save | Daughter | WallGuitar | Audience | Talks |
|---|---|---|---|---|
| Debug new game (Memorina owned) | Standing | OnWall | Listening | bed `daughter_errand`, elder `elder_return` |
| `baker_errand` heard, then the Memorina, no song | Standing (empty-handed) | **none** | Listening | none in the house; elder `elder_return` |

- Release: the lighthouse is reachable with the base kit (`reach_kits.tres`: sword and movement), and the east road is open by design ("the elder is a pointer, not a gate"). A player who does the errand, or skips home, and goes east gets the Memorina first. Back home the guitar is on neither the wall nor the girl, and nothing ever brings it back: `OnWall` needs `daughter_song`.
- Debug: a plain debug new game owns the Memorina (`BootPolicy.new_game_owns_items`), so the daughter stands from the first frame while the bed says "Bread. The round one." (scripted as half asleep). After the bakery the guitar vanishes as above.
- The elder: `Audience` reads only `elder_story` heard. Without the song that talk never opens, so the two children stay on his bench through `elder_return` and through `elder_empty` at 0.6, whose script says "The children are gone from his house... He stops and looks at the empty bench."

## Root cause

- `village_house_contents.tscn:175` (`story_26`, the WallGuitar stage `show = ""` when `baker_errand`) has no `unless MEMORINA`. That stage means "the girl holds the guitar out" (`HoldingOut`). The Daughter staging drops `HoldingOut` once the Memorina is owned (`story_13`, Standing, ranks above it), but the guitar staging still hides the guitar.
- `village_elder_contents.tscn:33` (`story_2`) hides the audience only on `elder_story` heard. No other fact ever ends the visit.
- Both come from one assumption: the opening's facts accrue in script order. `daughter_near.tres` (`daughter_song` `unless` MEMORINA) and `elder.tres` (`elder_story` `when` `daughter_song`) make the out-of-order path permanent.

## Fix

Fixed 2026-10-15, after the user's decision on "A player can walk east to the lighthouse before the song and the elder's story, skipping the call to adventure. How should the opening hold together?": "East gate shut until the elder points east (Recommended)": "The village's east gate stays closed (the existing gate barrier) until the elder's story has been heard; his "East. It's still there." is when it opens. The opening always plays in order. The reach audit learns that the opening's talks are part of the starting kit.".
- `village_gate_east` has a `FactBarrier` (legend `X`, col 38) on `heard_elder_story.tres` (DIALOGUE_HEARD `elder_story`; both of his choices end that talk). The Memorina can no longer come before the song in a game.
- The house reads talks: every `owns the Memorina` gate in the house's stages and talks became `mentor_gift` heard (the gift is heard in the same talk that grants it). A debug new game, which owns both items from the first frame, shows the daughter asleep and plays the morning in order.
- WallGuitar's "held out" stage (`baker_errand`) is `unless mentor_gift`, so the guitar is back on the wall whatever was skipped.
- The elder's audience also leaves at 0.6 (`GUARDIANS_RESTORED_AT_LEAST 2`), and the square's children play there from 0.6 too.
- The mentor reads the gift too: Holding until `mentor_gift` heard, then Stasis; the gift's beat stands the empty hand in.
- Tests: `opening_test` (`test_owning_the_items_early_changes_nothing_in_the_house`, `test_the_guitar_comes_back_whatever_was_skipped`, `test_the_bench_is_empty_at_six_tenths`, `test_the_east_gate_opens_on_the_elders_story`), `reach_kits_test` (every kit passes the gate; a dialogue need packs its id). Playtests g and h.

## Prevention

`opening_test` walks only the scripted order. Add a case per out-of-order save (Memorina before the errand, after the errand, at 0.6 with no song): for every `FactStaging`, a child that some talk or beat refers to (the guitar, the children) is shown somewhere. When a talk is gated `unless X`, check every staging that reads that talk's facts for the `X` case.
