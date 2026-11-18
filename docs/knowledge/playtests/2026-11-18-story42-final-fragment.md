---
id: playtests/2026-11-18-story42-final-fragment
type: playtest
title: "STORY-42 - Ermo's final fragment: seven panels, captions in turns, the black seam into the restoration, skip, notebook page"
status: active
build: 5a590d37 + uncommitted STORY-42 (final_fragment.tres 10:39, guardian_finale.gd 10:36, engraving shader/view/math 10:31-10:33, panel art 11:01-11:12; import 11:13; nothing in the area changed after it)
area_tested: "frost_edge/lighthouse_top: the final fragment by the FinalFragment trigger (pt_BR and en) and after a real bot victory (pt_BR); the handover to world_restoration; a skip from the pause menu; the notebook page"
tags: [story-42, final-fragment, ermo, cutscene, engraving, finale, notebook, playtest]
related: [architecture/story42-the-final-fragment, systems/cutscenes, systems/bearer-fragments, systems/guardians, systems/notebook, playtests/2026-11-01-grd06-restoration, playtests/2026-11-13-story04-bearer-fragments, bugs/the-final-fragment-opens-on-bare-wall-when-the-pair-stands-apart, bugs/the-pause-menus-intent-line-draws-over-an-engraving-caption]
created: 2026-11-18
updated: 2026-11-18
screenshots:
  - playtests/screenshots/2026-11-18-story42-final-fragment/p1_perennials.png
  - playtests/screenshots/2026-11-18-story42-final-fragment/p1_end_winter_figure_out_of_frame.png
  - playtests/screenshots/2026-11-18-story42-final-fragment/p2_lighthouse.png
  - playtests/screenshots/2026-11-18-story42-final-fragment/p3_flower.png
  - playtests/screenshots/2026-11-18-story42-final-fragment/p4_crack.png
  - playtests/screenshots/2026-11-18-story42-final-fragment/p4_crack_detail.png
  - playtests/screenshots/2026-11-18-story42-final-fragment/p5_roads_two_line_caption.png
  - playtests/screenshots/2026-11-18-story42-final-fragment/p5_trace_detail.png
  - playtests/screenshots/2026-11-18-story42-final-fragment/p6_grey.png
  - playtests/screenshots/2026-11-18-story42-final-fragment/p7_his_name_was_ermo.png
  - playtests/screenshots/2026-11-18-story42-final-fragment/en_captions_stacked.png
  - playtests/screenshots/2026-11-18-story42-final-fragment/handover_paper_black_restoration.png
  - playtests/screenshots/2026-11-18-story42-final-fragment/victory_to_fragment_pair_out_of_frame.png
  - playtests/screenshots/2026-11-18-story42-final-fragment/fallback_prelude_frames_bare_wall.png
  - playtests/screenshots/2026-11-18-story42-final-fragment/skip_menu_intent_over_caption.png
  - playtests/screenshots/2026-11-18-story42-final-fragment/notebook_ermo.png
  - playtests/screenshots/2026-11-18-story42-final-fragment/victory_path_after_restoration_quill.png
  - playtests/screenshots/2026-11-18-story42-final-fragment/r2_opening_frames_the_mentor.png
  - playtests/screenshots/2026-11-18-story42-final-fragment/r2_p1_ends_on_winter_figure.png
  - playtests/screenshots/2026-11-18-story42-final-fragment/r2_p7_his_name_was_ermo.png
---

# STORY-42: the final fragment (Ermo's story)

**Verdict:** works end to end on both paths. After a real bot victory and through the replay trigger, the fragment
plays seven readable panels in order, hands over through black to `world_restoration` (which plays as before), a skip
lands on the restoration, and the notebook gains "Ermo". There are two defects (bugs filed) and three pacing and
framing notes.

Ratings: fun n/a (a cutscene). Fluidity **3/5**: the caption pacing is uneven, and that is inferred from measured
on-screen times, not felt. Aesthetics **4/5**: the panels are strong and the inks read at once. Both are
low-confidence for "feel"; a human should watch it once with sound.

## Setup

- **Probe:** a scratch `-s` driver around the runner, `pt42ff/probe.gd`. It prints a line on every change of the
  playing scene id, the `EngravingView` panel (by texture), caption turn and text, caption alpha, `Fade` alpha and
  colour, `LifeHud` alpha, the letterbox, and the camera. At each panel change it prints a `[panel]` summary: pan
  window first and last, distinct `tremble_step` values, and `hframes` cells seen. It takes a shot every 1 s, one
  0.75 s after each caption turn, and one 1.7 s after each panel starts. In the handover it shoots every 0.1 s, and
  in the tremble/trace windows (`BURST=1`) every 0.04 s.
- **Replay path:** seed `world_restored`, the four restored, `scenes_seen: ["mentor_wakes"]`, and spawn at the hatch
  (12048, -1254). `Triggers/FinalFragment` armed on the first tick and played at t 0.81. Run `pt` (pt_BR, ending with
  the notebook), run `en` (English with bursts), run `skip` (pt_BR, Escape / Down / Z at t 30).
