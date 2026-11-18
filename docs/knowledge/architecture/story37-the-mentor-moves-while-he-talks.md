---
id: architecture/story37-the-mentor-moves-while-he-talks
type: architecture
title: STORY-37 plan - the mentor breathes while he talks (Holding and EmptyHand become looping StagedStrips with the flute baked in) and gestures on three lines through a line-borne LineGesture that stands a strip in while the box stays open
status: built
tags: [story-37, story, mentor, lighthouse, staging, staged-strip, dialogue, gesture, line-gesture, animation, pixellab, plan]
related: [architecture/story34-mentor-at-the-lantern, architecture/story38-the-keeper-wakes, architecture/the-opening-is-staged-by-save-facts, architecture/cutscenes-are-data-played-between-two-rest-states, architecture/dialogue-is-data-and-choices-are-save-facts, architecture/props-and-ambient-life, systems/story, systems/dialogue, systems/cutscenes, systems/props, systems/greyhush, systems/art-pipeline, gotchas/sprite-frame-out-of-bounds-on-clip-switch, gotchas/a-killed-tween-never-emits-finished, gotchas/an-explicit-process-mode-escapes-a-disabled-ancestor, bugs/the-mentors-lantern-talk-opens-the-top-box-over-his-face]
created: 2026-11-18
updated: 2026-11-18
source_files:
  - resources/dialogue/dialogue_line.gd
  - resources/dialogue/dialogue_catalog.gd
  - resources/dialogue/story/mentor.tres
  - scenes/world/dialogue/dialogue_runner.gd
  - scenes/world/dialogue/dialogue_director.gd
  - scenes/world/story/line_gesture.gd
  - scenes/world/story/staged_strip.gd
  - scenes/world/environment/props/fact_staging.gd
  - scenes/world/rooms/frost_edge/contents/lighthouse_top_contents.tscn
  - tools/art/prompts/story_mentor_breathe.md
  - tools/art/prompts/story_mentor_tilt.md
  - tools/art/prompts/story_mentor_lower.md
  - tools/art/prompts/story_mentor_hold_out.md
---

# STORY-37 plan: the mentor moves while he talks

