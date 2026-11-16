---
id: playtests/2026-11-16-story07-epilogue
type: playtest
title: STORY-07 the epilogue on the flat stone - the close-up, the pull-back that reveals Alba (now with a 1-frame sliver at the edge), both faces clear under the box at zoom 3 after the fix, the camera rise, her exit while the frame is up, the HUD fade, no replay on the stone
status: active
build: aa737e2d + the uncommitted STORY-07 step 10 tree in the main working tree; first runs imported 11:22:34, the re-run (section at the end) on the same tree with the three fixes (zoom 3 offset (0, -54), CutsceneFace alba -> ivo, EpilogueDirector.epilogue set), re-imported before it
area_tested: "world restored, all four guardians restored, all five flashbacks seen, daughter_reunion heard and seen. tools/playtest/scripts/story07_epilogue.json: Ivo at (3990, -530), Down at 1.5 s on StoneSeat, the whole epilogue (Z through eight lines), then Left to stand. Two short variants (scratch timelines): responses guardian_frost_gift = guardian_frost_gift_close (en) and locale pt_BR, both to Ivo's first line."
tags: [story-07, epilogue, cutscene, dialogue, camera, alba, playtest]
related: [architecture/story-07-epilogue, systems/cutscenes, systems/dialogue, systems/story, systems/music, playtests/2026-11-16-story07-walk-home-reunion, bugs/the-first-guardian-talks-zoom-hides-the-guardian-behind-the-dialogue-box]
created: 2026-11-16
updated: 2026-11-16
ratings: { fun: 0, fluidity: 3, aesthetics: 3 }
screenshots:
  - 2026-11-16-story07-epilogue/s02_closeup_zoom4.png
  - 2026-11-16-story07-epilogue/p_007.30.png
  - 2026-11-16-story07-epilogue/s07_pair.png
  - 2026-11-16-story07-epilogue/s16_talk3_alba.png
  - 2026-11-16-story07-epilogue/s17_ivo_alba.png
  - 2026-11-16-story07-epilogue/s20_top.png
  - 2026-11-16-story07-epilogue/s22_back_on_ivo.png
  - 2026-11-16-story07-epilogue/close_v_line2.png
  - 2026-11-16-story07-epilogue/crop_rerun_edge_7.15-7.40.png
  - 2026-11-16-story07-epilogue/s27_sat_again.png
---

# STORY-07: the epilogue on the flat stone

**The screenshots in the folder are from the re-run after the fixes** (see the last section); the findings below were written against the first runs, and findings 1, 2 and 4 are resolved there.

Three windowed runs, each with its own `APPDATA` (checked before every run). A scratch `-s` probe driver around
the runner printed every change of the director's scene and running task, the dialogue box (text, typing),
the camera centre and zoom, Alba's visibility and Ivo's facing. A first exploratory run let the probe press Z
1.6 s after each line had typed. The committed timeline uses those measured times as fixed Z presses, and its
log matched the probe's to within 0.15 s. No SCRIPT ERROR or parse error. The only engine output was the usual
"resources still in use at exit".

## Timeline as measured (main run, runner `t`, scaled clock)

| t (s) | Event |
|---|---|
| 1.51 | Down: Ivo snaps onto the stone (4016, -512), facing west. Scene `epilogue` starts. |
| 1.51-3.03 | Frame closes to zoom 4, centre (3952, -528). |
| 3.03-4.72 | The four notes (melody step). |
| 4.72-7.22 | The 2.5 s gap. |
| 7.22 | Alba placed (visible). The pull-back starts on the same frame (zoom 3.98). |
| 7.22-10.24 | Pull-back to zoom 2, centre (4028, -552). |
| 10.24 | Talk 1, line 1. **Ivo's facing flips -1 to 1 (east, toward her) on this frame.** |
| 14.95-16.85 | The 2 s pause with no box. |
| 16.85-27.14 | Talk 2, four lines. |
| 27.15-28.6 | Close to zoom 3, centre (4028, -544). |
| 28.6-32.63 | Talk 3: "Miss it. Play it anyway." / "Alba." |
| 32.65 | Duet starts; the rise to `waterfall_top` begins. |
| 41.15 | The camera reaches the top (4320, -1064). That is 8.5 s. |
| 45.11 | Alba hidden (12.47 s into the music; mark 12.45). The descent starts. |
| 46.63 | Back on Ivo at zoom 2, centre (4016, -552). That is 1.52 s. |
| 48.46 | Mark 15.8 s. |
| 50.48 | Scene over. Zoom eases back to 1. `blocked=false`, Ivo still seated. |
| 55.0 | Left stands him up and walks him off. |

