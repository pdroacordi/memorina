---
id: architecture/ivo-at-2x
type: architecture
title: Ivo at 2x - one 128 px frame, frames chosen from PixelLab's returned frames, body unchanged, reach shrunk to the art
status: active
tags: [ivo, art, animation, pixellab, sprite, collision, jump-reach]
related: [systems/animation, systems/art-pipeline, systems/props, gotchas/sprite-frame-out-of-bounds-on-clip-switch, gotchas/animationtree-reset-track-overwrites-script-writes, gotchas/zigzag-ledges-two-rows-apart-seal-a-shaft, bugs/off-centre-sprite-sheet-jumps-on-flip, architecture/room-reachability-audit]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - scenes/characters/ivo/ivo.tscn
  - tools/art/cut_inhabitant.py
  - tools/art/cut_props.py
  - tools/pixellab/pixellab.ps1
  - tools/art/art_prompt.gd
  - tests/scenes/characters/ivo/ivo_sheet_test.gd
---

# Ivo at 2x (BUILT, CORE-08)

## Context

User, 2026-10-10: "Redraw at 2x, ~52 px (Recommended)", then "Yes, the taller one (Recommended)": 29 art px (58 px) tall, 13 art px wide idle, the villagers' scale. Approved still `tools/art/sources/ivo/ivo_still_2x.png` (26x58, ours; source `ivo_lineup_codex.png`). Ivo: "thick forearms that kind of outstands; long, prince charming-like hair (with nice animations for it); long sleeved shirt (as a meideval farmer would use) and the sleeves rolled up to see the forearms. Maybe a scarf like the traditional gaucho culture", then "not that long hair. More prince-charming-like", scarf mid blue. The ZeggyGames sheets are replaced, never uploaded or traced. Roadmap: "body shrunk to match, jumps still clear the same gaps".

PixelLab `animate3`: the first frame is our still, whose canvas is the output size (max 256); `frame_count` even, 4-16; returns frames 0..N, N repeating 0.

## Options considered

