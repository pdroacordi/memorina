---
id: playtests/2026-10-16-story16-opening
type: playtest
title: STORY-16 - the opening re-staged as scenes on draft 3, watched and skipped, and the mentor
status: active
build: STORY-16 uncommitted
area_tested: "village_house (the morning, the errand, the return, the song, to bed), village_bakery, village_elder (the story, the return), lighthouse_interior (the mentor)"
tags: [story-16, cutscene, opening, dialogue, draft-3, skip]
related: [systems/story, systems/cutscenes, systems/notices, playtests/2026-10-16-story15-cutscenes]
created: 2026-10-16
updated: 2026-10-16
ratings: { fun: 3, fluidity: 4, aesthetics: 3 }
screenshots:
  - screenshots/2026-10-16-story16-opening/a00_black.png
  - screenshots/2026-10-16-story16-opening/a01_window_light.png
  - screenshots/2026-10-16-story16-opening/a02_shawl.png
  - screenshots/2026-10-16-story16-opening/a03_guitar_drawings.png
  - screenshots/2026-10-16-story16-opening/a04_girl_asleep.png
  - screenshots/2026-10-16-story16-opening/a05_ivo_on_his_bed.png
  - screenshots/2026-10-16-story16-opening/a06a_rising_seated.png
  - screenshots/2026-10-16-story16-opening/a06_he_stands.png
  - screenshots/2026-10-16-story16-opening/a06b_risen.png
  - screenshots/2026-10-16-story16-opening/a07_control.png
  - screenshots/2026-10-16-story16-opening/b01_round_loaf_day.png
  - screenshots/2026-10-16-story16-opening/b02_turns_over.png
  - screenshots/2026-10-16-story16-opening/b03_looks_at_the_shawl.png
  - screenshots/2026-10-16-story16-opening/b03a_back_soon_still_facing_the_shawl.png
  - screenshots/2026-10-16-story16-opening/b04_intent.png
  - screenshots/2026-10-16-story16-opening/c00_talk_framed.png
  - screenshots/2026-10-16-story16-opening/c01_two_loaves.png
  - screenshots/2026-10-16-story16-opening/c02_quietly.png
  - screenshots/2026-10-16-story16-opening/c03_notice.png
  - screenshots/2026-10-16-story16-opening/d01_sees_bread.png
  - screenshots/2026-10-16-story16-opening/d02_reaches_up.png
  - screenshots/2026-10-16-story16-opening/d03_holds_it_out.png
  - screenshots/2026-10-16-story16-opening/d04_takes_guitar.png
  - screenshots/2026-10-16-story16-opening/d05_song_fails.png
  - screenshots/2026-10-16-story16-opening/d06_choice.png
  - screenshots/2026-10-16-story16-opening/d07_it_isnt.png
  - screenshots/2026-10-16-story16-opening/d08_to_bed_walk.png
  - screenshots/2026-10-16-story16-opening/d09_lies_down.png
  - screenshots/2026-10-16-story16-opening/d10_hold.png
  - screenshots/2026-10-16-story16-opening/d11_offscreen_voice.png
  - screenshots/2026-10-16-story16-opening/d12_looks_at_the_door.png
  - screenshots/2026-10-16-story16-opening/e00_story_framed.png
  - screenshots/2026-10-16-story16-opening/e01_elder_turns.png
  - screenshots/2026-10-16-story16-opening/e02_ivo_at_the_painting.png
  - screenshots/2026-10-16-story16-opening/e03_girl.png
  - screenshots/2026-10-16-story16-opening/e04_bolt.png
  - screenshots/2026-10-16-story16-opening/e05_intent.png
  - screenshots/2026-10-16-story16-opening/f00_long_way_framed.png
  - screenshots/2026-10-16-story16-opening/f01_keep_things.png
  - screenshots/2026-10-16-story16-opening/f02_phrase.png
  - screenshots/2026-10-16-story16-opening/f03_gift_flicker.png
  - screenshots/2026-10-16-story16-opening/f04_choice.png
  - screenshots/2026-10-16-story16-opening/f05_goes_still.png
  - screenshots/2026-10-16-story16-opening/f06_if_i_what.png
  - screenshots/2026-10-16-story16-opening/f07_hold.png
  - screenshots/2026-10-16-story16-opening/g01_elder_sees_flute.png
  - screenshots/2026-10-16-story16-opening/g02_elder_model.png
  - screenshots/2026-10-16-story16-opening/g03_daughter_sees_flute.png
  - screenshots/2026-10-16-story16-opening/g04_not_yet.png
  - screenshots/2026-10-16-story16-opening/k01_pause_skip.png
  - screenshots/2026-10-16-story16-opening/k02_after_skip.png
  - screenshots/2026-10-16-story16-opening/k03_song_skip_keeps_talk.png
  - screenshots/2026-10-16-story16-opening/k04_song_skip_song.png
---

# STORY-16: the opening re-staged, watched and skipped

Windowed runs of the real game (`tools/playtest/playtest_runner.tscn`), en, one timeline per stretch, each seeding the save at its step (`tools/playtest/scripts/story16_*.json`):

- `story16_morning` (new game, owning nothing): the opening scene, then the half-asleep talk.
- `story16_bakery`, `story16_song` (the return, the song, "[Lower the guitar]", to bed, the voice), `story16_elder` ("[Look at the painting]"), `story16_mentor` ("[Play it again]") and `story16_returns` (the elder's return; the daughter's, after "[Try again]").
- Skipped: `story16_morning_skip` and `story16_song_skip` (`"clock": "real"`).

