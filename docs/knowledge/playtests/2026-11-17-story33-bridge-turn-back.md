---
id: playtests/2026-11-17-story33-bridge-turn-back
type: playtest
title: STORY-33 - a swordless Ivo is turned back at the Old Bridge; with the sword he walks on
status: active
build: uncommitted STORY-33 change over 19a9e2ff (threshold_bridge.room 15:26, imported 15:31; no file changed after the import)
area_tested: "story33_bridge_turn_back.json and story33_bridge_with_sword.json: threshold_fields x 6250 east into threshold_bridge (x 6400), pt_BR, elder_story heard; plus a scratch spawn inside the zone (6405, 280)."
tags: [story-33, dialogue, talkable, fact-wall, threshold, playtest]
related: [systems/dialogue, systems/rooms, bugs/a-hop-at-the-bridge-turn-back-replays-the-line, bugs/the-bridge-turn-back-faces-east-when-ivo-stops-at-the-room-edge]
created: 2026-11-17
updated: 2026-11-17
ratings: { fun: 0, fluidity: 4, aesthetics: 4 }   # second run; the first run was 3/3
screenshots:
  - screenshots/2026-11-17-story33-bridge-turn-back/turn_back_line.png
  - screenshots/2026-11-17-story33-bridge-turn-back/prompt_over_nothing.png
  - screenshots/2026-11-17-story33-bridge-turn-back/running_in_place_at_the_wall.png
  - screenshots/2026-11-17-story33-bridge-turn-back/jump_at_the_wall.png
  - screenshots/2026-11-17-story33-bridge-turn-back/hop_replays_the_line.png
  - screenshots/2026-11-17-story33-bridge-turn-back/second_approach_line_again.png
  - screenshots/2026-11-17-story33-bridge-turn-back/prompt_sliver_at_left_edge_crop.png
  - screenshots/2026-11-17-story33-bridge-turn-back/with_sword_on_the_bridge.png
  - screenshots/2026-11-17-story33-bridge-turn-back/run2_against_the_step.png
  - screenshots/2026-11-17-story33-bridge-turn-back/run2_approach_no_prompt.png
  - screenshots/2026-11-17-story33-bridge-turn-back/run2_after_hop_no_box.png
---

# STORY-33: the turn-back at the Old Bridge

## What was tested

- **Turn back** (`story33_bridge_turn_back.json`, `owned_items` []). The steps:
  - Ivo runs east from (6250, 250).
  - The line plays. A `jump` action is pressed during it, then a raw Z closes it.
  - He pushes right into the wall and jumps there.
  - He leaves west into threshold_fields and returns.
  - He hears the line again, and Z closes it.

  `log` runs every 0.05 s throughout.
- **With the sword** (`story33_bridge_with_sword.json`, `owned_items` [0, 1]): the same run east, with one jump up the bridge's first step.
- **Scratch edge case**: a spawn at (6405, 280) puts his centre at local x 5, inside the bugged band [-6, 16). Z closes the line, then he tap-jumps in place.

Timeline changes from the draft:
- The dialogue's continue is the `ContinueArea` GUI button, and an `InputEventAction` `jump` never closes it. The draft therefore left the box open from t 2.2 to the end, and every later step was swallowed. Raw `"key": "Z"` steps now close it.
- The hop at the wall reopens the talk (finding 4), so a Z now follows it before the walk west.

## Findings

1. **The line, the box and the facing work.**
   - Ivo enters the zone at x ~6390 (t 1.77). The talk opens 0.4 s later at x 6466.5, and he stops at 6467.4, 18 px short of the wall.
   - `facing=-1` in all three turn-backs. A crop shows his face profile pointing west each time.
   - The box sits at the top with Ivo's portrait and the "Ivo" plate. Ivo stands clear below the box, at the left of the frame. "Assim não." is fully typed within ~0.4 s. `turn_back_line.png`.
   - The camera is still gliding into the room when the box opens: the talk starts at t 2.17, and the glide ends at t 2.36. Harmless.
2. **The facing fix holds at the room edge.** Spawning with his centre at local x 5 (world 6405) gives `facing=-1` when the talk opens. `bugs/the-bridge-turn-back-faces-east-when-ivo-stops-at-the-room-edge` is fixed. Its INDEX line still says ACTIVE.
3. **The wall holds, with no jitter.**
   - Pushing right, he stops at x 6485.0 (the wall face is 6496, and his half-width is 11). x stays at 6485.0/6484.9 for 1.9 s.
   - A held jump against it peaks at y 144 (144 px up) and lands back at 6484.9. `jump_at_the_wall.png`.
