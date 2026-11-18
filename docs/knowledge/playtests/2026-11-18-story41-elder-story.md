---
id: playtests/2026-11-18-story41-elder-story
type: playtest
title: STORY-41 - the elder's story talk with the painting close-ups (zoom 4 on "Ele…", zoom 3 on [Olhar o quadro]), both branches in pt_BR, per-frame camera log
status: active
tags: [story-41, elder, dialogue, cutscene, camera, close-up, painting, opening, pt-br]
related: [bugs/the-elders-lighthouse-painting-shows-no-lighthouse, playtests/2026-10-16-story16-opening, playtests/2026-11-18-story39-camera-release, bugs/look-at-the-painting-turns-ivo-the-way-he-already-faces, systems/dialogue, systems/cutscenes, systems/story]
created: 2026-11-18
updated: 2026-11-18
build: round 1 = 66b357b5 + uncommitted STORY-41 (elder.tres 08:58:50, both cutscenes and village_elder_contents.tscn 08:59:10, translations.csv 08:58:50). Imported 09:07; Round 2 = the 09:18-09:22 follow-up (painting redrawn 40x56, offset (-20,-56); painting_view (410,170); ivo_walks_to_painting ends facing the elder), re-imported 09:24:58, runs p2/w2/r1 09:25-09:33; no file newer than that import at report time.
area_tested: "home_village/village_elder: elder_story (zoom 2) with elder_looks_at_painting (painting_view, zoom 4, hold 1.6 s), both choices, ivo_walks_to_painting (zoom 3), gate_bolt, the release"
ratings: { fun: n/a, fluidity: 4, aesthetics: 4 }
source_files:
  - resources/dialogue/story/elder.tres
  - resources/cutscene/story/elder_looks_at_painting.tres
  - resources/cutscene/story/ivo_walks_to_painting.tres
  - scenes/world/rooms/home_village/contents/village_elder_contents.tscn
  - i18n/translations.csv
  - tools/playtest/scripts/story16_elder.json
  - tools/playtest/scripts/talk_reader_driver.gd
---

## Summary

**Round 2 (redrawn painting, Ivo turns back): pass.**
- The 40x56 painting reads as a white lighthouse with a lamp, a beam, a cliff and the sea: at zoom 1 in the room, and in both
  close-ups.
- The zoom-4 close-up frames it whole and centred.
- After [Olhar o quadro], Ivo now faces the elder for every line.
- No camera step is above 6 px: 5.71 px max in a run without gap screenshots.
- `bugs/the-elders-lighthouse-painting-shows-no-lighthouse` is fixed.

Two small notes remain:
- the zoom-2 talk frame cuts the painting's top 10 px at the screen edge;
- the picture's bottom third hangs over the dark horizontal beam, where its brown frame has little contrast.

**Round 1 (the first STORY-41 build):**
- The staging worked: both close-ups play with the box closed, the camera eases in and out without a cut, the talk reads in the
  script's order, and it ends with the bolt and the "east" intent.
- The defect was the old 18x26 painting, which had no lighthouse in it.
- The two staging notes from round 1 are below. Round 2 fixed the first one, Ivo's back to the elder. The second, "aí" being said
  after the close-up, stays as before.

## Details

### Round 2 (09:25-09:33, redrawn painting, `ivo_walks_to_painting` ends `toward = elder`)

Runs:
- `p2` ([Olhar o quadro]) and `w2` ([Esperar por ele]), set up as in round 1;
- `r1` ([Olhar o quadro]) with `GAP=100`, so the run takes no box-closed screenshots, plus zoom-1 room shots at t 0.3 and 57.

Both talks read the same 23 `[dlg]` events as round 1 and log no new errors.

**The painting reads as a lighthouse at every zoom.**

| Shot | What it shows |
|---|---|
| `j_v2_room_zoom1.png` (t 0.3, before the talk) | A white tower with a brown lamp and a pale beam, over a dark cliff and the sea, hanging between the fireplace and the map. It reads even at 1x. |
| `p_v2_painting_on_the_beam_zoom1.png` (crop, 2x) | Placement. The painting is centred on the vertical post. Its top half is on plaster, its bottom third on the dark horizontal beam. |
| `k_v2_closeup_zoom4.png` (close-up 1, hold 13.03-14.66) | Centred and whole at 160x224 game px, with the beam and the lamp crisp. The box is closed. |
| `l_v2_closeup_zoom3.png` (close-up 2, hold 20.17-21.37) | The painting upper centre, Ivo's head at the bottom left, looking up at it. |
| `m_v2_talk_frame_zoom2_top_clipped.png` | The zoom-2 talk frame after the talk, box closed. The view's top is world y 12150 and the painting's top 12140, so the top 10 px (the frame and some sky) are cut by the screen edge. The lamp and tower still show. |
| `n_v2_painting_above_the_box.png` | While a line is open, the lamp and tower top peek between the screen top and the box. A nice accident: "lá" now has the lamp in view. |

