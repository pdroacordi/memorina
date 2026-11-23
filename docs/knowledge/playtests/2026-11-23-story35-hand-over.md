---
id: playtests/2026-11-23-story35-hand-over
type: playtest
title: STORY-35 - the Memorina hand-over as the cutscene memorina_hand_over (played and skipped); the give reads, the flute pops small on take frame 3, and the resumed talk's box hides Ivo
status: active
tags: [story-35, story, mentor, lighthouse, cutscene, hand-over, memorina, staged-strip, pose, bloom, camera, skip, dialogue-box]
related: [architecture/story35-memorina-hand-over, bugs/a-talk-resumed-after-a-cutscene-places-its-box-under-the-scenes-camera, playtests/2026-11-18-story37-the-mentor-moves, playtests/2026-11-17-story34-mentor-at-the-lantern, systems/cutscenes, systems/story]
created: 2026-11-23
updated: 2026-11-23
build: 9ca29d9d + uncommitted STORY-35 tree (art 09:16, scene/contents 09:40, imported 11:02, runs 11:03-11:12; nothing in scenes/resources/assets/globals changed after the import)
area_tested: "frost_edge/lighthouse_top, mentor_gift talk to memorina_hand_over and back (pt_BR, talk zoom 1.5, scene zoom 2 to 3)"
ratings: { fun: n/a, fluidity: 3, aesthetics: 3 }
source_files:
  - resources/cutscene/story/memorina_hand_over.tres
  - scenes/world/rooms/frost_edge/contents/lighthouse_top_contents.tscn
  - assets/sprites/world/story/mentor/give.png
  - assets/sprites/world/story/mentor/let_go.png
  - assets/sprites/characters/ivo/ivo_memorina_reach.png
  - assets/sprites/characters/ivo/ivo_memorina_take.png
  - assets/sprites/characters/ivo/ivo_memorina_hold.png
  - tools/playtest/scripts/story35_hand_over.json
  - tools/playtest/scripts/story35_hand_over_skip.json
---

## Summary

A first-time player now sees a give. The keeper lowers his hand to Ivo, Ivo reaches up under it, the object turns to
colour in Ivo's hands as the bloom floods the frame, and the keeper's hand opens empty and withdraws. That is a clear
improvement on the old one-frame swap.

What the player sees of the object is weaker:
- The flute in the keeper's hand is a grey smudge against the grey wall.
- It is a readable 13x15 px coloured object for only ~0.375 s.
- On `ivo_memorina_take` frame 3 it pops down to a ~4 px item while Ivo's whole figure jumps taller. This is the
  approved known flaw, and it is visible at speed.

One bug: after the scene, played or skipped, "Essa é…" and the choice open the bottom box over Ivo, so the payoff pose
(holding the flute) is hidden. See `bugs/a-talk-resumed-after-a-cutscene-places-its-box-under-the-scenes-camera`.

## What was tested

- **r1:** `talk_reader_driver.gd` (READ 1.0, `CAMLOG=1`, `STRIPSHOT=1`, GAP 0.1) on `story37_mentor_talk_setup.json`'s walk,
  with a `log` step every 0.05 s from 18 s. It measured every line, strip frame, camera step and Ivo clip.
- **h1:** `story35_hand_over.json`. **k1:** `story35_hand_over_skip.json`. Both were re-timed from r1 (see below).
- **r2:** the reader driver plus the skip keys, which skipped during `Giving`. k1 skipped during the offer hold.
- **a1:** h1 without screenshots under `audio_probe_driver.gd`, for the hum.
- A source composite of `give`/`let_go`/`ivo_memorina_reach`/`_take`/`_hold` frames placed at their world transforms
  (`03_take_frames_source.png`), plus a script check that `take` frame 0 covers every flute pixel of `let_go` frame 0.
- **Timeline fixes:** the walk was Left 0.6-1.1 s. 0.5 s stops Ivo short of the zone (STORY-37), so it is now 0.6-1.2 s.
  The Z times are now 3.76 / 8.55 / 11.25 / 12.48 / 16.04 / 18.82 / 23.68 / 30.64 / 31.73, the hand-over shots moved
  -0.15 s, and the hand-off burst is every 0.05 s from 25.75 to 26.45, with `log` every 0.05 s. Both `_note`s now
  describe the measured beats. Runs still drift ~0.3-0.5 s: k1 paused in the offer hold, r2 in Giving.

## Findings

- **Measured beats (r1, runner t):**

  | Beat | t |
  |---|---|
  | Z on "Muitas mãos" | 23.68 |
  | Scene starts (bars, zoom 1.5 to 2) | 23.77 |
  | Zoom 2 reached | 24.77 |
  | `Giving` and `memorina_reach` | 25.17 |
  | `LettingGo` | 25.85 |
  | `memorina_take` | ~25.87 |
  | `let_go` frame 1 (hand open) | 25.96 |
  | `memorina_take` frame 3 | ~26.25 |
  | `memorina_hold` | ~26.65 |
  | `EmptyHand` | 26.97 |
  | Zoom 3 reached | 27.47 |
  | "Essa é…" | 28.90 |

  The scene lasts 5.13 s, as planned (~5.1).