Run-to-run spread between the exploratory and main runs was ≤ 0.15 s at every event.

## What each screenshot shows

- `s00_before_down`: Ivo landing at x 3990 under the Down prompt. The garden is in the late-afternoon set: warm sky, lantern lit, the waterfall running.
- `s02_closeup_zoom4`: the close-up. Ivo sits at the right edge of the frame, facing west. His back is about 2-4 game px from the edge. The rest of the frame is the bush, grass and backdrop. **Alba is not in it.** The same holds for every close-up frame up to 7.15.
- `p_007.30`, `p_007.45` (burst every 0.05 s from 7.15): Alba enters from the right edge as the frame widens. At 7.25 she is not visible. At 7.30 a 1-2 game px sliver of her hair shows at the edge, and by 7.45 her head is in. She is revealed by the frame, not popped in mid-frame. The margin is thin, though. Her sprite's left edge sits within ~1-2 game px of the zoom 4 frame's right edge (4032), so any later change to the close-up offset, the mark or her sprite would show her before the pull-back.
- `s07_pair`: zoom 2 at the end of the pull-back. Ivo on the stone, Alba seated on the ground just east of it, the lantern beyond her. No bars and no dither.
- `s08_talk1_alba`, `s09_talk1_ivo`: the box opens at the top with portraits and name plates. At zoom 2 its bottom edge crosses the top 1-2 game px of Ivo's hat. His face and hers stay clear.
- `crop_turn_at_first_line` (crop of two exploratory frames, t 10.0 and 11.0): Ivo faces west during the gap and pull-back, then faces east (toward Alba) from the frame the first line opens. The turn is a cut, on the same frame the box appears.
- `s15_zoom3_closing`: zoom 3 on the pair, with no box between the talks.
- `s16_talk3_alba`, `s17_ivo_alba`: **at zoom 3 the top box covers Ivo's whole head.** The box's lower edge sits at his scarf. It also covers the crown of Alba's hair. On "Miss it. Play it anyway." and on his "Alba." the player sees the speakers only as bodies under the box. Their faces show only in the portraits.
- `s18_duet_start`: zoom 3 again, no box. Alba is on `sit_sing`, though it reads the same as `seated` at this size. Ivo shows the plain seated `sit` stand-in, not a Memorina pose: expected (`ivo_sit_memorina` is a later art step).
- `s19_rise_mid`: halfway up. The frame shows the backdrop and the cliff, with the fall only at its right edge. The rise goes diagonally (up and east) through mostly empty backdrop.
- `s20_top`, `x_045.10`: the top frame. The fall issues from under a cobbled stone ledge at the room's top. The left half is backdrop, with a flat pale band at the very top. Alba's exit at 45.11 happens here, ~550 px below the frame, so it cannot be seen.
- `s22_back_on_ivo`: zoom 2 on Ivo alone on the stone, facing east toward her empty place. Nothing is left where she sat.
- `s24_scene_end`, `s25_after`: the zoom eases back to 1. The garden stays in late afternoon. Ivo is still seated, Alba gone, and no prompt shows. Left stands him up normally (`s26_free`, not copied).
- `close_v_line2`: with `guardian_frost_gift_close` answered, Ivo's first line is "I should have listened to you. I think about it every day.", as expected. The base run shows the base line "I should have listened to you." (no answers, a tie).
- `ptbr_v_line1`: pt_BR "Você ainda carrega aquele dia.", which fits on one row. The second line, "Eu devia ter escutado você.", is in the same run.

## Draw order

