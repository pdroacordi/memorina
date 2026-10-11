---
id: architecture/ivo-at-2x
type: architecture
title: Ivo at 2x - one 128 px frame, frames chosen from PixelLab's closed loops, body and reach unchanged
status: proposed
tags: [ivo, art, animation, pixellab, sprite, collision, jump-reach]
related: [systems/animation, systems/art-pipeline, systems/props, gotchas/sprite-frame-out-of-bounds-on-clip-switch, gotchas/animationtree-reset-track-overwrites-script-writes, gotchas/zigzag-ledges-two-rows-apart-seal-a-shaft, bugs/off-centre-sprite-sheet-jumps-on-flip, architecture/room-reachability-audit]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - scenes/characters/ivo/ivo.tscn
  - tools/art/cut_inhabitant.py
  - tools/art/cut_props.py
  - tools/pixellab/pixellab.ps1
---

# Ivo at 2x (PROPOSED, CORE-08)

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