**Status: BUILT** (2026-11-18). As built: `lower` and `hold_out` keep 4 drawn frames (PixelLab's later frames thinned the mantle), the hold-out reaches its hold in 0.4 s; the seam checks live in `mentor_moves_test` (the shared `strip_seam.gd` was not needed); the test fixture is `tests/scenes/world/story/gesture_fixture.gd`. Roadmap STORY-37: "o guardião poderia ter mais animações enquanto fala" (user, 2026-11-17), then "Respirar + gestos (Recommended)": a subtle loop while he speaks (mantle and mask) and short gestures on three lines: a head tilt on "Guardo." (`DLG_MENTOR_GIFT_05`), the hand lowering on "Guardava." (`DLG_MENTOR_GIFT_09`), the flute held out on "Muitas mãos" (`DLG_MENTOR_GIFT_02`; the approved draft `docs/design/drafts/story32_34_talks.md` already says "(estende a flauta)" there). Art from his stills with PixelLab, approved by the user before it ships. Coordinated with STORY-35 (the hand-over as an animated scene, not started).

## Context

- `Props/Mentor` (`mentor_staging`) in `lighthouse_top_contents.tscn`: stages Gone · Waiting · Stasis · Holding (SCENE_SEEN `mentor_turns`, 0 s) · AtLamp. `Holding` is a Node2D with `Body` (`empty_hand.png`, `flip_h`, offset (-43, -120)) and a separate `Memorina` overlay (`memorina_in_hand.png` at (757, 574)). `EmptyHand` is a Node2D with one flipped `Body`. Beats face `Holding/Body` (MentorPhrase) and `EmptyHand/Body` (MentorGift, MemorinaLowered).
- What he shows on each of his lines: GIFT_01, 05, 09 and 02 are spoken over **Holding**; GIFT_03 ("Sua também…") over **EmptyHand**, the gift's stand-in, held from the gift to `mentor_goes_still`. Holding is picked only inside `mentor_gift`: SCENE_SEEN `mentor_turns` is written mid-talk and the talk's END (heard) picks Stasis; both are live data, there is no bench in the lantern, and nothing there hurts Ivo before the four are restored.
- **Frost Edge sits at 0.05.** `AmbientMotion` holds its frame below 0.2 (`systems/props`), so a breathing loop on the memory clock would never move in the lantern. His turn and his phrase already move there on the scaled clock (`StagedStrip`), as a character does (`systems/greyhush`: characters never freeze).
- A `DialogueLine.cue` plays **after** its line and the director closes the box for the beat (`DialogueDirector._play`). Nothing today moves a figure while a line is shown.
- `FactStaging.release(child)` acts only while `child` is still the stand-in; `_go_to` (a stage change) drops any stand-in. A `StagedStrip` restarts from frame 0 each time it is shown and stops when hidden; `stop()` emits no `animation_finished`.
- The turn's last frame is "Holding exactly" (`story_mentor_turn.md`), and `raise.png` starts on Holding. Every cut in the lantern is held to the pixel by `mentor_wakes_test._strip_meets`.
- `StoryActor.enter()` teleports onto the staging's shown child and reads its `flip_h` from a `Sprite2D` or `AnimatedSprite2D`; a bare Node2D like today's `Holding` reads as (0, 0), unflipped. STORY-35 will likely bring a mentor actor.

## Options considered

**1. The breathing loop and the flute overlay.**
- (a) Keep `Holding` as Body + overlay and require the flute hand to be pixel-still in every breathing frame. PixelLab drifts a pixel or two; one moved frame detaches the flute, and nothing can test the drift away at runtime.
- (b) An overlay that follows a per-frame offset table: a new script that writes a sprite's position every frame, a second writer beside the staging for one prop.
- (c) **Bake the flute into the frames** at cut time, as `raise.png`, `play.png` and `turn.png` already do. One PixelLab breath from `empty_hand.png` (the hand asked to stay still) gives EmptyHand's loop; Holding's loop is the same frames with `memorina_in_hand.png` pasted on the hand by the cut tool (offset per frame where the hand moved). The runtime overlay goes.
- **Chosen: (c).** Clock: `StagedStrip` on the scaled, pausable clock, not `AmbientMotion` (which would hold him still at 0.05).
- Which stages: **Holding and EmptyHand** (he speaks over both; EmptyHand is also what shows through Ivo's "Essa é… a música dela" and the choice, and a still man there reads as the stasis come early). AtLamp, Stasis and StillAtLamp stay stills (he says nothing at the lamp; the two greys are stopped by meaning).

**2. Holding as a nested strip or as the strip itself.**
- (a) `Holding/Body` becomes the strip, the Node2D kept: face paths stay, but the loop depends on a propagated `visibility_changed` and STORY-35's actor would still read a Node2D at (0, 0).
- (b) **`Holding` and `EmptyHand` become `StagedStrip`s themselves** at (720, 672): one node instead of three (shallow tree), the actor can stand on them, and the clip names `holding` / `empty_hand` are what `cutscene_rooms_test` will ask an actor's clips to be named. Cost: three `face` paths lose `/Body`.
- **Chosen: (b).**

**3. When a gesture plays.**
- (a) **After the line, as a beat** (no code): the tilt as a stand-in of `MentorPause` (box already closed there); a new cue-only line and beat after "Guardava."; the hold-out inside the gift beat. The box closes and reopens around "Guardava.", adding a pause the approved draft does not have ("Guardo" and "Guardava" in separate boxes with *one* pause between them); the gesture never sits on its word; and the hold-out inside `mentor_gift` collides with Ivo's MEMORINA pose, which starts with that beat (two flutes on screen).
- (b) **While the line is shown** (box open): a line field the director answers as the line shows, a small node that stands the gesture strip in and releases it when the clip ends. One field, one runner accessor, a few director lines, one ~30-line node. The gesture is on the word, the box stays where it is (bottom, under his face, `face_height` 110), the draft's rhythm is untouched.
- (c) A `DialogueBeat` flag that keeps the box open: changes what a beat is for every beat and the director's wait-for-finished path; a gesture does not hold the talk, so it is not a beat.
- (d) A gesture node that listens to `line_shown` and matches the text key: no director change, but it couples art to i18n keys (a variant changes the key) and needs a path to `World/DialogueDirector`.
- **Chosen: (b)**, the same lookup a `cue` uses (`DialogueBeat.find`), on a separate node and group so a gesture never counts as a beat.

**4. When a gesture ends.**
- (a) At the next line: a fast press cuts every gesture mid-motion, and the director would need a stop on each of its exits.
- (b) **At the clip's own end** (`animation_finished` → `release`), or earlier only if something else takes the staging (a beat's stand-in, a stage change), both of which `FactStaging` already handles. A gesture outlives a fast-pressed line by under 2 s and can never stay: a released, replaced or dropped stand-in is a no-op to release again, and a strip hidden mid-clip stops without emitting.
- **Chosen: (b)**, with one opt-out, `holds`, for the hold-out (Q2).

## Decision

### Data and code (all new code is small and has no input, no `WorldFreeze`, no visibility writes)

- **`DialogueLine.gesture: StringName`** (empty for none): "A LineGesture's id, played as the line shows; empty for none." Variants keep the line's gesture.
- **`DialogueRunner.gesture() -> StringName`**: the line's gesture on LINE, else `&""` (pure; mirrors `cue()`).
- **`DialogueDirector._step`**, LINE branch, after `line_shown.emit`: `_gesture(_runner.gesture())`, which returns on empty, finds `LineGesture.find(get_tree(), id)`, `push_error`s and goes on when none is loaded (as a cue with no beat does), else calls `play()`. No box change, no `talk_paused`, no wait: the talk never waits for a gesture.
- **`DialogueCatalog.validate()`** names a gesture on a line with no `text_key` (a cue-only line or a silent ask shows nothing to gesture over; this also keeps the new field apart from the silent ask, which the dialogue prose calls "a gesture").
- **`LineGesture`** (`scenes/world/story/line_gesture.gd`, `extends Node`, INHERIT, group `line_gestures`, under a contents scene's `Beats`): exports `gesture` (the id), `staging` (NodePath to a `FactStaging`), `child` (a `StagedStrip` child with an `intro` and no `loop`), `holds: bool = false`. `static find(tree, id)`. `play()` = `staging.stand_in(child)`. `_ready` connects the strip's `animation_finished` to `staging.release(child)` unless `holds`. It writes nothing else; `FactStaging` stays the only writer of the children's visibility.

### The staging (`Props/Mentor`)

| Child | Kind | Clip(s) | Shown by |
|---|---|---|---|
| `Holding` | `StagedStrip`, (720, 672), offset (-61, -126), `flip_h` | loop `holding` | stage Holding; the `mentor_turns` scene's `CutsceneStage`; every release while Holding is picked |
| `EmptyHand` | `StagedStrip`, same placement | loop `empty_hand` | the gift beat's stand-in (unchanged) |
| `Tilting` | `StagedStrip`, same placement | intro `tilt` | `LineGesture` `mentor_tilt` |
| `Lowering` | `StagedStrip`, same placement | intro `lower` | `LineGesture` `mentor_lower` |
| `HoldingOut` | `StagedStrip`, same placement | intro `hold_out` | `LineGesture` `mentor_hold_out` (`holds` true, Q2) |

- `Holding/Memorina` and both `Body` sprites are deleted; `AtLamp/Memorina` stays (AtLamp is a still).
- Face paths: `MentorPhrase.face` → `Props/Mentor/Holding`; `MentorGift.face` and `MemorinaLowered.face` → `Props/Mentor/EmptyHand`. Same point (720, 672).
- `Beats/` gains `MentorTilt`, `MentorLower`, `MentorHoldOut` (`LineGesture`s, staging `../../Props/Mentor`).
- `mentor.tres`: `line_3` (GIFT_05) `gesture = &"mentor_tilt"`, `line_kept` (GIFT_09) `&"mentor_lower"`, `line_4` (GIFT_02) `&"mentor_hold_out"`. No text changes.
- One clip per node, so no sprite switches between strips of different lengths (`gotchas/sprite-frame-out-of-bounds-on-clip-switch`). All INHERIT under `Props` (`gotchas/an-explicit-process-mode-escapes-a-disabled-ancestor`): a pause, the notebook or a recall's slow act on them as on the beats.

### How each line plays

- "Guardo.": the tilt starts with the line; whether the player presses at once or not, it finishes inside the 1.6 s `MentorPause` (no stand-ins there) and releases to Holding.
- "Guardava. ~Guardava~.": the hand lowers and comes back up (Q1). A fast press through Ivo's line lets `MentorPhrase` stand Playing in over it; the later release is a no-op.
- "Muitas mãos. Nenhuma ~guardou~.": the flute goes out toward Ivo and stays out (Q2) until `mentor_gift` stands EmptyHand in, as today.
- Seams: every strip's frame 0 is Holding's frame 0, which is today's composite (`empty_hand.png` flipped + `memorina_in_hand.png` at (757, 574)), so the turn's last frame, the raise's first and the release cuts are pixel-exact. `tilt` and `lower` also end on it. Cutting from a mid-breath frame to a gesture's frame 0 moves at most the breath's 1 px.

### The art (stills face west as authored; every strip is stored facing west and flipped in the scene)

Canvas for all five: 128x128, feet on row 125, frame (24, 6) is the stills' (0, 0), placed at (720, 672) with offset (-61, -126) and `flip_h`, exactly as `raise.png` / `play.png` (`systems/story`, STORY-11). The flute is drawn in every frame. Contracts go in `tools/art/prompts/` first; sources in `tools/art/sources/story/`; credits in `CREDITS.md`.

| Asset (`assets/sprites/world/story/mentor/`) | Contract | Drawn frames | Played (one SpriteFrames entry per row, frames reused) | From |
|---|---|---|---|---|
| `empty_hand_breathe.png` | `story_mentor_breathe.md` (animate3) | 4 (0 = `empty_hand.png` exactly) | 0 1 2 3 2 1 looped, 0.375 / 0.25 / 0.25 / 0.375 / 0.25 / 0.25 s (1.75 s a breath) | `mentor_empty_hand_codex.png` padded to 2x (`pad_reference.py`); mantle hem and shoulders 1 px, the mask up 1 px on the inhale, the raised hand still |
| `holding_breathe.png` | same contract, a cut step | 4 | as above | the breath frames with `memorina_in_hand.png` pasted on the hand (per-frame offset where the hand moved); no generation |
| `tilt.png` | `story_mentor_tilt.md` (animate3) | 3 (0 = Holding) | 0 1 2 1 0 once: 0.1 / 0.15 / 0.6 / 0.15 / 0.1 s (1.1 s) | `mentor_holding_2x.png`; the mask tilts down toward Ivo about 2 px, body still |
| `lower.png` | `story_mentor_lower.md` (animate3) | 4 (0 = Holding, 3 the lowest) | 0 1 2 3 2 1 0 once: 0.1 / 0.15 / 0.15 / 0.7 / 0.2 / 0.2 / 0.1 s (1.6 s) | `mentor_holding_2x.png`; the flute hand sinks from his chest to about his waist and rises again |
| `hold_out.png` | `story_mentor_hold_out.md` (animate3) | 5 (0 = Holding, 4 held out) | 0..4 once, 0.1 / 0.15 / 0.15 / 0.15 / held (0.55 s to the hold) | `mentor_holding_2x.png`; the arm extends toward Ivo (west in the file), flute offered flat; the end point is measured in the contract against Ivo's hands at `ivo_near` (776, 672) in his `memorina_draw` first frame, for STORY-35 |

Four PixelLab generations, five assets. Frame 0 of each strip is replaced by the exact still composite at cut time (`compose_strip.py`, as for `turn.png`). If a generation will not hold the figure, compose the in-betweens by hand as the turn's contract allows. Placeholders until approval: each strip is one frame of Holding's (or EmptyHand's) still, so the code, data and tests land first and the art swaps in.

## Tests

- `tests/scenes/world/dialogue/dialogue_runner_test.gd`: `gesture()` is the line's on LINE, empty on CUE, CHOICES and END, kept by a variant.
- `dialogue_director_test.gd`: a line with a gesture plays its `LineGesture` as the line shows with no `box_closed` and no `talk_paused`; a gesture with no node errors and the talk goes on; `advance()` works at once (the talk never waits).
- `tests/resources/dialogue/dialogue_catalog_test.gd`: `validate()` names a gesture on a cue-only line and on a silent ask.
- New `tests/scenes/world/story/line_gesture_test.gd` (a fixture staging with a picked child and a 3-frame intro strip): `play()` stands the child in; the clip's end returns to the picked stage; `holds` keeps it until a later `stand_in`; a later stand-in mid-clip is not undone by the clip's end; a stage change mid-clip drops it; `find()` by id.
- `story_beats_test.gd`: every gesture a catalog line names has exactly one `LineGesture` in the contents scenes, every `LineGesture` is named by a line, its staging is a `FactStaging`, its child a `StagedStrip` with a non-looping `intro` and an empty `loop`.
- New `tests/scenes/world/story/mentor_moves_test.gd`: Holding and EmptyHand are looping strips (frame counts, `loop` true) at (720, 672), offset (-61, -126), flipped; Holding's frame 0 is the old composite and EmptyHand's is `empty_hand.png` on the same pixels; Turning's last frame, `raise` frame 0, `tilt` and `lower` first and last, `hold_out` first all equal Holding's frame 0; the three `mentor.tres` lines carry their gestures.
- The pixel compare (`_strip_meets`, `_differs`) moves from `mentor_wakes_test.gd` into a shared test helper `tests/scenes/world/story/strip_seam.gd` (a RefCounted, like `dialogue_fixture.gd`), used by both suites and later by STORY-35. That is the only new non-trivial logic; `LineGesture` itself is wiring, covered by its scene suite.
- Unchanged and still green: `opening_test` (stage names `Holding`, `EmptyHand`; the phrase strip), `cutscene_rooms_test`, `talkable_rooms_test`, `dialogue_text_fit_test`, smoke.
- Playtest (`mentor_gift.json`, zoom 1.5 lift 64): the breath reads at that zoom and is not a jitter; each gesture is seen over its line with the bottom box open; a second timeline pressing every 0.1 s shows nothing sticking and no pop worse than the breath.

## Build order

1. `DialogueLine.gesture`, `DialogueRunner.gesture()`, the director's `_gesture`, the catalog rule, `LineGesture`; suites; `--import`.
2. The staging: Holding and EmptyHand as strips (placeholder one-frame loops, with a cut `holding.png` composite), the overlay and bodies deleted, face paths, the three gesture strips (placeholders), the three `LineGesture`s, `mentor.tres`; `strip_seam.gd`, `mentor_moves_test`, `story_beats_test`, `opening_test`, smoke.
3. Art: four contracts, the user approves them; generate, cut, the user approves the art; swap the placeholders; credits.
4. Docs: `systems/story` (the lighthouse row, `LineGesture`, the strips that loop at rest), `systems/dialogue` (`DialogueLine.gesture`, the director's step, the validate rule), `systems/props` (the `StagedStrip` exemption amended: a strip may loop on the scaled clock on a figure seen only inside a talk or a scene), `glossary.md` (gesture: a figure's clip on a line, vs the silent ask), the roadmap row with the user's words, `INDEX.md`.
5. `verify-gates`, then the playtest.

## SOLID check

- Gesture as a line field, played by id → Open/Closed: any talk adds gestures in data; the director has no speaker- or line-specific branch.
- `LineGesture` → Single Responsibility (an id to a stand-in and its release); `FactStaging` and `StagedStrip` are untouched (Open/Closed) and the staging stays the only visibility writer.
- A gesture is not a `DialogueBeat` → Liskov and Interface Segregation: a beat holds the talk and has hold/pose/face; a gesture has none of that, so it does not pretend to be one, and the director depends only on `play()`.
- Holding and EmptyHand as strips → any `CanvasItem` is a staging child (substitution); the same nodes serve a cutscene actor later.
- Timings, frames and ids are data in `.tscn` and `.tres`.

## i18n

No new user-facing text. Gestures carry no text; `mentor.tres` keeps its keys (`DLG_MENTOR_GIFT_05`, `_09`, `_02`), already in `i18n/translations.csv` and shown by the box through `tr()`. Contracts and ids are not shown to the player.

## What STORY-35 reuses

- `Holding`, `EmptyHand` and `HoldingOut` as strips at his feet with `flip_h`: a mentor `StoryActor` enters on whichever is shown, facing right, with its clips named `holding`, `empty_hand`, `holding_out` from the same PNGs.
- `hold_out.png`'s last frame is where the hand-over starts: STORY-35 replaces the gift beat's cut to EmptyHand (today a `StagedBeat`) with its scene from that pose; the measured flute point is in the contract.
- `LineGesture` for any line-borne motion in its scene's talks, and `strip_seam.gd` for its cuts.
- If STORY-35 is built first or together (Q2 (c)), `HoldingOut` may need no `holds` at all.

## Prior art and traps

- Reuses: `architecture/dialogue-is-data-and-choices-are-save-facts` (a cue finds its beat by group; a gesture finds its node the same way), `architecture/the-opening-is-staged-by-save-facts` (stand-ins and release), `architecture/cutscenes-are-data-played-between-two-rest-states` (Holding is the derived rest after `mentor_turns`), `architecture/story34-mentor-at-the-lantern` and `architecture/story38-the-keeper-wakes` (the stages, the strip canvas, the seam tests).
- Avoids: `AmbientMotion` at 0.05 (`architecture/props-and-ambient-life`, `systems/props`: it would hold him still); `gotchas/sprite-frame-out-of-bounds-on-clip-switch` (one clip per strip); `gotchas/a-killed-tween-never-emits-finished` (no tween is added; `FactStaging`'s fade already snaps); `gotchas/an-explicit-process-mode-escapes-a-disabled-ancestor` (no explicit modes); `bugs/the-mentors-lantern-talk-opens-the-top-box-over-his-face` (the bottom box under his face is what keeps the gestures visible: keep `face_height` 110).

## Consequences and risks

- `systems/props`'s rule that a `StagedStrip` is stood in by a beat becomes "seen only inside a talk or a scene". Holding is picked only inside `mentor_gift`; if a later change makes Holding a rest seen outside the talk, the clock question reopens.
- `DialogueLine` gains a field the director answers on every LINE step: one group lookup per gestured line, none otherwise.
- The word "gesture" now names two things in prose (a silent ask, a figure's clip); the code keeps them apart (`silent()` vs `gesture`) and the catalog forbids both on one line.
- The breath at zoom 1.5 is 1.5 px on screen; if the playtest reads it as jitter, the loop slows (durations are data) before it grows.

## User decisions (2026-11-18)

- Q4: "During the line (Recommended)".
- Q1: "Down and back (Recommended)".
- Q2: "Out, until the gift (Recommended)".
- Q3: "Keeps breathing (Recommended)".
- Q5 was not asked; taken as recommended (a), since his turn and phrase already move at 0.05 on the scaled clock.

## Open questions (as asked)

- **Q1 "Guardava."** (a) The hand lowers and comes back up within the line, so every gesture ends where it started and the phrase's raise is unchanged (**recommended**); (b) the hand stays down through Ivo's line until the phrase, which needs `raise.png` redrawn from the lowered hand or a visible jump when the box closes.
- **Q2 "Muitas mãos."** (a) The flute goes out and stays out until the gift, which still cuts to the empty hand until STORY-35 animates the hand-over from that pose (**recommended**); (b) out and back now, the hold-out left to STORY-35; (c) build STORY-35's hand-over in the same run.
- **Q3 EmptyHand.** (a) He breathes after the gift too, through Ivo's line, the choice and "Sua também…", from the same generation (**recommended**); (b) he stays still from the gift on.
- **Q4 When the gestures play.** (a) While the line is shown, the box open (a small new mechanism, **recommended**); (b) after the line with the box closed (no code, but a new pause after "Guardava." the approved draft does not have, and the hold-out meets Ivo's own flute in the gift beat).
- **Q5 Moving in the grey.** The lantern is at 0.05, where ambient props stop. (a) He breathes and gestures on the scaled clock, as his turn and his phrase already move there: he is alive until the stasis (**recommended**); (b) he stays still at rest and moves only in gestures.