- **Victory path:** `guardian_fight_bot_driver.gd` on `guardian_bot_mentor.json` (pt_BR, BOT_GOD=1,
  BOT_RESTORED_MS=95000). RESTORED at bot t 68.8, then the fragment, the restoration, the quill and the post-victory
  talk.
- `APPDATA` was redirected per run and the probe aborts unless `OS.get_user_data_dir()` is the scratch dir. No
  player save was touched.

## Timeline measured (replay path, pt_BR)

| Beat | t (s) |
|---|---|
| Scene starts; bars open and the camera zooms to 2 (1 s) | 0.81-1.71 |
| Life notes fade out (still on the lantern) | 0.87-2.23 |
| Fade to paper (bars included) | 2.99-4.14 |
| Panels 1-7 begin | 4.19, 13.18, 22.18, 31.19, 38.20, 47.20, 54.22 |
| Panel 7 clears to paper | 64.7-66.2 |
| Paper to black | 66.27-67.00 |
| `world_restoration` begins (black) | 67.04 |
| Life notes fade back in, **on the black** | 67.1-68.5 |
| Restoration fades in on the placed pair | 68.3-69.4 |
| Restoration ends | 81.22 (14.2 s, as GRD-06) |

The fragment lasts 66.2 s. From victory to control it is ~80 s plus the talk. On the victory path the fragment
started on the RESTORED frame, and the restoration followed about 66 s later. The panel lengths and pans in `[panel]`
match the `.tres` exactly (9/9/9/7/9/7/10.5 s, plus the 1.5 s clear on 7).

## Checks

1. **Panels between the bars, pan inside the art: pass.** All seven pans stay inside their 384x176 canvases (windows
   logged, `src` overlay drawn). Every panel reads clearly at 2x. Framing notes:
   - Panel 1 pans from x 0 to 64, so the **blue winter Perennial (him) slides out of frame** during the second
     caption ("Cada um lembrava uma estação..."). The panel ends on the fourth figure cut by the right edge
     (`p1_end_winter_figure_out_of_frame.png`). Reversing the pan (64 to 0) would end on him.
   - Panel 2's window never shows the lamp's right 32 art px (pan x fixed at 32). The rising pan reveals the figure
     with the raised hand well.
   - Panel 3 starts with the top of his hair at the bar. Panel 4 ends with the mask's top at the bar. Both are fine:
     the crack is the subject.
2. **Captions fit and read in order, "Seu nome era Ermo." alone last: pass.** All 13 turns fit in both languages.
   Only 5_1 takes two lines in pt_BR. In English, 1_2 and 5_1 take two lines, and 1_2 leaves the single word
   "back." alone on line 2 (`en_captions_stacked.png`). Order is 1_1 to 7_3, and 7_3 is the only text in its turn.
3. **Inks: pass.**
   - Panels 1, 3, 4, 5 and 7 show winter blue and flower pink where the plan puts them. Panel 2 is all blue, panel 6
     has no ink.
   - Panel 4's crack trembles: 71 distinct `tremble_step` values in 7 s (10 Hz), and a ~7.8k-pixel change confined
     to the crack between frames with no pan step. The crack is a 1-art-px speckled blue/pink/grey line: subtle, but
     it reads as unstable (`p4_crack_detail.png`).
   - Panel 5's trace cycles all 4 cells at 2 fps (cells 0-3 seen 354-450 frames each). It reads as a speckled dashed
     path marching across the valley (`p5_trace_detail.png`). It runs along a road across the threads rather than
     along a thread.
4. **Life notes hidden during it and back after: pass, with a note.** They fade out over the lantern before the paper
   comes in. They fade back in at the fragment's end, so they come back **on the black** between the two scenes
   (67.1-68.5) and stay through the restoration, as before STORY-42. Not filed: a minor polish point. Holding them
   until the restoration ends would keep the seam clean.
5. **Handover: pass.** Paper, then black (0.8 s), ~1.3 s of solid black, then the restoration's 1.2 s fade-in on the
   placed pair. No frame of the lantern shows between the scenes, and there is no double fade. The restoration then
   plays as in GRD-06: pull back to zoom 0.5, the lamp lights, back on the two (`handover_paper_black_restoration.png`).
6. **Skip mid-fragment: pass.** Skip from the pause menu on panel 3: the next frame is black, then the restoration
   plays whole (31.59 to 45.77). The engraving goes straight to black, a cut rather than a fade, which suits a skip.
   **Defect:** with the menu open, its intent line "Para casa." draws over the caption in the bottom bar
   (`skip_menu_intent_over_caption.png`; bugs/the-pause-menus-intent-line-draws-over-an-engraving-caption).
7. **Notebook page: pass.** After both the full run and the skip, opening the notebook lands on Memories, `Ermo`,
   unread, with "Ele segurou o inverno pra uma flor esperar. Eu conheço essa mão." and the flute cell
   (`notebook_ermo.png`). On the victory path the quill shows right after the restoration ends. At this size the
   flute cell reads as a small bundle more than as a flute.

## Defects