**Placement.**
- The ceiling does not clip it: the room's top is far above, see `j_…`.
- Hanging over the beam is plausible, since a picture hung on a timber rail looks like this. But the bottom of the brown frame and
  the dark sea meet the dark beam with little contrast, so at zoom 1 the picture's lower edge blurs into the beam. The map beside it
  does the same.
- If the user wants it clearer, raising it ~20 px puts the whole frame on plaster. Today it is a taste note, not a defect.

**Ivo faces the elder after the close-up** (`o_v2_ivo_turns_to_elder.png`, left to right): close-up 2 (facing the painting), then
"Ainda tá de pé…", "Eu também paro…", "Então eu vou." and "Traz o fim…", all facing west toward the elder. `gate_bolt` still
turns him east at the end, and the log shows `INTENT_EAST`.

**Camera, max step per window (world px):**

| Window | p2 | w2 | r1 (no gap shots) |
|---|---|---|---|
| Close-up 1 in (2→4) | 8.37 | 8.37 | **4.57** |
| Close-up 1 out | 5.65 | 5.65 | 5.71 |
| Close-up 2 in (2→3) | 4.13 | n/a | 4.13 |
| Close-up 2 out | 3.87 | n/a | 3.87 |
| Release | 4.88 | 3.05 | 4.88 |

- The 8.37 in p2 and w2 is two physics steps drawn in one frame (dz 0.100 = 2 x 0.05, between steps of 4.00 and 4.33), at the
  t 12.53-12.54 `gap` screenshot. It is the capture hitch (~37 ms per shot), not the curve: r1, with no screenshots in that window,
  peaks at 4.57 with a smooth in-out.
- Close-up 1 now travels 70 px up instead of 57 (painting_view y 170), so its peak step rose from 4.33 to 4.57.
- The pre-existing talk zoom-in (14.54) and the p2 release kink (3.89 change of step) are unchanged from round 1.

### Round 1 details (old 18x26 painting)

### Method

- `talk_reader_driver.gd` (scratch copy with one addition: `CHOICE=1` taps Down halfway through the read before Z) with `CAMLOG=1`
  and `READ=1.2`.
- Setup: `story16_elder.json` reduced to its walk-in (Right 0.6-1.4 s), with `"locale": "pt_BR"`, `max_duration` 100 and a final
  `log` at 95.
- `APPDATA` was redirected to a fresh scratch folder per run, checked with a headless `OS.get_user_data_dir()` probe.
- One run per branch: `p1` = [Olhar o quadro] and `w1` = [Esperar por ele].
- The camera was judged from the `[cam]` lines (one per physics step), split into windows. The step is the world-px change of the
  screen centre between consecutive lines.

### 1. The painting in the close-ups: the frame is right, the art is not

- **Close-up 1 (`elder_looks_at_painting`):** the box closes at t 11.92. The camera eases to (5210, 12183) at zoom 4, arriving at
  13.03, and holds 1.61 s, to 14.645. The painting is centred, whole, and nothing covers it (`b_closeup_zoom4.png`). Fixed since
  STORY-16, where "at the elder's painting the painting is above the frame" (`2026-10-16-story16-opening`).
- **Close-up 2 (`ivo_walks_to_painting`):** Ivo walks from x 5109 to 5192. The camera eases to (5210, 12199) at zoom 3, arriving
  at 20.17, and holds 1.2 s. The painting sits upper centre, with Ivo's head and shoulders at the lower left, facing it
  (`f_closeup_zoom3_ivo_under.png`). The box is closed throughout.
- **It does not read as a lighthouse.** Inside the frame there is a pale grey-green sky over dark slate and brown blocks
  (`c_painting_source_vs_closeup.png`: the PNG at 16x beside the close-up). The art contract asks for "a white lighthouse on a
  cliff". The in-game pixels match the source, so the art is at fault, not the camera. Without the elder's words you would not
  know it is a lighthouse. The bookshelf's lighthouse model is outside both close-ups.
- At zoom 4 the painting fills about 72x104 of the 640x360 frame. Most of the shot is timber wall. With art that reads, that
  would be fine. With this art the shot looks empty.

### 2. Camera: no cut or step in or out of either close-up

