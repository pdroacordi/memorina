---
id: playtests/2026-10-15-story03-opening
type: playtest
title: STORY-03 - the opening (the errand, the song by either gesture, the elder's story), the mentor's gift, the return and the visits at 0.6
status: active
build: 4d56cca (STORY-03 phase A and B uncommitted)
area_tested: "village_house, village_bakery, village_elder, village_square, lighthouse_interior: Acts 1, 3 and 4 of docs/design/05_roteiro.md"
tags: [story-03, opening, dialogue, beat, guitar, mentor, staging]
related: [systems/story, systems/dialogue, architecture/the-opening-is-staged-by-save-facts]
created: 2026-10-15
updated: 2026-10-15
ratings: { fun: 3, fluidity: 4, aesthetics: 3 }
screenshots:
  - screenshots/2026-10-15-story03-opening/a_00_waking.png
  - screenshots/2026-10-15-story03-opening/a_01_bread.png
  - screenshots/2026-10-15-story03-opening/a_04_two_loaves.png
  - screenshots/2026-10-15-story03-opening/a_05_one_loaf.png
  - screenshots/2026-10-15-story03-opening/a_06_morning_one.png
  - screenshots/2026-10-15-story03-opening/a_08_five_played.png
  - screenshots/2026-10-15-story03-opening/a_09_try_again_or_lower.png
  - screenshots/2026-10-15-story03-opening/a_10_one_note_earlier.png
  - screenshots/2026-10-15-story03-opening/a_12_turned_to_the_wall.png
  - screenshots/2026-10-15-story03-opening/b_03_lower_focused.png
  - screenshots/2026-10-15-story03-opening/b_04_lowered_hum.png
  - screenshots/2026-10-15-story03-opening/b_07_turned.png
  - screenshots/2026-10-15-story03-opening/c_00_children_on_the_bench.png
  - screenshots/2026-10-15-story03-opening/c_03_a_good_end.png
  - screenshots/2026-10-15-story03-opening/c_05_turned_to_the_painting.png
  - screenshots/2026-10-15-story03-opening/c_06_east_behind_him.png
  - screenshots/2026-10-15-story03-opening/c_07_children_gone.png
  - screenshots/2026-10-15-story03-opening/c_08_children_in_the_square.png
  - screenshots/2026-10-15-story03-opening/d_00_mentor_holding.png
  - screenshots/2026-10-15-story03-opening/d_02_phrase_pulse.png
  - screenshots/2026-10-15-story03-opening/d_04_flicker.png
  - screenshots/2026-10-15-story03-opening/d_06_play_again_or_lower.png
  - screenshots/2026-10-15-story03-opening/d_08_yours_too.png
  - screenshots/2026-10-15-story03-opening/d_10_stasis.png
  - screenshots/2026-10-15-story03-opening/d_11_up_on_him.png
  - screenshots/2026-10-15-story03-opening/e_01_she_plays.png
  - screenshots/2026-10-15-story03-opening/e_03_guitar_back_on_the_wall.png
  - screenshots/2026-10-15-story03-opening/e_04_my_father_carved_that.png
  - screenshots/2026-10-15-story03-opening/f_00_three_houses.png
  - screenshots/2026-10-15-story03-opening/f_01_her_eyes.png
  - screenshots/2026-10-15-story03-opening/f_02_empty_bench.png
  - screenshots/2026-10-15-story03-opening/f_03_and_the_keeper.png
  - screenshots/2026-10-15-story03-opening/g_01_east_gate_shut.png
  - screenshots/2026-10-15-story03-opening/g_02_east_gate_open.png
  - screenshots/2026-10-15-story03-opening/h_00_debug_waking.png
---

# STORY-03: the opening and the mentor

Six timelines in `tools/playtest/scripts/` (locale en, keyboard: Up, Z, arrows). They seed the save with the runner's `owned_items`, `dialogues_heard`, `responses` and `restored_guardians`, and move rooms with the new `"teleport"` step. Prefixes: a `opening_errand`, b `opening_lower`, c `opening_elder`, d `mentor_gift`, e `village_return`, f `village_at_06`, g `east_gate_shut` / `east_gate_open`, h `opening_debug`. Revised after the phase B review (2026-10-15): the elder's talk starts east of him, the stages read talks, the east gate; c, e, f, g and h were rerun, and a, b and d reran unchanged.

## What the runs showed

- **a, 1a-1d, Try again.**
  - A new game without items: the daughter asleep in her bed (`a_00`); Up on her: "Bread. The round one." (`a_01`).
  - The bakery: the baker takes two loaves, then puts one back (`a_04`, `a_05`).
  - Home: she holds the guitar out at the door (auto start) (`a_06`). The guitar beat shows the phrase up to its gap, Ivo plays the five notes, and three dead presses end it (`a_08`).
  - The gesture box offers "[Try again]" and "[Lower the guitar]" with no question (`a_09`). Try again stops one note earlier, and two seconds of silence end it (`a_10`).
  - "…", then she cross-fades back to her bed, turned to the wall, and the guitar is on the wall again (`a_12`). Up on her: "…".
- **b, Lower.** Ivo sets the guitar down on the floor (a stand-in) and she hums her four notes (`b_04`); "…"; she is in bed, turned, the guitar back on the wall (`b_07`).
- **c, 1e.**
  - The two children on the bench by the door (`c_00`). Ivo walks past the elder, who tells the story to the children with his back to Ivo, and the talk starts between the elder and the painting. The long first line fits two rows. The question with "[Wait for him]" and "[Look at the painting]" (`c_03`, Ivo facing the elder, west).
  - "[Look at the painting]" turns Ivo east to the painting (`c_05`), and he keeps facing it while the elder says "East. Past the fields…" behind him (`c_06`).
  - The children fade out (`c_07`) and play in the square (`c_08`).
- **d, Act 3.**
  - The mentor holds the Memorina (`d_00`). The phrase G E D C sounds under a winter pulse around the pair (`d_02`).
  - The cue-only grant: his hand is empty, and the flicker is a spring pulse with the hummed opening (`d_04`).
  - The gesture box (`d_06`); "[Play it again]" sounds the flat note. "Yours too. Maybe. If you—" (`d_08`).
  - The stasis cross-fades in over 1.5 s and the notebook quill appears for the mentor's Memories entry (`d_10`). Up: "…" with his stasis portrait (`d_11`).
- **e, Act 4, Try again.** She is at the guitar; the beat plays her four notes and stops (`e_01`); "That's a strange one."; she stands by the drawings and the guitar is back on the wall (`e_03`). The elder's return line shows the lighthouse model's base as the portrait (`e_04`).
- **f, at 0.6, Lower.** Three houses on the wall and the daughter by them (`f_00`); "…It's okay. I'll draw them grey for now." (`f_01`, two rows); the elder's empty bench (`f_02`) and his unfinished line (`f_03`).
- **g, the east gate.** Before the elder's story Ivo walks into the chained gate at village_gate_east's east end and stops (`g_01`). With the story heard it is gone and he walks on to the fields (`g_02`).
- **h, debug.** A plain debug new game owns the sword and the Memorina from the first frame, and the daughter is asleep as in a release (`h_00`): the stages read talks, not items.

## Fixed during the runs

- **The door's Up prompt showed over the talk** at the house door, where the daughter's talk starts. `Door` now hides its prompt while Ivo is talking, refreshing each physics frame while he is in reach. Doors are refused during a talk anyway.
- **Ivo covered the daughter when he talked to her by the drawings** (her standing still was at x 112, between the bed and the door). Her standing still is now by the wall at x 44, facing east, and the bed's talk reach is three cells wide. An Up at x 136 had taken the door instead of the talk.
- **The return timeline teleported mid-talk** (one Z completed the typing and the next was missing). The timeline was fixed; the game was right.

## Fixed after the phase B review (2026-10-15)

- `bugs/the-memorina-before-the-song-hides-the-guitar-and-keeps-the-elders-audience`: the east gate makes the order certain, the house reads `mentor_gift` heard instead of owning the Memorina, the guitar's "held out" stage ends at the gift, and the bench empties at 0.6 too.
- `bugs/a-late-held-return-shows-the-daughter-away-from-the-guitar-she-plays`: AtGuitar (gift, Try again, return unheard) ranks first (`opening_test`).
- `bugs/look-at-the-painting-turns-ivo-the-way-he-already-faces`: the talk zone moved between the elder and the painting (`c_03`, `c_05`, `c_06`).

## What screenshots cannot show

- Sound: the guitar strings, the muted thump, the hums and the flat note are synthesized placeholders. The mix and timing want an ear.
- The cross-fades read in sequence, not in stills; 0.5 s (and 1.5 s for the stasis) looked right in the frames taken mid-fade.

## Observations for the user

- In the elder's house Ivo walks past the bench and the children to reach the elder; the elder speaks with his back to Ivo, facing the children, as the script has him mid-story (`c_01`).
- The baker has no portrait (none drawn); her box shows only her plate.
- The gesture choices' Portuguese is not in the script; see the report.