- **Frame size.** 96 px body clips plus 128 px attacks (today) needs a per-clip `Sprite2D:offset` key. **One 128x128 frame (64 art px) for every sheet**, floor line at row 96, body centre column 64, keeps `Sprite2D.position (0, -32)`: 96 px above the feet for swings and climbing arms, 32 below for the pogo blade. Chosen.
- **Odd counts.** Re-timing keys or dropping frames changes feel. **Choosing the kept range** reaches every count 3-16 with keys unchanged: a loop keeps 0..N-1; a one-shot that returns to its first pose keeps 1..N-1 (odd) or 1..N (even, ends on that pose). Chosen; no clip length changes.
- **Hair.** An overlay needs per-frame head anchors and twice the generation, and `Character.silhouette()` (Sombra's copy) would miss it. Baked per clip, chosen.
- **Body.** The art (58) is taller than the capsule (54); growing it costs 4 px of headroom on every authored jump. **Capsule unchanged** (radius 11, height 54; hair is not body), centred at x 0 (was -1). Chosen, pending the user.

## Decision

| Sheet `ivo_<id>.png` | Clips (frame keys) | Count | N, kept | First frame |
|---|---|---|---|---|
| idle | idle, memorina_draw 0-2, memorina_idle | 10 | 10, 0-9 | still |
| run | run | 8 | 8, 0-7 | still |
| push | brace | 10 | 10, 0-9 | still |
| climb | climb, climb_hold | 4 | 4, 0-3 | pose: climbing |
| climb_back | climb_back, climb_back_hold | 4 | 4, 0-3 | pose: back view |
| sit | sit | 10 | 10, 0-9 | pose: seated |
| jump | jump_start 0-2, jump_idle 2, fall_start 3-5, fall_idle 5 | 6 | 8, 1-6 | still |
| air_spin | air_spin | 6 | 6, 0-5 | cut jump frame 2 |
| land | land (0.75 s = `hard_land_time`) | 9 | 10, 1-9 | still |
| wall_land | wall_landing | 6 | 6, 1-6 | pose: wall cling |
| wall_slide | wall_slide | 1 | no call | pose: wall cling |
| roll | roll (0.583 s, asserted) | 7 | 8, 1-7 | still |
| hurt | hurt | 4 | 4, 1-4 | still |
| death | death (`death_shown` at its end) | 10 | pilot | still, else pose: lying |
| attack_ground | attack_idle_1 0-4, attack_idle_2 5-8 | 9 | 10, 1-9 | pose: guard |
| attack_run | attack_run_1 0-4, attack_run_2 5-8 | 9 | 10, 1-9 | pose: guard |
| attack_air | attack_jump, attack_fall | 4 | 4, 1-4 | pose: air guard |
| attack_down | attack_pogo | 6 | 6, 1-6 | pose: air guard |

Clip lengths, steps and the hitbox/hurtbox keys (seconds) stay. Jump and fall attacks share a sheet (same hitbox today). Death: "staggers, falls and lies still", N=10, keep 1-10; if frame 10 drifts back toward standing, generate from a lying pose ("pushes up and collapses again", N=16) and keep the collapse.

**Hair and scarf** get a secondary-motion clause in every `action` (idle "stir with each breath", run "bounce and stream back", roll and air_spin "whip round", hurt "snap forward"). Two re-rolls of a dead-haired idle or run before reconsidering an overlay.

**Nodes.** Sprite2D position, sensors, `GreyhushShield`, `RecallAura`, `top_hop_height` and the camera (`body_rect()`) stay. Hurtbox stays r 8 h 44, inside the body. Hitboxes keep today's geometry. Tracks ordered texture, hframes, frame. Art faces east (`flip_h = facing < 0`), unlike the props.

## Build order

1. Contracts `tools/art/prompts/ivo_<id>.md` (`command: animate3`, `size: 128x128`, `direction: east`, `reference`, `action`, a new `keep: a-b` that `art_prompt_test` checks); placeholders.
2. One Codex pose sheet beside the standing still as scale figure (seated, wall cling, climbing, back view, lying, guard, air guard), cut by `cut_props.py --ref-height=29`, framed on the 128 canvas.
3. Pilot: idle at 128. If the figure degrades, body clips generate at 96 and the cutter pads (+1 call).
4. The other clips; chained first frames come from cut sheets.
5. `cut_inhabitant.py` gains `--keep=a-b`; always snap to `ivo_still_2x.png`'s colours.
6. Re-key `ivo.tscn`; delete old sheets from the FileSystem dock; CREDITS.md drops ZeggyGames for Ivo.

**Calls:** 17 clips, plus 2 fallbacks, before re-rolls; about 40% re-rolled (attacks, roll, death, climbs): **about 25 (18-30)**. Codex: 1-2.

## Consequences (tests)

- `ivo_sheet_test`: every sheet hframes x 128 by 128; no frame key at or past hframes; hframes before frame; clip lengths pinned.
- Grounded clips: lowest opaque art row 47 in every frame. Air clips: centroid within 1 art px of column 32. No frame touches its border; colours within the still's.
- `_assert_clip_durations` also pins land to `hard_land_time`.
- Capsule: `ceil(height / 32) == 2`; `MapGuide.ivo_reach()` peak and gap pinned to today's numbers.
- Smoke, and a playtest: hair reads in run and jump; its tip is not greyed at the shield's edge.

## Revision (2026-10-11, CORE-08 built)

The user's decisions, in their words: "Redraw at 2x, ~52 px (Recommended)" (2026-10-10); the design "Yes, the taller one (Recommended)" (2026-10-11), 29 art px tall; the pipes on his back "Remove them (Recommended)" (2026-10-11), already gone from `ivo_still_2x.png`; the weapon "His short sword, drawn to swing (Recommended)" (2026-10-11), in its scabbard at his hip except in attacks; the sword's reach "Shrink to the art" (2026-10-11); the idle pilot "Yes, do the rest (Recommended)" (2026-10-11); the PixelLab spend "Go ahead (Recommended)" (2026-10-11), up to 30 animate3 calls. The capsule stays radius 11, height 54 (this plan's call), now centred at x 0.

What changed from the decision above, and why:

- **Canvas.** At 128 px PixelLab lost his face (the pilot); at 64 px it held his profile. Clips are generated on the tightest canvas that holds the motion and padded into the 128 frame by `cut_inhabitant.py --frame=128 --at=x,y`: 64 px for idle, run, push, sit, jump, land and hurt; 80 px for climb, climb_back, wall_land and air_spin (the climbing and clinging poses are 62-70 px tall); 96 px for roll, death and the attacks. The approved idle pilot is re-framed (`--strip=64`), not regenerated.
- **`keep` lists frames**, not only a range: `5-10,9-6` plays the braced frames of `push` forward and back (frames 1-4 only lean in from the still); `0-4,6-9` builds the two-swing sheets from one generation; `6-6,0-4` puts the pogo stab (generated 2-3) on the clip's hit window (frames 3-4). `ArtPrompt.keep` holds the list; `art_prompt_test` checks it has exactly `frames` entries.
- **Frame N does not always repeat frame 0.** The death clip (N=16 from the still, on 96 px) ends lying still; frames 6-15 keep the stagger, the fall and the rest. `wall_land` ends crouched on the wall, so `wall_slide` is its last frame rather than the Codex cling pose, and the slide follows the landing without a pop.
- **Chained first frames.** The roll from the standing still came back as a lunge; the re-roll starts from the land clip's deep crouch. The air spin starts from the jump's top (generated frame 3 of `ivo_jump`). The attacks start from the Codex guard (`ivo_first_guard_left_96.png`, 16 px from the left so the swing has room) and air guard.
- **Wall clips face the wall** (a slide starts while pushing into it) and put his front on the capsule's edge, column 75, instead of centring; `ivo_sheet_test` checks that edge and exempts them from the centring test.
- **Palette.** The still has no steel, so a blade snapped to it turned cream; every sheet snaps to `tools/art/sources/ivo/ivo_palette.png`, the still's 23 colours plus three steel greys. Two blades of the Codex poses were repainted steel after the reduction (a thin blade's blocks take the magenta fringe).
- **Hitboxes shrink to the art** ("Shrink to the art", user, 2026-10-11), replacing "Hitboxes keep today's geometry". Each attack keys the capsule's position and scale at 0 to the box its hit-window frames cover (steel, slash trails, and anything past the body's front), the front clipped at the body centre where an arc passes over his head. Body px, x forward, y up negative:

| Clip | Template: x, y | 2x art (fourth round, key poses and smears): x, y | Forward reach |
|---|---|---|---|
| attack_idle_1 | 4.6..75.4, -84..28 | 0..48, -66..-14 | 75 -> 48 (the slash's leading and trailing smears) |
| attack_idle_2 | 2.2..73.8, -92..20 | 0..40, -62..0 | 74 -> 40 (the chop's smears, down to the floor) |
| attack_run_1 | -6..68, -75..5 | 0..40, -72..-34 | 68 -> 40 |
| attack_run_2 | 10..70, -71..11 | 2..40, -60..-6 | 70 -> 40 |
| attack_jump | 23.3..56.7, -83..-1 | 0..38, -60..-24 | 57 -> 38 |
| attack_fall | 28.3..51.7, -83..-1 | 0..38, -60..-24 | 52 -> 38 |
| attack_pogo | -44..62, -44..36 | -10..8, 0..22 | depth below the feet 36 -> 22, width 106 -> 18 |

  The air slash's arc sweeps under and behind him, so its box now reaches behind too. Enemies and guardians were tuned against the old reach; CORE-09 (2026-10-11) retuned them as data without touching these boxes: the brute parks at 48 px and winds up for 0.5 s, swing 1 shoves at 60 px/s, the guardians' comfort distances and the boxes that could not reach a grounded Ivo changed (`systems/guardians`, "Reach against Ivo's sword"; `combat_reach_test`).
- **Run and push redone** after "I find that some animation that should be improved of Ivo are his pushing and his running. His running seems only like a walk." (user, 2026-10-11). Three run takes from standing or striding poses kept both feet down, however the action was worded. The fourth starts from a stride lifted 4 px off the floor, and it runs: forward lean, knees high, fists pumping, with `run` still 8 frames at 1/12 s. Its flight frames were later settled onto the floor line (third round, below). The push leans into a wall at about 30 degrees with both hands flat at chest height and the legs driving (`keep: 3-10,9-8`, placed 2 px back so the lean stays on the axis). `brace` plays when he walks into a wind that pushes back (`Player.is_bracing`); there is no wall, so the flat hands read as pushing against the wind.
- **Third round** (user, 2026-10-11, verbatim): "The jumping and falling animation could be improved. The attacking animation is weird as well. ... Many things on the game seem to just be flaoting. ivo while running doesn't touch the ground." What was weird about the attack, in the user's choices: "The swing itself", "Too short/weak", "Sliding or popping". PixelLab: "Approve 15 more (Recommended)".
  - **Feet on the floor.** `cut_inhabitant.py --floor=95` moves each frame so its lowest pixel sits on the floor line. The run and the roll use it, so the run's feet never leave the floor, and the run is back under the floor-line test.
  - **No sliding.** `--centre=TOP-BOTTOM` moves each frame sideways until the body's non-steel centroid in that band sits on the axis: the feet (rows 80-95) for ground attacks, head and torso (rows 40-69) for air attacks, and the whole frame for the jump. `ivo_sheet_test` adds a steadiness check: an attack's body moves at most 2 art px between two frames.
  - **Jump and fall.** The jump is redrawn on an 80 px canvas: anticipation crouch, take-off with legs extended, a rise, and an open-limbed fall with hair and scarf lifted (`keep: 2-6,5-5`). Every frame is settled on the floor line and the axis.
  - **Attacks.** All four are redrawn from guard poses whose sword was repainted by hand as a long, two-pixel steel blade (`ivo_first_guard_long_96.png`, `ivo_first_air_guard_long_96.png`; removed with their PixelLab frames when the fourth round replaced them), with beat-by-beat prompts. The ground combo is a thrust and then an overhead chop (one retake). The running slash is a wind-up thrust and then a white backhand slash. The air slash sweeps an arc. The pogo stab points the blade straight down through the hit window.
  - **Thin blades survive the cut.** A 2x2 block that is half pale steel is kept, so a 1 px blade or trail survives halving. A white (234, 240, 240) joins `ivo_palette.png` so slash trails read against light backgrounds.
  - **Hitboxes** follow the new steel (table above), the front clipped at the body where the steel sweeps behind his head. The finisher's overhead chop reaches only 33 px forward, but from head height to the floor.
- **Fourth round: attacks from key poses** (user, 2026-10-11, verbatim): "The attack animation still very strange. Not good, not fluid, doesn't even seem like an attack. The running attack is weird too, because the character is moving, but it's legs aren't". The PixelLab in-betweens came back stiff, holding the sword out for six frames, so the attacks are now built the classic way by `tools/art/build_ivo_attacks.py`.
  - **Key poses.** Two Codex sheets, drawn beside the approved still (`ivo_attack_poses_ground_codex.png`, `ivo_attack_poses_air_codex.png`), give eleven stills, cut by `cut_props.py --ref-height=29 --colors=48 --merge=8` into `tools/art/sources/ivo/attack_poses/` and snapped to the palette. Ground: slash wind-up, strike and follow-through; chop wind-up, strike and follow-through. Air: wind-up, strike and follow-through; pogo raise and stab. The blades of `air_strike` and `pogo_stab` were repainted steel where the cut turned them cream.
  - **Smears.** A smear frame is the strike pose with its blade erased and a crescent drawn by the tool along the swing's path: pale steel inside and white outside, thickest late in the swing, tapering at both ends. The pogo's smear is a short vertical streak.
  - **Timing by holds** within each clip's frames at 1/12 s, so no length changes. Swing 1 (5 frames): wind-up held 2, strike, smear, follow-through. Swing 2 (4 frames): wind-up, strike, smear, follow-through. Air slash (4): wind-up, strike, smear, follow-through. Pogo (6): raise held 2, stab, smear, stab, raise.
  - **Hit windows** now cover the strike and smear frames: 0.167-0.333 s on swing 1 and the first running swing, 0.083-0.25 s on swing 2, the second running swing and the air slash, 0.167-0.417 s on the pogo. The Hitbox is keyed to the steel and smear in those frames (table above). The pogo box only reaches below his boots.
  - **The running attack runs.** `Player.move_axis` keeps the input during a running attack, so he moves; a standing attack zeroes it, so he stands. Each running-attack frame keeps the attack pose above the hips, moved so its torso rides the run frame's torso, over the legs of run frames 0-7 and then 0. `ivo_sheet_test` checks the running attacks' steadiness on the upper body, because the legs keep the run's stride.
  - Every pose's feet sit on row 95 and its body on the flip axis (the feet for ground poses, head and torso for air poses).
- **Fifth round: the standing combo's swish and flow** (user, 2026-10-11, verbatim): "The attacks are mostly fine, just need to improve the swish from the standing attack the flowness." The running attack, the air slash and the pogo are unchanged.
  - **Swing 1** (5 frames). Wind-up; the wind-up body with its blade replaced by a thin rising smear over the head (the in-between); the strike with a thin, bright leading smear on the arc's front half; the follow-through with the whole sweep trailing behind the blade, white near it and pale steel further back, with a 1 art px darker inner edge; then the guard pose, easing back.
  - **Swing 2** (4 frames). The chop's wind-up, rising from that guard; the chop with its leading smear; the follow-through with the trailing sweep down to the floor; the guard.
  - Each arc is pivoted on the shoulder of the pose it is drawn on, so it follows the blade's path from wind-up to follow-through. The leading and trailing smears keep the blade and paint only behind the body.
  - The hit windows are unchanged (strike and smear frames). The boxes follow the new smears: slash 0..48, -66..-14; chop 0..40, -62..0 (table above). The guard pose is the first pose sheet's guard with its long repainted blade (`attack_poses/guard.png`).
- **Flip axis and attack bodies** (CORE-08 review, 2026-10-11). `Sprite2D` is centred, so a 128 px frame mirrors about column 63.5, not 64. The attack sheets were placed by the guard pose's bounding box, which left the body 3-5 px behind the axis (feet centroids -3.1..-3.5 px on the ground swings against idle's -0.6), so the body hopped at each swing's start and end. The attack sheets now sit 4 px further forward (ground, air slash, pogo) or 2 px (running slash), the roll 2 px back and the air spin 2 px forward, and every Hitbox key moved with its sheet, so each hit window still covers the steel. `ivo_sheet_test` centres every clip on 63.5: body clips by their whole-frame centroid, ground attacks by the feet (rows 80-95) and air attacks by the head and torso (rows 40-69), leaving the steel out.
- **Two counts in a contract.** `frames:` is the sheet; `generate:` is PixelLab's frame_count (even, 4..16, reaching every kept index), which `pixellab.ps1 -Prompt` sends. `ivo_wall_slide` is `command: cut` with `cut_from: ivo_wall_land`: it has no generation, and `-Prompt` refuses it (`bugs/an-ivo-contract-run-through-pixellab-prompt-requests-the-sheet-count`).
- **Calls.** PixelLab: 31 animate3 generations of the 45 the user approved; none in the fourth round (30, then "Approve 15 more (Recommended)", 2026-10-11). The first pass was 21 (one per clip, plus re-rolls: run once, roll once, attack_ground twice, attack_run once). The run/push redo added four: run twice, push once, and one hurt take that still turned toward the camera and was not kept. The third round added six: jump, ground combo twice, running slash, air slash, pogo. Two more calls failed locally before reaching the API (a missing reference). Codex: 3 images (the pose sheet, `ivo_poses_codex.png`, and the two attack key-pose sheets of the fourth round). The hurt flinch keeps its three-quarter turn for two frames.
- **Tests** as listed above, in `tests/scenes/characters/ivo/ivo_sheet_test.gd`; the centring test reads each frame's opaque centroid within 2 art px of the flip axis, column 63.5 (a bounding box swings with an outflung arm). `Player._assert_clip_durations` also pins `land` to `hard_land_time`.