4. **Bug: any hop inside the zone replays the line.** The zone is 64 px tall, so a jump lifts Ivo out of it, and landing re-arms the auto start. The box reopened 0.3 s after landing from the wall jump. It also reopened after a 73 px tap hop at x 6405. Each time it blocks him until Z is pressed, so a player testing the wall with jumps is stopped by a modal line on every landing. `hop_replays_the_line.png`. Filed as `bugs/a-hop-at-the-bridge-turn-back-replays-the-line` (medium).
5. **He runs in place against nothing.**
   - The unseen wall's face is at x 6496, 32 px (one cell) before the visible step face at 6528. Pushing right shows the run cycle on bare, flat snow, a body's width short of the step. `log` reads `state=run vel=(0,0)`. `running_in_place_at_the_wall.png`.
   - On the first approach the talk stops him before he touches the wall. The run-in-place only shows when the player pushes on after closing the line. That is the moment it most reads as a collision bug.
   - Suggestion: put the wall's face on the step face, or swap the run for the idle or brace pose while pushing into a `FactWall`.
6. **The empty Up prompt is odd, in two ways.**
   - During each approach, the Up glyph floats over empty air at the room's west edge for the 0.4 s `auto_delay` (t 1.80-2.10 and 9.60-9.75). It slides left with the camera glide, with no speaker under it. `prompt_over_nothing.png`. It promises something to talk to that is not there.
   - After the line closes, while Ivo idles in the zone facing west, the glyph sits at world x 6394. That is 6 px left of the clamped view (6400), so only a 2-game-px dark sliver shows at the screen's left edge. `prompt_sliver_at_left_edge_crop.png`. It was not visible while he faced east against the wall.
   - Pressing Up there would replay the line (`has_talk` holds). Consider hiding the prompt for an auto-start Talkable with no speaker.
7. **Readability of the reason.** Nothing on screen says why he cannot pass. The steps up to the bridge look open, and "Assim não." does not name the sword. It reads as intended only if the player remembers the elder's sword line (STORY-32, `elder_story` was seeded heard). This is a subjective note for the user, not a defect.
8. **The second approach plays the line again.** After he walks west to x 6283 in threshold_fields and returns, the box reopens at x 6466.5 (t 9.80), facing west. `second_approach_line_again.png`.
9. **With the sword there is no wall and no talk.** `blocked=false` throughout. He runs through x 6493 → 6512 (the wall's cell) at full speed. He stops only at the bridge's natural one-cell step (x 6517), jumps it, and climbs onto the bridge (6709, 192). `with_sword_on_the_bridge.png`.

## Cannot be judged from frames

The voice notes while the text types (DIALOGUE, `1c795574`) were not heard. Whether stopping before the wall feels like a choice Ivo makes or an input drop is a feel question for a human. The timing (0.4 s from zone entry, at full run) suggests a choice, but that is inferred.

## Ratings rationale

- Fun: n/a. This is a gate, not play.
- Fluidity 3: the first stop is clean, but the hop replay (finding 4) and the run in place (finding 5) make poking at the gate clumsy.
- Aesthetics 3: the box and the facing are good. The floating or clipped Up glyph and the invisible stop on flat snow detract.

## Second run (after the coordinator's fixes)

Build: the same uncommitted tree with three fixes. The Talkable at 0,8 is now `height_cells` 6, `up_starts` false and `reach_east` 134, and the `m` wall moved from 3,8 to 4,7. The project was re-imported at 15:45, and no file changed after that. The timeline now also taps Up while Ivo idles in the zone, at t 3.75 and 6.6.

The box opened twice, both times on purpose: on the first approach (t 2.21) and on the return (t 9.75). No other press reopened it.

- **Finding 4 (hop replay): fixed.**
  - A held jump at the step (t 4.8, peak y 144) lands at t 6.05 with the box still closed.
  - A tap hop at t 7.1 does the same. He lands at t 8.0 at x 6411, still inside the zone, and the box stays closed.
  - `run2_after_hop_no_box.png`.
- **Finding 5 (run in place against air): fixed.**
  - Pushing right, he now stops at x 6517.0, against the rock step's face (x 6528), not in the air before it. `run2_against_the_step.png`.
  - The held jump goes straight up at x 6516.9 and comes back down there, so he cannot get onto the step or over the wall.
  - Stopped at a visible step, the running pose reads as a step too high to climb, not as a collision bug.
- **Finding 6 (Up prompt): fixed.**
  - No Up glyph appears during either approach (t 1.9-2.1 and 9.6-9.7). `run2_approach_no_prompt.png`.
  - The dark sliver at the left edge after the box closes is gone. A pixel check of window columns 0-7, rows 330-400 finds 112 dark pixels in run 1 and 0 in run 2.
  - Up pressed in the zone at t 3.75 and 6.6 leaves `blocked=false`, so the line is not replayed.
- **Unchanged:**
  - The first approach still stops at x 6467.4 facing west.
  - The line repeats after he leaves west (to x ~6283) and returns: the box opens at x 6467.0 at t 9.75, facing west.
- **With the sword:** no talk, no wall. He reaches the step at 6517 and climbs it with the t 2.7 jump. He is on the bridge at (6709, 192) by t 3.9, the same as run 1.
- **Finding 7 (the reason is not on screen):** not addressed. It is the user's call.

Ratings for the second run: fluidity 4, aesthetics 4. Poking at the gate is now clean. The remaining question is whether "Assim não." alone says enough.