- **The opening frames bare wall** (medium): bugs/the-final-fragment-opens-on-bare-wall-when-the-pair-stands-apart.
  The camera centres on the pair's midpoint at zoom 2 (320 px wide). After the bot's victory they stood 465 px apart,
  and on the replay 448 px, so neither figure is on screen for the ~2.2 s before the paper. The last image of the
  final battle is an empty wall (`victory_to_fragment_pair_out_of_frame.png`).
- **Pause intent over the caption** (low): bugs/the-pause-menus-intent-line-draws-over-an-engraving-caption. It
  affects every captioned engraving scene, so bearer fragments are likely affected too (not re-run).

## Pacing (inferred from logged on-screen times; needs a human watch)

- **~66 s is not too long for a once-per-game reveal.** The weak spot is the distribution. Turns split a panel into
  equal shares, so each turn is visible ~3.8 s (panels 1-3, 5) or ~2.95 s (panel 7), whatever its length.
- **Panel 5's first turn rushes:** 120 characters (pt_BR; 115 en) in ~3.8 s is ~31 characters/s, about twice a
  comfortable subtitle rate. Others are fast too: 3_1 at 21 cps, 1_2 at 20 cps (24 in English), 7_2 at 21 cps
  (25 in English).
- **Short lines linger:** 5_2 "Por onde passava, as coisas paravam." gets the same 3.8 s (9.5 cps).
- **The name, the payoff, gets the least time:** "Seu nome era Ermo." is visible ~2.95 s, then the panel clears
  1.5 s and goes black. Suggest weighting turn shares by text length, or making panel 5 ~11-12 s, and holding the
  name longer (for example a 4-5 s last turn, or the caption kept through the clear).
- Between turns the bar is empty for ~0.5 s, and at each dissolve ~1.1 s. The rhythm is calm and even. Panels 4 and
  6 (single 7 s captions) feel the best-paced on paper: about 5.8 s for ~70-80 characters.

## What the screenshots cannot show

Audio was not measured. The silence cue, his phrase on panel 2, the broken phrase on panel 4, and the release of the
200 BPM fight loop at the victory are all untested. Run `audio_fight_driver.gd` or `audio_probe.gd` for those.
Whether 2 fps reads as "running" for the trace, and whether a 1-art-px 10 Hz tremble reads as unstable rather than as
a rendering glitch, are motion judgments: the frames show that both move, not how that feels.

## Harness notes

- A probe around the runner that reads `EngravingView.sprites()`, `_turn`, `caption_label()` and `elapsed()` gives
  every panel's real start, pan window and caption visibility in one log. `[panel]` summaries made the pan check a
  table instead of a flipbook.
- On the victory path, `BOT_RESTORED_MS=95000` keeps the bot's 0.7 s shots running through the fragment and the
  restoration (152 shots).

## Round 2 (2026-11-18, final_fragment.tres 11:34)

The coordinator changed only `final_fragment.tres`, uncommitted:
- the opening camera targets `[mentor]` (zoom 2);
- panel 1 pans (64,16) to (0,16);
- panel 5 lasts 12 s and panel 7 12.5 s.

No other file in the area changed after the 11:13 import. I re-ran the replay-trigger path once in pt_BR (`pt2`, same
probe and seed); the victory bot was not re-run.

- **Opening: fixed.** The frame settles on the mentor at (11600, -1304), zoom 2, and he stands whole and centred
  through the hold until the paper (`r2_opening_frames_the_mentor.png`). Ivo is off frame, by design.
  bugs/the-final-fragment-opens-on-bare-wall-when-the-pair-stands-apart is fixed for this path. The victory path frames
  the same target, so it should hold whatever the distance, but that path was not re-run.
- **Panel 1: fixed.** The window runs (64,16) to (0,16), and the panel ends with the blue winter Perennial whole at the
  left (`r2_p1_ends_on_winter_figure.png`).
- **Panel 5:** each turn is visible ~5.28 s (was 3.78). 5_1 (120 characters) drops to ~22.7 characters/s (was 31.7).
  That is readable but still the fastest caption; panels 1_2 and 3_1 are at 20-21. 5_2 is on for 5.29 s (6.8 cps). The
  equal-share split remains, so the short line now lingers longer.
- **The name:** "Seu nome era Ermo." is visible ~3.63 s (was 2.95), then the 1.5 s clear. The other panel 7 turns are ~3.62 s
  (13.5 and 16.9 cps).
- **Nothing else changed:**
  - Panels 2, 3, 4 and 6 have the same lengths and windows. The tremble shows 71 steps, and the trace cycles all 4 cells.
  - Caption turns 1-4 and 6 have the same visible times as round 1.
  - The fragment now runs 71.2 s (t 0.77-72.01; was 66.2).
  - The handover is the same: paper, black at ~71.9, solid black, restoration fade-in ~73.6-74.3. No lantern frame shows.
  - The restoration ends at 86.20 (14.2 s).
  - The notebook opens on `lore_final_fragment`.
- **Still open:**
  - the pause intent over the caption (not re-tested; the `.tres` change does not touch it);
  - the life notes returning on the black;
  - EN "back." alone on its line (not re-run in EN).