The stone (light grey) is behind both of them. Ivo sits on it. Alba sits on the ground at its east end and is drawn over the stone's right edge. The foreground grass is in front of both. They do not overlap each other, so neither is wrongly in front of or behind the other. Nothing is cut wrongly in any frame.

## Findings

1. **[Fixed in the re-run]** **Defect (reproducible): the zoom 3 close hides Ivo's face, and the top of Alba's head, under the top dialogue box** during talk 3 (`s16`, `s17`). It is the intimate beat of the scene ("Na última frase a câmera fecha nos dois"). Cutscene talks pass `face_height` 0, so `DialogueBoxSide` always opens the top box here. The box bottom (176 screen px) is above the pair's heads at zoom 2 but crosses them at zoom 3. Possible fixes: offset `close_on_both` downward (frame the pair higher, e.g. offset y ≈ +16..+24), keep zoom 2 for talk 3 and close only after it, or open the bottom box for this talk. The same pattern as `bugs/the-first-guardian-talks-zoom-hides-the-guardian-behind-the-dialogue-box`. **Not filed to `bugs/`: this session's instructions limited writes to this entry.** It should be filed.
2. **[HUD part fixed in the re-run; credits still unassigned, as expected]** **Wiring gap: `game.tscn`'s `World/EpilogueDirector` has no `epilogue` or `credits` set.** `_is(scene, null)` is false, so `ending_began` never fires. `LifeHud` (the three notes at the top left) stays on screen for the whole epilogue (every frame here), and nothing follows the scene. No credits, no rest on `garden_stone`. The run ended seated in the garden with `scene=-` for 11 s, then walked away. This may be expected while step 11 (credits) is unbuilt, but the HUD fade belongs to the epilogue itself. Setting `epilogue` alone would fix it.
3. **Ivo turns from west to east by a cut on the frame the first line opens** (`crop_turn_at_first_line`). Facing the person he talks to is right, but the turn lands with the box and after the reveal. It could come earlier: when she is placed, or during the pull-back. Turning before the pull-back starts would mean he "knows" she is there before the camera shows her. Turning during the pull-back reads as him noticing. This is a staging question, not a bug.
4. **[Changed in the re-run: she now faces Ivo]** **Alba faces east, away from Ivo, for the whole scene.** Both look toward the waterfall side by side, which may be the intent (they both watch the fall, and the camera then rises up it). But she never turns to him, even on "Because I loved you." Flagged for the author to confirm.
5. **The close-up's framing:** Ivo is pressed against the right edge with ~2-4 px to spare, and most of the zoom 4 frame is bush and grass. That keeps Alba off frame (the reveal works). As a close-up "nele, de perto" it frames the bush more than him. Alba's margin off the edge is ~1-2 game px (see `p_007.30`), so this composition is fragile.
6. **The rise:** for most of its 8.5 s the frame crosses plain backdrop (`s19`), and it ends on the fall issuing from a stone ledge with a flat pale band above (`s20`). The draft has the camera rise "pela cachoeira até o céu". Here it never shows open sky, and it only reaches the fall in its last third. Her exit at 12.47 s happens ~550 px below the frame, so its timing against the camera is correct: invisible, as intended.
7. **Timing matches the outline:** close 1.5 s, gap 2.5 s, pull-back 3.0 s, pause 2.0 s, close 1.5 s, rise 8.5 s, exit at 12.47 s into the music, descent 1.52 s (it lands at ~14.0 s of music, inside the flute's lone held C, 12.45-14.12 per `music/wifes-song.md`), end 2.0 s after the 15.8 s mark.
8. **Works as specified:**
   - Alba is never visible in the close-up;
   - she is "simply there" after the pull-back, with no fade, bars or dither;
   - the box never covers a face at zoom 2 (it grazes Ivo's hat);
   - the tone variant (close) and pt_BR text play;
   - after the scene Ivo is free and the garden keeps its afternoon.

## What the screenshots cannot show

- **Sound.** The hush of the region theme, the four Memorina notes (E G E D), the 2.5 s silence, the duet and her voice's release against her disappearance were not heard. The timing above is the director's step clock compared with the `CutsceneMusicMark` values. Whether the music actually starts on the frame the step logs, and whether 12.45 s matches her audible release, needs a human listen, or an `audio_probe_driver.gd` run (`[aud]` lines).
- **Camera smoothness.** The pull-back, rise and descent were sampled at 1 s, plus one 0.05 s burst. Their easing, and whether the 1.5 s descent feels rushed after an 8.5 s rise, can only be judged live. The descent is 5.7x faster than the rise, an inference from the numbers.
- **Feel.** Fun is not rated (0). Fluidity 3/5 is inferred from the step timings and the hard turn cut. Aesthetics 3/5 is held back by finding 1 and the empty mid-rise frames. A human run should confirm both.

## Re-run after the fixes

One run of the same timeline, with the end changed to Left 0.12 s (stand), Down at 56.8 and a shot at 61.0. Every
event fell within 0.02 s of the first run, so the Z times were kept. The probe now also logs `LifeHud.modulate.a`.

- **Zoom 3 under the box: fixed.** The camera centre is now (4028, -568). In `s16_talk3_alba` and `s17_ivo_alba`
  both heads sit fully under the top box, Ivo's hat ~12 game px below its edge, and their faces are readable on both
  lines.
- **Alba faces west, toward Ivo, from her first frame to her exit** (`s07_pair`, `s16`, `s17`, `s18_duet_start`).
  Ivo still turns east by a cut when the first line opens (finding 3 stands).
- **HUD fade: fixed.** `hud` goes 1.0 to 0.0 over 1.5 s from the scene's start (1.52 to 2.94), stays 0 for the whole
  scene and returns 0 to 1.0 over 1.4 s after its end (50.48 to 51.91). The notes are absent from every frame from
  `s02` to `s23`. As expected, nothing follows the scene: no credits, no rest.
- **No replay on the stone.** After standing and pressing Down at 56.8, Ivo sits on the stone (`sit=true`,
  `blocked=false`) and the director stays idle (`scene=-`) through 62 s. `s27_sat_again` shows him seated at zoom 1
  in the afternoon garden with the HUD up.
- **New, minor: the reveal margin is gone.** Facing west flips her sprite, and her hair now reaches ~2-3 game px
  inside the zoom 4 frame's right edge. She is placed at 7.229, on the same frame the pull-back starts
  (zoom 3.98). In `p_007.25` (the first frame after placing) a block of her hair is already at the edge, while the
  frame has barely moved. `crop_rerun_edge_7.15-7.40.png` (the right 30 game px of the 7.15-7.40 burst) shows it.
  Before the fix she was off frame at 7.25 and entered at 7.30. It reads as a one-frame pop at the edge rather than
  a reveal, though it is small and at the very edge. Moving `close_on_him`'s offset from -64 to about -72, or
  placing her a few px further east, would give back a margin.
- **Second re-run, close-up offset (-72, -16):** Alba is no longer visible at the edge anywhere in 7.15-7.40 (`p_007.25`, `crop_rerun_edge_7.15-7.40.png`). But Ivo no longer fits in the close-up: the zoom 4 frame's right edge is now x 4024 (centre 3944), and in `s02_closeup_zoom4` his back, the rear of his hat and his seat are cut by the edge. Only his face and front show. At offset -64 Ivo's back reached ~x 4029, and facing west Alba's hair starts at ~x 4030, so no camera offset keeps him whole and her out. Move `BesideStone` (x 840) about 8-12 px east, and return the offset to -64.
- **Third re-run, offset back to (-64, -16), Alba placed at `beside_stone` + (12, 0) (world x 4052):** Ivo is fully inside the zoom 4 close-up again (`s02_closeup_zoom4`, as in the first run). Alba is not visible at the right edge anywhere in 7.15-7.40 (`p_007.25`, `crop_rerun_edge_7.15-7.40.png`); she enters with the widening frame after 7.40. At zoom 2 (`s07_pair`) and zoom 3 (`s16_talk3_alba`, `s17_ivo_alba`) she sits on the ground just past the stone's east end, facing him. The gap between them is about one body width (~14 game px between his knees and her back hair). They still read as sitting together by the stone, a touch less close than before; at zoom 3 both heads stay clear of the box.