No `debug_trials` press appeared in any run log.

## What the frames show

- **The morning** (`a00`..`a07`, about 22 s): black for 1.6 s with the room tone; the window opens with its slanted light; at zoom 3 the frame crosses the shawl, holds, then the fireplace, the guitar on its hook and the drawings, and settles on the girl asleep in her bed. Then the cut to Ivo seated on his bed's edge, zoom 2 on him and the shawl, and he stands. Control comes back with him by his bed and no intent yet.
- **Half asleep** (`b01`..`b04`): Ivo's portrait and plate on his lines; a "…" bubble over her as she trails off; he turns to the shawl before "Back soon."; "The round loaf." is told after the talk.
- **Bakery** (`c01`..`c03`): the frame closes on the pair as she holds out both loaves (zoom 2), and again as she puts the long one back. Then "Just the round one.", the loaf notice, then "Home.".
- **Home** (`d01`..`d12`):
  - as Ivo comes in, a "!" over her and the frame on the pair;
  - "You found the round one!" / "The last one.";
  - she walks to the hook, reaches up, the guitar leaves the wall, she holds it out, and Ivo steps in (walk clip);
  - "Play the morning one?…": her hands empty as he takes it;
  - the guitar; at the gap, bars, the frame on Ivo and a "…" over her;
  - the choice, the hum, "That's all I know.", "It's all right, Papa." / "It isn't.";
  - to bed at zoom 2, the hold at zoom 3;
  - the offscreen voice: plate "Elder", no portrait;
  - Ivo turns east to the door.
- **Elder** (`e01`..`e05`): the elder turns from the children to the painting after "Until he what?" and turns back once his story is done. Ivo walks to the painting for "Is that lighthouse still there?". After the girl's line, the bolt sounds and Ivo turns east. Then "The lighthouse, east.".
- **Mentor** (`f01`..`f07`): Ivo's lines; the winter pulse on the phrase; the gift's spring pulse with the hum; the flat note; the grey closing over the mentor during "Yours too…"; "If I what?"; then bars and a zoom-2 hold on the still mentor for 2.6 s. The Memorina notice waits until the scene ends.
- **Act 4** (`g01`..`g04`): a "!" over the elder, then the `elder_model` portrait lines; the girl at the guitar stops, "Almost." / "You stopped there too.", a "!" over her, "That's a strange one. Does it play anything?" / "Not yet.".
- **Skipped**:
  - The morning skip cuts to the room with Ivo standing by his bed (`k02`).
  - The return skip, pressed during the "!", lands only up to the bread talk, which still plays (`k03`).
  - A second skip during the fetch lands it, and the song talk begins with her holding the guitar out (`k04`). The skip never chose for the player.

## What screenshots cannot show

- The morning's pacing (about 22 s) and whether the 1.6 s of black with the placeholder room tone reads as morning. There is no cart.
- Ivo's walk at pace 0.4 over 12 px is a step, not a walk; the clip barely shows.

## Round 2 (after review, 2026-10-16)

The 8 timelines were re-run after the review's fixes; the frames above are this round's (the earlier ones were replaced; `story16_returns` waits longer before leaving the elder, whose talk the first round left mid-line).

- **Ivo stands up** with `stand_up` (`a06a` seated, `a06` rising, `a06b` up), no cut.
- **Every talk holds the frame at zoom 2** on the speaker and Ivo (`Dialogue.zoom`): the errand (`b01`), the bakery (`c00`), the song, the elder (`e00`), the mentor (`f00`), the returns (`g02`, `g04`). The room's clamp still leans some frames: the elder's painting is above the frame when Ivo stands under it (`e02`).
- **Faces hold**: "Back soon." is said still looking at the shawl (`b03a`); "Is that lighthouse still there?" faces the painting, the elder behind him (`e02`); Ivo faces the door after the voice (`d12`) and east after the bolt (`e04`).
- **The door**: she holds the guitar out at x 104, Ivo stands at 136; the guitar's neck still meets his hand, which reads as handing it over (`d03`).
- **The reach**: the guitar now leaves the hook as her hand comes down from it (0.5 s into `reach_up`, frame 4), not before (`d02`).
- **The sword's line** is started by the take (`player_pickup_test`); not replayed here.

## What reads badly

1. ~~Ivo stands up with a cut~~: fixed in round 2 (`stand_up`).
2. ~~At zoom 1 the small beats are tiny~~: fixed in round 2 (the talks hold zoom 2).
3. **The close-ups are clamped by the room**: at zoom 3 on the girl in bed the frame stops at x 107, so Ivo, not she, is centred at the end of "to bed"; at the elder's painting the painting is above the frame.
4. **"She smiles" has no smile**: a "!" bubble stands in for it (no clip). Neither the daughter's "sorriso se desfaz" nor the elder's pointing has art: a "…" bubble and his turn carry them.
5. ~~The reach~~: fixed in round 2.
6. **Crowding at the door**: eased in round 2 (she at 104, Ivo at 136); the held-out neck still touches his hand.
7. **The elder's mid-line beats** ("He gives up; points at the painting") have no gesture of their own: he is already turned to the painting.

Ratings: fun 3 (the opening now has a shape, a morning, a failure seen on faces), fluidity 3 (the cuts above), aesthetics 3.