- **Exactly one flute through the hand-off: yes.** The keeper draws it through `let_go` frame 0 (25.85-25.96). Ivo draws
  it from `take` frame 0 (~25.87). Source check: all 192 pixels that change between `let_go` 0 and 1 lie inside
  (749..762, 610..629), and `take` 0 covers all but 8 of them. Those 8 are the keeper's pale fingers at x 761-762, not
  the flute. The 0.05 s burst (`02_handoff_flipbook.png`, `handoff_00` to `_04`) shows no frame with two flutes and none
  with no flute.
  - The flute is grey (greyhush) in the keeper's hand and coloured in Ivo's, and it turns on the take frame, ~0.1 s
    before the bloom's ring shows.
- **The offer barely shows the object.** At zoom 2 the keeper's held-out flute is a light-grey shape a few pixels across
  over a grey wall (`01_offer_zoom2.png`). It first reads as a thing when it turns coloured in Ivo's hand. A player
  reads "he hands Ivo something" from the gesture, and learns that it is the flute only from the talk.
- **Take frame 3: noticeable at speed.** At ~26.25 (`handoff_09` to `_10` in the flipbook):
  - the flute drops from a 13x15 px brown and cream block to ~4x4 px at Ivo's chest;
  - his head jumps up ~6 px and his whole figure redraws larger;
  - his reaching arm drops to the hip.
  At zoom ~2.1 that is a ~12-window-px jump of the head. It lands mid-push and while the colour floods, which masks it
  somewhat, but a 10% size change of the figure in focus reads as a pop, not a motion. From then on the Memorina is a
  4 px item: at zoom 3 it is a tan dot in his hand (`05_held_after_bloom.png`), and at the talk's 1.5 it is barely
  there.
  - The hold is at chest height with the hand forward, which is `ivo_memorina_lower` frame 1. It does not read as
    "under his chin".
  - Suggestion: shrink the flute and grow the figure over take frames 1-4 instead of in one step, or keep a larger
    held flute until the hold.
- **Camera push: smooth by the log.** Zoom 2 to 3 runs 25.85-27.47 and the centre moves from (11628, -1308) to
  (11656, -1284), in even steps with no reversal. At zoom 3 the keeper's head and his withdrawing hand leave the top of
  the frame (`05_held_after_bloom.png`), so his "empty hand holds 0.5 s and returns" plays mostly at zoom ~2.2-2.5,
  during the flood. It is visible (r1 26.30 frame) but not featured.
- **Bloom: reads strongly.** A ring shows at ~26.0. By ~26.3 the whole view is spring-coloured, because at zoom 2-3
  the 112 px radius covers the frame: the keeper turns moss green and the wall dark (`04_bloom_zoom3.png`). The rings
  close at 27.5-27.8 and the grey is back by 27.86. It is the strongest read of the scene: colour comes from what Ivo
  now holds.
- **Talk resumes with Ivo holding it:** `memorina_hold` runs from ~26.65 through "Essa é…" and the choice (log
  `state=memorina_hold`), and "[Tocar de novo]" plays `memorina_lift` then `memorina_idle` at 31.90-32.05, with no
  belt draw (`07_lift_for_play_again.png`). **But the player cannot see it.** Both lines open the BOTTOM box, which
  covers Ivo entirely (`06_her_song_box_over_ivo.png`). "Muitas mãos" before and "Sua também" after open at the top,
  so the box also changes side twice. The line opens while the camera is still easing back from zoom 2.88 (28.90 to
  29.65), so it types over a moving frame. Bug filed.
- **Skip lands the rest state:** in both k1 (from the offer) and r2 (from Giving), `EmptyHand` is the only `Props/Mentor`
  child from the skip frame. Ivo plays `memorina_take` from frame 0, then `memorina_hold` (the known limit), and the
  bars are gone.
  - One rendered frame shows zoom 1.5 centred on the scene's point (-1308), then the talk framing (-1360): a 52 px
    vertical jump (`08_skip_one_frame_at_scene_centre.png`).
  - The box then opens at the bottom over Ivo (`09_skip_box_over_ivo.png`), so the "Ivo holding" rest is not visible
    after a skip either.
  - The pause menu's Skip took one unpaused frame of the scene (`Giving` frame 1) before the cut. This is harmless.
- **No errors** in any run's log apart from the usual "resources still in use at exit".

## What frames cannot show

- **The hum's timing**, measured on the Sfx bus meter (a1; the probe clock is ~3.7 s ahead of the runner's):
  - It starts with `memorina_take` (Sfx rises between runner 25.85 and 25.90) and lasts ~1.9 s, matching the 1.94 s
    wav. It ends ~27.8, while the bloom closes.
  - The scene then holds ~1.1 s of silence before "Essa é…".
  - The hum peaks at about -20 to -27 dB, while the line-open and typing sounds right after it peak at -5 to -12 dB.
    By meter the woman's voice is 10-15 dB under the UI blips. Whether that reads as intimate or as too faint needs
    ears.
- Whether the colour flood and the hum feel like one event, whether the 0.4 s offer hold is long enough to notice the
  object, and the weight of the push are inferred from timing only. A human playtest should confirm them.

## Ratings rationale

- **Fun:** n/a; this is a story scene.
- **Fluidity 3:** the motion chain (lower, reach, grip, withdraw, push) is continuous and the timings match the plan.
  Take frame 3's pop and the box flipping to the bottom are the two breaks.
- **Aesthetics 3:** the bloom is the best moment of the lantern so far. The object at the centre of the scene is
  either grey and lost against the wall, or 4 px.
- Confidence is moderate. Every judgement is from frames, logs and meters; none is from a watched run at speed.
