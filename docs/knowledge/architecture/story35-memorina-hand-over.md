---
id: architecture/story35-memorina-hand-over
type: architecture
title: STORY-35 plan - the Memorina's hand-over becomes a skippable actor-free cutscene; the flute changes sprites on one frame where the keeper's strip and Ivo's new pose draw it on the same world pixels
status: active
tags: [story-35, story, mentor, lighthouse, cutscene, staging, staged-strip, pose, memorina, hand-over, item, animation, pixellab, plan]
related: [architecture/cutscenes-are-data-played-between-two-rest-states, architecture/story34-mentor-at-the-lantern, architecture/story37-the-mentor-moves-while-he-talks, architecture/story38-the-keeper-wakes, systems/cutscenes, systems/story, systems/dialogue, systems/animation, systems/art-pipeline, systems/notices, systems/music, systems/greyhush, bugs/the-mentors-new-strips-redraw-the-figure-between-frame-0-and-frame-1, gotchas/a-replaced-sheet-plays-the-old-import-until-reimported, gotchas/animationtree-reset-track-overwrites-script-writes, playtests/2026-11-18-story37-the-mentor-moves]
created: 2026-11-22
updated: 2026-11-23
source_files:
  - resources/dialogue/story/mentor.tres
  - scenes/world/rooms/frost_edge/contents/lighthouse_top_contents.tscn
  - scenes/world/dialogue/dialogue_beat.gd
  - scenes/world/dialogue/dialogue_director.gd
  - scenes/characters/ivo/player_animation_resolver.gd
  - resources/cutscene/cutscene_catalog.tres
---

# STORY-35 plan: the Memorina's hand-over as an animated scene

**Status: BUILT** (2026-11-23). See "As built" at the end; the contracts are in `tools/art/prompts/story_*.md`, the systems entries `systems/cutscenes` and `systems/story` ("The hand-over"), `systems/animation`.

"não há animação da entrega da memorina, nem da pra entender oq acontece ali. Deveria ter. Algo mais como uma cutscene da entrega, mais animado." (user, 2026-11-16). Roadmap: a cutscene (`systems/cutscenes`) with hand-over clips; art contract first. Design 05 Act 3: "Muitas mãos. Nenhuma ~guardou~. (estende a flauta)" · **[Presente]** Ivo pega a Memorina · **[Lampejo]** "Quando a mão dele fecha na flauta, as primeiras notas da música da manhã soam numa voz de mulher, em cor, por um segundo." · "Essa é… essa é a música dela."

## Context: what plays today