| Window | p1 max step | w1 max step | Max change of step between frames |
|---|---|---|---|
| Close-up 1 in (zoom 2→4, 0.8 s) | 4.33 px | 4.33 px | 0.29 |
| Close-up 1 out (zoom 4→2, with the girl's line) | 5.40 px | 5.40 px | 0.25 |
| Close-up 2 in (zoom 2→3, 0.6 s) | 3.84 px | n/a | 0.74 |
| Close-up 2 out (zoom 3→2, with the elder's line) | 3.59 px | n/a | 0.17 |
| Release after the bolt (zoom 2→1) | 4.88 px | 3.05 px | 3.89 (p1), 1.42 (w1) |
| Talk zoom-in at the start (zoom 1→2, unchanged by STORY-41) | 14.54 px | 14.54 px | 14.54 |

- Every close-up ease stays under 6 px per step, and the centre's speed rises and falls smoothly (in-out).
- The zoom component of each ease starts at full rate: the first frame is +0.082 on 2→4, and the rate then decays. It does not
  start from zero. The centre does. A human should judge whether that start reads as a kick. It cannot be seen in stills.
- After close-up 2 the talk frame re-centres for Ivo's new x (5090.56 → 5132), inside the same 3.59 px ease.
- p1's release has a small speed kink at t 52.55: 2.2 → 0.99 → 4.88 px per step. It is under 6 px, so it passes, but it is a step
  change of 3.9 px per frame where w1's is 1.4. It is probably the look-ahead seeding after Ivo was turned east (STORY-39 code).
- **Outside STORY-41 (pre-existing, `camera.gd` is committed and unchanged):** the talk's own zoom-in at t 1.6 jumps from rest to
  14.5 px per step on its first frame and then decays: an ease-out with no ease-in. The criterion was for the close-ups, so it is
  noted here, not filed. STORY-39 measured only the release.

### 3. Order and text fit

Both branches read in the order of `05_roteiro.md` §6:

1. "…e toda noite…"
2. "Até o que caía na água, vô?"
3. "Até isso… Até que um inverno ele—"
4. "Ele…"
5. close-up 1
6. "Ele sempre para aí." (Menina)
7. "Tinha um fim. Tinha um fim bom."
8. the choice (`e_choice.png`)
9. the branch:
   - [Esperar por ele]: "…até que um inverno— até que um—" / "Não vem. Faz tempo que não vem.";
   - [Olhar o quadro]: close-up 2, then "Ainda tá de pé, sabe. Meu pai subiu lá uma vez.".
10. "Eu também paro no mesmo lugar. Numa música." … "Traz o fim da história, tá?"

Line counts: 19 in p1 and 20 in w1. Every line fits the box in one or two lines, and the plates (Ancião, Menina, Ivo) fit.

After the last line closes, `gate_bolt` turns Ivo east (`i_gate_bolt_ivo_turns_east.png`). The final log shows
`intent=INTENT_EAST` and `blocked=false` in both runs. The bolt's sound cannot be judged from a screenshot.

### 4. Framing after the close-ups

- For every line after a close-up, the talk frame (zoom 2, box on top) shows Ivo, the elder and the two children below the box
  (`d_she_always_stops_there.png`, `g_after_closeup_ivo_faces_painting.png`).
- **Ivo faces the painting (east, away from the elder) for all 11 lines after [Olhar o quadro]**, "Então eu vou." included
  (`g_…`, and the left crop of `h_…`). This is the beat's face held to the talk's end, the 2026-10-16 fix for
  `bugs/look-at-the-painting-turns-ivo-the-way-he-already-faces`. "Ancião (atrás dele)" fits the script. Whether Ivo should turn
  back for "Eu também paro…" or "Onde fica?" is the user's call. In the [Esperar] branch he faces the elder throughout (middle crop).
- **Ivo's hair runs under the box's bottom edge:** his head top is at window y 312, the box border ends at 327, so about 4 art px
  are hidden (`h_ivo_hair_under_box_edge.png`). This also happens before the choice (right crop, line 3), so it predates STORY-41.
  It is a small loss, and the face stays visible.
- "Ele sempre para aí." starts as the zoom-4 hold ends, and the camera eases back to the talk frame while it types. At zoom 2 the
  painting (world y 170-196) is under the box. The girl's "aí" is therefore said over a frame without the painting, right after the
  close-up. The brief describes exactly this (hold ~1.6 s, then the girl). The roteiro's "a câmera vai até o quadro e fica nele" could
  also be read as the camera staying for her line. This is a staging question, not a defect.

### What the screenshots cannot tell

- Whether a 1.6 s hold is long enough to take the picture in. That depends on the art reading at all, which it does not yet.
- The feel of the zoom eases.
- The bolt's sound.
- The pacing at a player's own reading speed. The driver reads 1.2 s after each line finishes typing.

## Gotchas / pitfalls

- `talk_reader_driver.gd` always answers choice 0. For the second choice, a scratch copy that taps Down before Z worked
  (`focus=Choice1` logged on the Z). Consider adding a `CHOICE` env to the driver itself.
- Ivo's position changes during the LET branch, so the talk frame changes with it. Compare frames per branch.
