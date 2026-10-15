---
id: playtests/2026-10-15-story14-opening-fixes
type: playtest
title: STORY-14 - a new game owns nothing, the village interiors are calm, the guitar sheet at the Memorina's size, talks centred on the speaker
status: active
build: STORY-14 uncommitted
area_tested: "village_house, village_square, village_bakery, village_tavern, village_lane_west, village_elder, lighthouse_interior, winter_trial"
tags: [story-14, new-game, calm, phrase-sheet, talkable, opening]
related: [systems/story, systems/dialogue, systems/life-benches-death, systems/rooms, playtests/2026-10-15-story09-village-voices]
created: 2026-10-15
updated: 2026-10-15
ratings: { fun: 3, fluidity: 4, aesthetics: 4 }
screenshots:
  - screenshots/2026-10-15-story14-opening-fixes/a_00_new_game_in_the_house.png
  - screenshots/2026-10-15-story14-opening-fixes/a_01_attack_press.png
  - screenshots/2026-10-15-story14-opening-fixes/a_02_draw_press.png
  - screenshots/2026-10-15-story14-opening-fixes/b_01_attack_in_house_2.png
  - screenshots/2026-10-15-story14-opening-fixes/b_03_attack_in_square_2.png
  - screenshots/2026-10-15-story14-opening-fixes/c_guitar_sheet_beside_memorina_sheet.png
  - screenshots/2026-10-15-story14-opening-fixes/d_water_carrier_from_the_front.png
  - screenshots/2026-10-15-story14-opening-fixes/d_boy_from_the_east.png
  - screenshots/2026-10-15-story14-opening-fixes/d_baker.png
  - screenshots/2026-10-15-story14-opening-fixes/d_daughter_by_the_door.png
  - screenshots/2026-10-15-story14-opening-fixes/d_elder.png
  - screenshots/2026-10-15-story14-opening-fixes/d_mentor.png
  - screenshots/2026-10-15-story14-opening-fixes/e_home_walked_in.png
  - screenshots/2026-10-15-story14-opening-fixes/e_elder_running_in.png
  - screenshots/2026-10-15-story14-opening-fixes/f_stopped_short.png
  - screenshots/2026-10-15-story14-opening-fixes/f_a_step_further.png
---

# STORY-14: three fixes from the user's playtest

Each runs below exited 0, after a reimport.

## A new game owns nothing (point 13a)

"eu tenho a memorina desde o inicio do jogo e também a espada. Isso não está certo." (user, 2026-10-15)

`story14_new_game` starts as a new game does (`owned_items` []), in Ivo's house:
- An attack press does nothing (`a_01`, `attack_no_sword` logs `attack=false`).
- A draw press draws nothing (`a_02`, `drawn=false`).

The new game itself is proven by `boot_policy_test` and `opening_test`: `SaveSystem.begin` gives no item. The runner applies its timeline's items after that, so a run cannot show the editor's start any closer than this.

## The house is calm (point 13b)

"E eu consigo utilizar a espada dentro de casa na minha filha."

`story14_calm_house` (sword and Memorina owned):
- An attack press in the house gives no swing over four frames (`b_01_attack_in_house_*`, `attack=false`).
- In the square the same press swings (`b_03_attack_in_square_*`, `attack_idle_`, `attack=true`).

## The guitar sheet (point 10)

"os botoes do hud do violão estão muito pequenos, diferente do hud da memorina"

`c_guitar_sheet_beside_memorina_sheet.png`: the guitar's sheet during the morning song (left) beside the Memorina's during a Freeze performance (right), at the same scale. The glyphs are the same size, and the columns are the same distance apart (22 px). The guitar's frame is wider: the staff is tiled between the clef and the right corner, and the lines stay continuous.

## Talks centred on the speaker (point 3)

"Eu preciso chegar por trás da aguadeira pra conseguir disparar o dialogo com ela. E bem longe"

- **Water carrier:** she now faces east, away from the well's shaft. Ivo stands in front of her, close, on the well's lip, with the prompt over her head (`d_water_carrier_from_the_front`, `d_water_carrier_line`).
- **Boy:** the prompt is over the boy. From the east, at x 620, only the talk's prompt shows; the bell tower door 24 px further east still wins its own side (`d_boy_from_the_east`).
- **Baker:** the prompt is over the baker (`d_baker`).
- **Daughter:**
  - the bed talk works from beside the bed (`d_daughter_bed`);
  - the talk by the door: see the review fix below.
- **Elder:** "[Look at the painting]" still turns him east (`d_elder_painting`).
- **Mentor:** unchanged; both talks were already on him (`d_mentor`).

## Review fix: arriving home and running past (bugs/the-daughters-song-talk-needs-ivo-inside-her-and-a-run-past-never-starts-it)

- **The girl holding the guitar out** now stands at x 72, by her bed, and her song talk reaches 24 to 104 (80 px).
  - `opening_errand` brings Ivo home at the door (x 144) and walks him west for 0.3 s. He stops beside her at x 91, the prompt over her head (`e_home_walked_in`), and the song starts (`d_daughter_by_the_door`, then the guitar beat, `e_guitar_beat`).
  - A 0.2 s walk stops him at x 110, where neither the song nor the prompt starts. Prompts now read the same door sensor as Up and auto starts (`Player.reaches`), so they agree. The first try, before that change, showed the prompt there with nothing starting. `story14_walk_home` shows it: x 110 with no prompt and no song even after the delay (`f_stopped_short`, `f_still_short_after_delay`); one more step to x 109.5 and the song starts at once (`f_a_step_further`). Its delay had run since his body came into the zone.
- **The elder:** `opening_elder` now runs Ivo through at full speed for 1.6 s. The talk starts while he runs (`e_elder_running_in`: the prompt over the elder as Ivo passes him), and he stops at x 344, inside the zone, between the elder and the painting (`d_elder`).
- **The return:** `village_return` reaches the daughter at the guitar as before (`e_return_at_the_guitar`).
- **The calm house:** re-run after the gate moved to `Player.calm`, set by Game; the house still refuses the swing and the square swings.

## What screenshots cannot show

- How far the reach feels. It is 48 px (a cell and a half) each side of the speaker; the frames only show the prompt appearing over the speaker.
- `opening_lower` stands Ivo at x 100 for the morning talk. The talk no longer reaches the door.
- The bench's Down prompt still reads Ivo's body, not the seat sensor. It is the one prompt left with the old split.