- `mentor.tres` (`mentor_gift`, zoom 1.5, `frame_lift` 64): line `DLG_MENTOR_GIFT_02` with gesture `mentor_hold_out` (`LineGesture`, `holds`: the keeper's arm goes out and stays, `hold_out.png` frame 3), then the cue-only `line_6`, cue `mentor_gift`, `grants` ITEM 1 (the Memorina). `DialogueDirector._play` applies a cue-only line's grant as its beat starts.
- `Beats/MentorGift` in `lighthouse_top_contents.tscn` is a `StagedBeat` (2.4 s, pose MEMORINA, stand-in `Props/Mentor` → `EmptyHand`, stream `wife_hum_opening.wav`, a spring `root` pulse at `Beats/Pair`).
- What the player sees in one frame: the box closes; the keeper's held-out arm **snaps** back to his chest with no flute (the STORY-37 playtest measured it at 24.03 s: "the arm snaps from held out back up to his chest"); Ivo plays `memorina_draw` (his own lower clip backward: from his belt to his lips) and loops `memorina_idle` (the flute at his lips, a playing pose); the hum and the spring pulse start at once and the disc floods the frame within ~0.2 s.
- Why it does not read: (1) the flute never travels: it leaves one sprite and appears in the other at another place in the same frame; (2) Ivo's clip is the draw from his belt, so he seems to take out a flute he already had; (3) he then stands in a playing pose, so the hum reads as him playing, and "[Tocar de novo]" right after makes that worse; (4) offer, take, colour and voice are one instant, with no hold before or after; (5) at zoom 1.5 the flute is a 14x16 px object, half covered by the pulse; (6) the notice is withheld until the talk ends (`NoticeHold`), so nothing names the item during it.
- A measurement that shapes the scene: in `hold_out.png` frame 3 the flute sits about 80..90 px over the keeper's feet (eyeballed at 1:1; the builder measures it by script before the contracts go to the user), i.e. about (755..770, 581..595) in the world, **20-30 px above Ivo's head** (he is 58 px tall, standing at `ivo_near` (776, 672)). Ivo cannot take it where it is held.

## Options considered

1. **The keeper: a `StoryActor` or stand-in strips.**
   - (a) A mentor `StoryActor` (design 06 Pilar 1 lists "o mentor" among the actors). It never walks here; it would need a resolver, locomotion stats, and a clip for every `mentor_staging` child (`cutscene_rooms_test`), 13 children today, several pixel-locked by `mentor_moves_test` and `mentor_wakes_test`.
   - (b) **New `StagedStrip` children of `Props/Mentor`, stood in by `CutsceneStage`**, as `mentor_turns` and `mentor_wakes` already do. Feet fixed at (720, 672), the same offset (-61, -126) and `flip_h`.
   - **Chosen: (b).** It is the lantern's established mechanism, and a figure that does not move from his spot gains nothing from a body. Surfaced, not resolved by me: design 06 says the mentor becomes an actor; Q7 below asks the user.
2. **Ivo's motion: a gesture or a pose.** Cutscene gestures are actors' only; Ivo's clips come from `DialogueBeat.Pose` through `CutscenePose`, and a pose set by a scene inside a talk holds after it (`Player.end_scene` keeps `_pose` while `_in_talk`). **Chosen: two appended poses, `RECEIVE` and `MEMORINA_HELD`.**
3. **The flicker's colour.** (a) **`CutsceneBloom` on a new `MemoryBloom` `gift_bloom` with the spring palette's tint** (existing vocabulary, flashbacks 1-5); (b) a new `CutscenePulse` step around `PulseEmitter`, so the colour is the same `root` pulse as before and rhymes with the phrase's winter pulse. **Chosen: (a)**, Q3 asks.
4. **Who closes the 20-30 px gap.** (a) **The keeper lowers the flute to Ivo** (a new `give` strip, the tall one bending to the small one); (b) Ivo reaches overhead at full stretch (no keeper clip; reads as straining or snatching). **Chosen: (a)**, Q1 asks.
5. **Ivo after the take.** (a) **The take ends exactly on `ivo_memorina_lower.png` frame 1** (the flute just under his chin) and a breathing hold loops from it; then "[Tocar de novo]" lifts it with that sheet's frames 1→0 and "[Baixar a flauta]" puts it away with frames 1→3, so no raise or lower art is new; (b) a new "looking down at it with both hands" still, which would need two more clips (raise and lower from it). **Chosen: (a)**, Q4 asks.

## Decision

`Beats/MentorGift` becomes a `CutsceneBeat` (cue `mentor_gift`, hold STILL, pose NONE) playing the new scene **`memorina_hand_over`** (`resources/cutscene/story/memorina_hand_over.tres`, skippable, actor-free, wordless). `mentor.tres` is unchanged: the grant stays on `line_6` and still lands as the beat starts (no grant step in a scene: items come from talks).

### Shot list (scaled seconds; about 5.4 s, then the director's 0.4 s bar close and 0.8 s ease back)

| t | Step(s) | What is seen and heard |
|---|---|---|
| 0.0 | Together: `CutsceneBars` 0.6 · `CutsceneCamera [ivo, mentor_home]` offset (0, -60), zoom 2, 1.0 s · `CutsceneFace ivo` toward `mentor_home` | the box is gone; the frame closes on the pair from the talk's 1.5; between the bars (144 game px at zoom 2) it shows y 540..684: the keeper's mask to the floor, the held-out flute in the middle (the `mentor_silence` framing) |
| 1.0 | `CutsceneWait` 0.4 | the offer, held: the flute out, Ivo still, the lantern silent (frost_edge has no region music) |
| 1.4 | Together: `CutsceneStage mentor_staging` → `Giving` · `CutscenePose RECEIVE` · `CutsceneWait` 0.7 | the keeper's arm lowers the flute about 30 px toward Ivo (0.55 s) while Ivo lifts his hand to it (0.625 s); both stop with his open hand under the flute |
| 2.1 | Together: `CutsceneStage` → `LettingGo`, then 1.1 s, then → `EmptyHand` · `CutscenePose MEMORINA_HELD` · `CutsceneSound wife_hum_opening.wav` · `CutsceneBloom gift_bloom` radius 112, strength 1, ring 0.5, 0.4 s, then 1.0 s, then radius 0 / strength 0 over 0.8 s · `CutsceneCamera ivo` offset (0, -36), zoom 3, 1.6 s | the grip: his fingers close on it and the woman's voice sings the first notes; colour opens from the flute over both of them and the frame pushes in on Ivo's hands; the keeper's fingers open empty, hold open 0.5 s and draw back to his chest (the `EmptyHand` breath resumes); Ivo brings the flute under his chin; the colour closes |
| 4.3 | `CutsceneWait` 0.8 (or the hum's remaining length, if longer) | Ivo holds the flute in the grey, breathing; the scene ends; the talk resumes on "Essa é… essa é a música dela." with the flute still at his chin |

- **The hand-off frame.** At 2.1 both `LettingGo` frame 0 and Ivo's `memorina_take` frame 0 draw the flute on the **same world pixels** (`Giving`'s last frame's flute; Ivo draws over the props, so his closing fingers may cover part of it). The staging cut and the resolver's clip change may land one rendered frame apart; with identical pixels a frame with both shows one flute, and neither frame shows none. That is the only new pattern here, and the seam test below pins it.
- **The marks:** Ivo stays at `ivo_near` (776, 672) (`mentor_approach` put him there and the talk blocks him). With the flute lowered to about (760, 618), 54 px over the floor and 16 px ahead of him, his raised forward hand reaches it. If the builder's measurement says otherwise, a `CutsceneWalk ivo` to a new mark `ivo_take` at pace 0.3 opens the 1.4 row (Q5).
- **`gift_bloom`:** a `MemoryBloom` (bloom_id `gift_bloom`, spring palette tint, feather 48) at the contents root, positioned on that flute point; `CutsceneBloom.at` empty centres on itself.

### Rest states and the contract (`systems/cutscenes`, `systems/story`)

- `mentor_staging` gains a stage **EmptyHand on `SCENE_SEEN memorina_hand_over`** (fade 0), between Stasis (`mentor_gift` heard) and Holding (`SCENE_SEEN mentor_turns`). The scene's end writes SCENE_SEEN before the stagings uncover in the same frame, so the stand-in `EmptyHand` and the picked stage `EmptyHand` are one picture: no pop. `FactStaging` stays the only writer of its children; the scene only stands children in.
- **Skip** (pause menu, while no talk step runs, which is always here): lands `EmptyHand`, pose `MEMORINA_HELD`, the bloom hidden by `restore`, the hum never played (`CutsceneSound` contract), SCENE_SEEN written; it chooses nothing, the choice `mentor_flicker` comes after in the talk. Known limit: after a skip the resolver plays `memorina_take` from its first frame, so the flute is seen coming down from the raised hand for 0.75 s.
- **Drop** (`interrupt` on hurt or a room change; neither can happen in the lantern while the talk blocks Ivo): the same restore unrecorded; `HoldingOut` (the held gesture's stand-in) shows again. The grant has landed, as today.
- **Death or quit before a bench:** `SCENE_SEEN memorina_hand_over` is live data and is forgotten with `mentor_gift` heard and the item, so the keeper is back at the lamp and the whole talk, scene included, replays. Old saves that heard `mentor_gift` show Stasis (higher priority); nothing migrates.
- **StoryActor rules:** no actor enters. **`PlayerInput.blocked`:** untouched; `_refresh_block()` keeps it blocked (talk, then scene). **Director:** pausable, scaled, no `WorldFreeze` writer, no input reader. **Music:** nothing asked of `Music`; the region is silent by decision ("Silêncio total até a batalha final", user, 2026-11-03) and the hum is a scene voice on `Sfx`, as the StagedBeat's stream was. **Notices:** unchanged; "Memorina" shows after the talk.

### Ivo (`systems/animation`)

- `DialogueBeat.Pose` appends `RECEIVE` (8) and `MEMORINA_HELD` (9). `PlayerAnimationResolver`: `RECEIVE` → `memorina_reach` (one-shot, held on its last frame); `MEMORINA_HELD` → `driver.sequence(memorina_take, memorina_hold)`; `MEMORINA` while the current clip is `memorina_take`/`memorina_hold` (or `memorina_lift` is held) → `driver.sequence(memorina_lift, memorina_idle)` instead of the belt draw; with no pose, the same condition → `memorina_put_away` before the existing `memorina_lower` rule. `memorina_lift` keys `ivo_memorina_lower.png` frames 1, 0 at 12 fps; `memorina_put_away` frames 1, 2, 3 at 12 fps: no new art. Every new clip is added to Ivo's AnimationPlayer/AnimationTree (STORY-07 found actor clips missing from a tree).
- The component stays sheathed: a pose draws the flute without drawing the Memorina (`is_memorina_drawn()` false), as MEMORINA does.

## Art: new clips (contracts drafted below, awaiting approval)

| Contract id | Target | Frames | Size | Plays |
|---|---|---|---|---|
| `story_mentor_give` | `assets/sprites/world/story/mentor/give.png` | 4 (0 = `hold_out.png` frame 3) | 128x128, feet row 125, west-facing file, offset (-61, -126), `flip_h` | `Giving`: intro 0.1 / 0.15 / 0.15 / held |
| `story_mentor_let_go` | `assets/sprites/world/story/mentor/let_go.png` | 6 (0 = `give` 3, 5 = `empty_hand_breathe` frame 0) | as above | `LettingGo`: 0.1 / 0.5 / 0.15 / 0.15 / 0.15 / held |
| `story_ivo_memorina_reach` | `assets/sprites/characters/ivo/ivo_memorina_reach.png` | 5 (0 = `ivo_idle` frame 0) | 128x128, floor row 96, east-facing, body on column 63.5 | `memorina_reach`, 8 fps once, held |
| `story_ivo_memorina_take` | `assets/sprites/characters/ivo/ivo_memorina_take.png` | 6 (0 = reach 4 with the flute; 5 = `ivo_memorina_lower.png` frame 1) | as above | `memorina_take`, 8 fps once |
| `story_ivo_memorina_hold` | `assets/sprites/characters/ivo/ivo_memorina_hold.png` | 4 (0 = `ivo_memorina_lower.png` frame 1), played 0 1 2 3 2 1 | as above | `memorina_hold`, loop, 1.75 s a breath (the keeper's pace) |

Contract drafts, to become `tools/art/prompts/<id>.md` once approved. They are not on disk yet: `art_prompt_test.test_every_target_exists_at_its_contract_size` fails while a contract's target is missing, so each lands together with its placeholder from `tools/art/make_placeholders.gd`. The point coordinates below are eyeballed and must be measured by script first.

```
---
id: story_mentor_give
command: animate3
target: res://assets/sprites/world/story/mentor/give.png
size: 128x128
frames: 4
view: side
direction: west
reference: res://tools/art/sources/story/mentor_hold_out_f3_2x.png
action: a tall ancient guardian of wood and frost, its arm held out with a small pan flute on its open hand, slowly lowers the arm and bows its pale mask a little, bringing the flute down to the height of a small man's raised hand in front of it; it stays in place
keep: 0-3
generate: 6
source: pixellab
---
The keeper lowers the flute to Ivo (STORY-35, `docs/knowledge/architecture/story35-memorina-hand-over.md`; design 05 Act 3 "(estende a flauta)", **[Presente]**). Draft, awaiting approval. Stood in by `memorina_hand_over` as `Props/Mentor/Giving` (intro `give`, 0.1 / 0.15 / 0.15 s, held on 3). Measured: from `hold_out.png` frame 3 (flute about 80..90 px over his feet, file px about (16..31, 34..48)) to the flute's centre at file px about (26, 72), i.e. world (760, 618), 54 px over the floor and 16 px west of Ivo's feet at `ivo_near` (776, 672); the arm moves about 30 px down, the mask bows, the feet and mantle hem stay. Frame 0 is `hold_out.png` frame 3 exactly; the flute stays drawn in every frame. Canvas, feet row 125, offset (-61, -126) with `flip_h`, as `hold_out.png` (world x = 786 - file column, y = 546 + file row). Reference: `hold_out.png` frame 3 padded by `tools/art/pad_reference.py`; our own art only (pack licences forbid AI training). Cut and lock as `story_mentor_hold_out` (`cut_inhabitant.py ... --floor=125 --centre=60-124`, then `lock_to_still.py` against that frame, `--mirror`).
Negative: outlines, black contour, front view, glow, text, ground, scenery, throwing, walking
```

```
---
id: story_mentor_let_go
command: animate3
target: res://assets/sprites/world/story/mentor/let_go.png
size: 128x128
frames: 6
view: side
direction: west
reference: res://tools/art/sources/story/mentor_give_f3_empty_2x.png
action: a tall ancient guardian of wood and frost, its arm held low and forward with an empty open hand, slowly opens its fingers, holds them open a moment, then draws the hand back up to rest against its chest; its mask follows the hand; it stays in place
keep: 0-3
generate: 6
source: pixellab
---
The keeper lets go (STORY-35, plan as above). Draft, awaiting approval. Stood in as `Props/Mentor/LettingGo` (intro `let_go`, 0.1 / 0.5 / 0.15 / 0.15 / 0.15 s, held on 5), then `EmptyHand` is stood in on the identical picture. Composed by `tools/art/compose_strip.py`: frame 0 = `give.png` frame 3 exactly (the flute on the hand; drawn on the same world pixels as `ivo_memorina_take.png` frame 0's flute, so the hand-off frame shows one flute whichever sprite changes first); frame 1 = the same arm, flute removed by hand, fingers open (the reference); frames 2-4 = the generation's withdraw; frame 5 = `empty_hand_breathe.png` frame 0 exactly. Canvas and offset as `give.png`. Our own art only.
Negative: outlines, black contour, front view, glow, text, ground, scenery, flute, throwing, walking
```

```
---
id: story_ivo_memorina_reach
command: animate3
target: res://assets/sprites/characters/ivo/ivo_memorina_reach.png
size: 128x128
frames: 5
view: side
direction: east
reference: res://tools/art/sources/story/ivo_idle_f0_2x.png
action: looks up and slowly lifts his right arm forward and up, his open palm turned up, until his hand is just above his head height in front of him, as if to take something offered by someone much taller; feet stay planted; always in right-facing profile
keep: 0-4
generate: 6
source: pixellab
---
Ivo reaching for the Memorina (STORY-35, plan as above; pose `RECEIVE`). Draft, awaiting approval. 5 frames, 8 fps once (0.625 s), held on 4. Frame 4's open hand is at file px about (79, 42): 15 px ahead of the axis (column 63.5), 54 px over the floor row 96, so faced west at (776, 672) it lies under the flute of `give.png` frame 3. No flute drawn. Cut by `python -I tools/art/cut_inhabitant.py <frames dir> ivo_memorina_reach tools/art/sources/story/ivo_idle_f0_2x.png <out> --keep=0-4 --floor=95 --centre=36-56`; frame 0 is idle frame 0 (`lock_to_still.py`).
Negative: outlines, black contour, front view, glow, text, ground, scenery, flute, jumping
```

```
---
id: story_ivo_memorina_take
command: animate3
target: res://assets/sprites/characters/ivo/ivo_memorina_take.png
size: 128x128
frames: 6
view: side
direction: east
reference: res://tools/art/sources/story/ivo_memorina_take_f0_2x.png
action: his raised hand closes around a small pan flute and he slowly brings it down and in, holding it just under his chin, looking at it; feet stay planted; always in right-facing profile
keep: 0-5
generate: 8
source: pixellab
---
Ivo taking the Memorina (STORY-35, plan as above; pose `MEMORINA_HELD`, then `memorina_hold`). Draft, awaiting approval. 6 frames, 8 fps once (0.75 s). Frame 0 = `ivo_memorina_reach.png` frame 4 with the flute pasted from `give.png` frame 3, mirrored into Ivo's frame (world px x maps to file column 839 - x and row y - 576 at his feet (776, 672) facing west), fingers closed on it; frame 5 = `ivo_memorina_lower.png` frame 1 exactly, so `memorina_lift` (lower 1, 0) and `memorina_put_away` (lower 1, 2, 3) follow without a pop. Composed by `tools/art/compose_strip.py` from the generation's frames 1-4. Colours: Ivo's palette and the Memorina still (`ivo_sheet_test` `HELD_PROPS`).
Negative: outlines, black contour, front view, glow, text, ground, scenery, playing, blowing
```

```
---
id: story_ivo_memorina_hold
command: animate3
target: res://assets/sprites/characters/ivo/ivo_memorina_hold.png
size: 128x128
frames: 4
view: side
direction: east
reference: res://tools/art/sources/story/ivo_memorina_lower_f1_2x.png
action: stands holding a small pan flute just under his chin, breathing slowly, his shoulders rising and falling a little; feet stay planted; always in right-facing profile
keep: 0-3
generate: 6
source: pixellab
---
Ivo holding the Memorina through "Essa é… essa é a música dela." and the choice (STORY-35, plan as above). Draft, awaiting approval. 4 frames played 0 1 2 3 2 1, durations 0.375 / 0.25 / 0.25 / 0.375 / 0.25 / 0.25 s (1.75 s, the keeper's breath). Frame 0 = `ivo_memorina_lower.png` frame 1 exactly; later frames by `lock_to_still.py` (only what moved), so nothing else flickers (`bugs/the-mentors-new-strips-redraw-the-figure-between-frame-0-and-frame-1`). Cut as `story_ivo_memorina_reach`.
Negative: outlines, black contour, front view, glow, text, ground, scenery, playing, blowing
```

Reference stills to make before generation (`pad_reference.py`, our own art): `mentor_hold_out_f3_2x.png`, `mentor_give_f3_empty_2x.png`, `ivo_memorina_take_f0_2x.png`, `ivo_memorina_lower_f1_2x.png`. Placeholders until approval: `give` and `let_go` repeat `hold_out` frame 3 then `empty_hand` frame 0; the three Ivo sheets repeat `ivo_memorina_lower.png` frame 1, so code, data and tests land first.

**As built (2026-11-23)**, superseding the drafts above where they differ; the contracts are `tools/art/prompts/story_mentor_give.md`, `story_mentor_let_go.md`, `story_ivo_memorina_reach.md`, `story_ivo_memorina_take.md` and `story_ivo_memorina_hold.md`, built by `tools/art/build_story35_hand_over.py`. Measured: `hold_out` frame 3's flute is world (755..768, 580..595), straight over Ivo's face (nose x 764, head top y 614), so `give` frame 3 puts it at (749..762, 610..625): 30 px lower and 6 px back toward the keeper. `ivo_memorina_reach` frame 4's palm is world (750, 626..629), under it; no step is needed. The mentor-to-Ivo file map at `ivo_near` facing west is (+53, -30). `let_go` has 5 frames (0.1 / 0.5 / 0.15 / 0.15 / held), its withdraw is `lower.png` frames 2, 1 without the flute; `ivo_memorina_hold` is procedural (2 px breaths on lower frame 1). `ivo_memorina_take.png` uses 3 flute colours outside the Memorina still: its `HELD_PROPS` entry is `tools/art/sources/story/ivo_memorina_take_palette.png`.

## Save facts

Reads: `DIALOGUE_HEARD mentor_gift`, `SCENE_SEEN mentor_turns`, `SCENE_SEEN memorina_hand_over` (stages). Writes: `SCENE_SEEN memorina_hand_over` (the director, live data; new `resources/save_facts/seen_memorina_hand_over.tres`; the scene added to `cutscene_catalog.tres`). Unchanged: ITEM 1 by `line_6`, `mentor_gift` heard at the talk's end. Nothing gates a way on it (the reach audit cannot read SCENE_SEEN).

## Tests

- New `tests/scenes/world/story/memorina_hand_over_test.gd`, using `strip_seam.gd`: `hold_out` 3 = `give` 0; `give` 3 = `let_go` 0; `let_go` 5 = `empty_hand_breathe` 0; in world px, every flute pixel of `give` 3 (mentor transform) that Ivo's hand does not cover equals `ivo_memorina_take` 0 at that pixel (Ivo's transform at `ivo_near`, facing west), and `take` 0 draws no flute pixel outside `give` 3's flute; `memorina_reach` 4 = `take` 0 outside the flute and the fingers; `take` 5 = `hold` 0 = `ivo_memorina_lower` 1; `memorina_lift` keys lower 1, 0 and `memorina_put_away` 1, 2, 3; the scene's last wait covers the hum's length from the grip; the stage order (Gone, Waiting, Stasis, EmptyHand, Holding, AtLamp).
- `cutscene_director_test`-style cases on the lantern: the end records and `EmptyHand` is the picked stage in the same frame; a skip lands `EmptyHand`, `MEMORINA_HELD`, the bloom hidden, no voice; a drop shows `HoldingOut` again.
- `player_beat_test`: `RECEIVE` plays the reach and holds it; `MEMORINA_HELD` plays take then the hold loop; MEMORINA from the hold plays lift then `memorina_idle` (never `memorina_draw`); NONE from the hold plays `put_away`; the component stays sheathed.
- `ivo_sheet_test`: the three sheets (floor row, axis, palette, the flute colours allowed by `HELD_PROPS`); the clips in the tree.
- Existing, updated: `story_beats_test` (cue `mentor_gift` still answered by one beat), `cutscene_rooms_test` (ids `mentor_staging`, `mentor_home`, `gift_bloom`, `ivo` resolve; the beat holds STILL; no talk in the scene), `cutscene_catalog_test`, `opening_test` / mentor suites that read `MentorGift` as a `StagedBeat`, `art_prompt_test`, smoke.
- Playtests: `tools/playtest/scripts/story35_hand_over.json` (watched; frame-stepped screenshots 2.0..2.3 s into the scene for a double or missing flute; the read at zoom 3) and `story35_hand_over_skip.json` (`"clock": "real"`).

## SOLID check

- The scene as data on the existing step set → Open/Closed: no new step, no branch in the director; tuning is `.tres` edits.
- The keeper as staging strips, Ivo's motion as poses → Single Responsibility: `FactStaging` alone shows the keeper, the resolver alone picks Ivo's clip, the director only sequences.
- The rest derived from SCENE_SEEN → one source of truth a death rewinds together with the item and the heard talk.
- Reusing `ivo_memorina_lower` frames for lift and put-away → no duplicate art to keep in step.

## i18n

No new user-facing text: the scene is wordless; the lines (`DLG_MENTOR_GIFT_*`, `DLG_CHOICE_MEMORINA_*`), the notice and "Skip scene" (`PAUSE_SKIP_SCENE`) already exist and go through `tr()`. Contract ids and step ids are not shown.

## Prior art and traps

Built on `architecture/cutscenes-are-data-played-between-two-rest-states`, `architecture/story34-mentor-at-the-lantern` (the turn's SCENE_SEEN-picked pose), `architecture/story37-the-mentor-moves-while-he-talks` ("STORY-35 starts the hand-over from its last frame"; `strip_seam.gd`), `architecture/story38-the-keeper-wakes`. Avoids `bugs/the-mentors-new-strips-redraw-the-figure-between-frame-0-and-frame-1` (lock every strip to its still) and `gotchas/a-replaced-sheet-plays-the-old-import-until-reimported` (import after the art swaps in). `systems/story` LineGesture limit: the held `HoldingOut` is replaced by the scene's first stand-in, so nothing outlives the talk. Not in scope: STORY-40 (the snap after the phrase).

## Open questions (user)

- **Q1 Who closes the gap.** (a) The keeper lowers the flute to Ivo's raised hand (**recommended**); (b) Ivo reaches overhead to where it is held now.
- **Q2 Framing.** (a) The pair at zoom 2, then a push to zoom 3 on Ivo's hands as the colour opens (**recommended**); (b) zoom 2 throughout; (c) the talk's 1.5 with bars only.
- **Q3 The colour.** (a) A spring bloom opening from the flute for about a second (**recommended**); (b) the same spring song pulse as today (one new step type).
- **Q4 Ivo after the take.** (a) The flute held under his chin, breathing, through "Essa é…" and the choice (**recommended**); (b) a new pose looking down at it in both hands (two more clips).
- **Q5 A step.** (a) He takes it from where he stands (**recommended**, if the measurement allows); (b) one slow step in before he reaches.
- **Q6 The keeper's empty hand.** (a) It opens, holds 0.5 s and returns to his chest (**recommended**); (b) it stays open and out until "Sua também…".
- **Q7 Actor or strips** (design 06 Pilar 1 lists the mentor as an actor). (a) Strips, as the rest of the lantern (**recommended**); (b) a mentor `StoryActor` now, its clips cut from every lantern strip.
- **Q8 The art.** (a) Approve the five contracts; placeholders meanwhile (**recommended**); (b) revise them first.

## Decisions (user, 2026-11-22)

- The height gap: "Keeper lowers it (Recommended)": the keeper's `Giving` strip lowers the flute about 30 px; Ivo takes it from where he stands.
- Framing: "Zoom 2, push to 3 (Recommended)".
- The keeper: "Swapped strips (Recommended)", not a mentor `StoryActor`.
- The rest, "Yes, all (Recommended)": a spring bloom from the flute; Ivo holds it under his chin, breathing, through his line and the choice; the keeper's empty hand opens, holds 0.5 s and returns to his chest; the five contracts are drawn with PixelLab and shown before wiring.
- The art (user, 2026-11-23): "Approve, wire it (Recommended)", with the known flaw that the flute and Ivo change size at take frame 3; the playtest judges it at speed.

## As built (2026-11-23)

- **As planned:** `Beats/MentorGift` is a `CutsceneBeat` playing `memorina_hand_over` (the shot list above, about 5.1 s); `Props/Mentor/Giving` and `LettingGo` are intro-only `StagedStrip`s; `mentor_staging` has six stages (EmptyHand on `seen_memorina_hand_over.tres`, 0 s, between Stasis and Holding); `GiftBloom` at (756, 618); `DialogueBeat.Pose` appends `RECEIVE` (8) and `MEMORINA_HELD` (9); the resolver's five clips (`memorina_reach`, `_take`, `_hold`, `_lift`, `_put_away`) are in Ivo's AnimationPlayer and tree. The removed `StagedBeat` took `wife_hum_opening.wav` and the spring `root` pulse with it; the hum is a `CutsceneSound`.
- **`let_go` has 5 frames** (0.1 / 0.5 / 0.15 / 0.15 / held), as the art paragraph above says; the hand-off timing is let_go frame 0 (0.1 s) against take frame 0 (0.125 s), at least one tick apart either way.
- **Two contract gaps the plan assumed away, closed in the cutscene runtime:**
  1. A scene's end released Ivo's pose (`WorldCutsceneContext.restore` emitted `ivo_posed(NONE)` before `Player.end_scene`), so a pose could never outlive a scene inside a talk, contrary to the plan's "a pose set by a scene inside a talk holds after it". Now only a drop releases it; a recorded or skipped end leaves the scene's last pose, which `end_scene` keeps inside a talk and drops outside one. The other scenes that end posed (`flashback_4`, `flashback_4_crossing`, `epilogue`) either end their talk with the scene or play outside one, so nothing else changes.
  2. A drop left a `CutsceneStage`'s stand-in showing; the docs promised "the rest shown before (a stand-in included) shows again". The context now records each staging's stand-in before the scene's first `CutsceneStage` (`FactStaging.is_standing_in()`, `stand_in_name()`) and a drop puts it back unless the pick changed, on the frame it showed (`StagedStrip.resume_at`; `bugs/a-dropped-cutscene-replays-the-gesture-it-gives-back`), so a dropped hand-over rests on `HoldingOut`'s held last frame.
- **`CutsceneCatalog.validate` checked a sequence inside a together as if it were the together**, so the grip's two sequences (`LettingGo` → `EmptyHand`; the bloom open → close) were refused for moving one subject twice. A sequence's or a branch case's own steps now run in order for that check; they still count against the together's other steps (`cutscene_catalog_test.test_a_sequence_inside_a_together_may_move_one_subject_twice`).
- **Seam tests** live in `tests/scenes/world/story/memorina_hand_over_test.gd` (no shared `strip_seam.gd`, as in STORY-37): the keeper's flute is found by colour (the colours `give` 3 draws only inside world (749..762, 610..625)); every rendered frame of the played scene is sampled for zero or two flutes.
- **Not run:** the playtests `tools/playtest/scripts/story35_hand_over.json` and `story35_hand_over_skip.json` are written from `mentor_gift.json`'s measured Z times, re-timed for the hand-over; the first run should check the Z times still land after STORY-37's gestures.
- **After the playtest (`playtests/2026-11-23-story35-hand-over`):**
  - The resumed talk opened its box at the bottom over Ivo. It took the side from the scene's camera, still easing back or skipped. Fixed at the root in the talk's box placement (`bugs/a-talk-resumed-after-a-cutscene-places-its-box-under-the-scenes-camera`). The skip's one stray frame at the scene's centre is gone (`GameCamera.snap()` places at once).
  - `ivo_memorina_take.png` is 10 frames (1.075 s). The flute shrinks over frames 3-8 (160 px, then 164, 120, 77, 53, 29, 14, 12) and the figure changes drawing between frames 3 and 4 with the flute still large, not in one frame (contract `tools/art/prompts/story_ivo_memorina_take.md`).
  - The hold stays at chest height. Its frame 0 must be `ivo_memorina_lower` frame 1: that is the take's last frame and the start of `memorina_lift` and `memorina_put_away`. Raising the flute only in the later frames would make it bob through every breath, so "under his chin" needs a new lower sheet (not done).
