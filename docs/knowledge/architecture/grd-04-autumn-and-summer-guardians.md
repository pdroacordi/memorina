---
id: architecture/grd-04-autumn-and-summer-guardians
type: architecture
title: GRD-04 plan - the bone scarecrow (autumn, recalls WALL_CLIMB with a floor gust escaped up a wall) and the sun-lion (summer, no recall) as scene + GuardianStats; a move that carries Ivo (GuardianGust) and a wall-cued recall
status: accepted
tags: [grd-04, guardian, plan, recall, wall-climb, gust, quadruped, art, pixellab]
related: [systems/guardians, architecture/guardian-performance-and-talks, architecture/guardian-fight-phase-machine, architecture/room-reachability-audit, systems/air, systems/dialogue, systems/notebook, systems/art-pipeline, gotchas/a-one-screen-shaft-cannot-shut-out-wall-climb, gotchas/physics-parent-before-children-one-frame-lag, gotchas/animationtree-reset-track-overwrites-script-writes, gotchas/a-centred-texture-rect-can-land-half-an-art-pixel-off-the-grid, gotchas/a-replaced-sheet-plays-the-old-import-until-reimported, bugs/recall-move-range-exceeds-hitbox-reach, bugs/the-frost-swipe-hit-ivo-far-from-its-fist, bugs/the-lucidity-leap-lands-outside-the-frame-so-its-land-clip-is-not-seen, bugs/the-first-guardian-talks-zoom-hides-the-guardian-behind-the-dialogue-box, bugs/the-orchard-arena-barrier-is-jumped-over-into-the-cliff-chimney]
created: 2026-10-30
updated: 2026-10-30
source_files:
  - scenes/characters/guardians/guardian.gd
  - scenes/characters/guardians/guardian_talks.gd
  - scenes/characters/ivo/player.gd
  - scenes/characters/ivo/abilities/ability_recall_component.gd
  - scenes/characters/ivo/abilities/wall_mobility_component.gd
  - resources/characters/guardians/guardian_attack.gd
  - resources/characters/guardians/ability_recall_stats.gd
  - scenes/world/interactables/fight_wall/fight_wall.gd
  - tests/scenes/combat/combat_reach_test.gd
---

# GRD-04 plan: the autumn and summer guardians

**Status: accepted** (2026-10-30). Roadmap GRD-04; contract `systems/guardians`, which this plan does not change except where it says so.

## User decisions (verbatim)

- Autumn (2026-10-30): "Espantalho de osso (Recommended)": a tall scarecrow of hollow bone and dry leaves that will not let its last leaves fall; its recall move a gust along the floor escaped only up a wall. It recalls WALL_CLIMB: "Autumn: wall climb; summer: none" (2026-10-08). Concept: "B, curvado, mais assustador. Porém mudar o rosto (que se parece demais com um cervo, a flor e a coroa que apenas parece um chifre)", redrawn with a round cracked bone mask, a stitched mouth and a hood of dry leaves; "Aprovar". Still `tools/art/sources/guardians/scarecrow_still.png`, 72x78 art px (hunched, arms to the ground, long leaf skirt).
- Summer (2026-10-30): "Leão-sol de pedra": a heavy lion of porous volcanic stone, mane and tail tuft of sun rays; "A, pesado (Recommended)". Still `tools/art/sources/guardians/sun_lion_still.png`, 99x64 art px, quadruped.
- "Como na folha (Recommended)" (scale as on the sheet). "Guardiões primeiro (Recommended)": built in today's flat 40-cell `orchard_arena` and `caldera_arena`; dressing (WORLD-16/17) later.
- Each gets the full GRD-07/08/STORY-18 set: idle, walk, 3 attacks, hurt, lucid, restored, leap (8 frames), lucid_enter, play_song, relapse, perform, perform_end, a portrait; a `GuardianVoice` with a bark per cure step and a retry, a first talk with one HOLD/LET gesture and a repeatable talk; notebook names and bodies; autumn teaches Soltar (`release.tres`), summer Sombra (`shadow.tres`).

## Context

- A guardian is a scene plus `GuardianStats`, never a subclass. Every clip, line and box below is data; the code changes are five small generic seams (section "Code").
- `release.tres` (id 4) and `shadow.tres` (id 2) are complete for a lesson: six notes, track, palette, pulse. Release has no `note_cues` (default cues, like `freeze.tres`). Neither arena has a `SongReceiver`, so the lesson's own pulse acts on nothing; Sombra's lesson leaves Ivo's burned shadow in the arena, which is harmless.
- Ivo enters the Orchard with DOUBLE_JUMP and ROOT (both from Bloom, design 04 section 2). His jump is 144 px, the double jump 270, so no floor move can be "escaped only up a wall" by height alone: it must be by duration.
- The recall today opens on a distance cue (`AbilityRecallStats.trigger_distance`) and is performed by the same press. A WALL_CLIMB recall needs Ivo at a wall, which nothing guarantees today (checked: `AbilityRecallComponent` and `Player._recall_cue_met` have no wall notion; `WallMobilityComponent` starts a slide only with the axis held into the wall).
- `orchard_arena.room`: floor top row 9, nine rows of air. East: col 39 rock from 96 px over the floor, the doorway under it held by a 3-cell `FightWall`; west: `FightWall` col 0 (4 cells), the chimney `FactBarrier` `X` at col 1 (3 cells, gone once `has_wall_climb` holds, live on `progress_changed`), the lintel at cols 0-2 rows 0-4. Its top opens into `orchard_crag`'s shaft (cols 31-38), whose lips stand 512 px up: today only wall climb reaches it.

## Decision

### 1. The moves

Shared timings (so the startup asserts hold: `lucid_enter` 0.6 <= `lucidity_delay` 1.0 - `leap_crouch` 0.3; `relapse` 0.75 <= 0.84): idle 6 f x 0.15 loop; walk 8 f x 0.125 loop; hurt 7 f x 1/12 (0.5833); lucid 6 f x 0.15 loop; restored 6 f x 0.1 loop; leap 8 f (crouch 0-1 0.3 s, rise 2-3, fall 4-5, land 6-7 0.3 s); lucid_enter 4 f x 0.15; play_song 6 f x 0.15 loop; relapse 5 f x 0.15; perform 8 f x 0.2 loop; perform_end 4 f x 0.2. Continuity frames as GRD-08 (`lucid_enter` ends on `lucid` f0, `relapse` on `idle` f0, `perform_end` on `restored` f0, the pipe leaving on its last frame).

**Autumn, the scarecrow** (light and tall: it hops; `resources/characters/guardians/autumn_guardian/`):

| Move (`.tres`) | clip | duration | telegraph | range / height | lunge / leap | contact | recall | window and box (world px, facing +x) |
|---|---|---|---|---|---|---|---|---|
| sweep `autumn_sweep` | attack_1, 12 f x 1/12 | 1.0 | 0.5 | 108 / 96 | - | yes | - | 0.333-0.583 (f4-6): rect x 16..118, y -36..0 (the twig claws raked along the floor); weight 1.5, cooldown 1.6, kb 380/120 |
| gust `autumn_gust` | attack_2, 12 f x 0.2 | 2.4 | 0.9 | 600 / 96 | - | yes | `recall_wall_climb` | push from 0 s (`push_speed` 1700); band 2.0-2.4 (f10-11): rect x 16..1296, y -32..0; weight 0, cooldown 2.4, kb 300/80 |
| hop `autumn_hop` | attack_3, 8 f x 0.1 | 0.8 | 0.5 | 260 / 96 | lunge 300, leap ~375 (airtime = clip; tune to the measured guardian gravity, bloom_pounce gives ~940 px/s2) | yes | - | 0.2-0.7 (f2-6): the stilt legs and claws per frame, inside the art; weight 1.0, cooldown 2.6, kb 420/200. A leap only has to touch |

Clips: idle, a hunched sway with the skirt rustling and one leaf caught back as it starts to fall; walk, a lurching drag, knuckles brushing the floor; sweep, one arm drawn back and raked low across the floor; gust, arms flung forward and the skirt flared, held in one long blow (the leaves streaming along the floor are `GustStream`, never painted into the body strip, `systems/art-pipeline`); hop, a crouch on the stilt legs, a leap with arms spread and claws down, a land; lucid, straighter, the mask tilted up, a leaf trembling at its fingers; restored, upright, letting one leaf drift down; play_song and perform, a pipe of hollow bone (the autumn pipe's material, design 02 section 7.1) at the stitched mouth.

**The gust is how WALL_CLIMB is recalled.** Telegraph: the skirt lifts. Swing: `GuardianGust` carries Ivo along the floor away from the scarecrow (ground drift (1700 - 90) x 0.4 = 644 px/s; airborne 1700), so he reaches the wall behind him (at most ~1190 px in this arena) in 1.85 s, before the band opens at 2.0 s. The recall opens on its new cue: Ivo's body touching a grippable wall (`wall_cue`). The world slows, the prompt is jump, and the press recalls and performs: it jumps (ground jump at the wall's foot, or the double jump if he was carried airborne), and for `RECALL_ESCAPE_TIME` the wall slide takes the escape axis (away from the scarecrow, into the wall), so he grips at the apex with nothing held and hangs above the 32 px band; more jumps climb. Both ends work: east the 3-cell `FightWall` plus col 39 rock is one face from the floor up; west the barrier `X` vanishes on the unlock and Ivo grips the 4-cell `FightWall` at col 0, whose top meets the lintel (128 px). `recall_wall_climb.tres`: skill WALL_CLIMB, action `&"jump"`, window 2.0, grace 1.0, grounded_steps 1, `wall_cue` true, trigger_distance 0, miss_damage 0 (a miss costs the band's hit, as the Frost charge's miss costs the charge). After the skill is held the gust stays in the cadence and is escaped the same way, now by choice.

Options weighed for the delivery: (a) carry Ivo with the move (chosen); (b) knockback: decays in 0.3 s and cannot cross an arena; (c) an `AirflowSource` registered with `Airflow`: scaled by the memory at the point (0.25 here, so a quarter of the push) and blocked by shelters, so the move would differ by place; (d) no delivery, the recall simply waiting for Ivo to reach a wall: the design's "unavoidable" trigger (02 section 4) would then depend on where he stood.

**Summer, the sun-lion** (heavy: no leap move, as Frost; `resources/characters/guardians/summer_guardian/`):

| Move | clip | duration | telegraph | range / height | lunge | contact | window and box |
|---|---|---|---|---|---|---|---|
| claw `summer_claw` | attack_1, 12 f x 1/12 | 1.0 | 0.55 | 118 / 96 | - | yes | 0.4167-0.5833 (f5-6): rect x 56..124, y -48..0 (forepaw raked low); weight 1.5, cooldown 1.7, kb 400/120 |
| charge `summer_charge` | attack_2, 14 f x 1/12 | 1.1667 | 0.8 | 300 / 96 | 420 px/s from `lunge_delay` 0.5 | **no** (GRD-10) | 0.5 to clip end: head and mane per frame, inside the art (x ~50..110, y -90..-10); weight 0.8, cooldown 2.4, kb 520/160 |
| sun roar `summer_roar` | attack_3, 14 f x 1/12 | 1.1667 | 0.6 | 96 / 150 | - | yes | 0.4167-0.8333: f5 forepaws raised (rect ~x 30..80, y -190..-110, keeps `attack_height` 150 honest), f6-9 paws slammed down (rect ~x 40..100, y -60..0); weight 1.0, cooldown 2.0, kb 460/180 |

Clips: idle, heavy breathing, the mane rays brightening on the beat by a palette lift (as Frost's crystals); walk, a heavy pad; claw, a forepaw raked forward low; charge, head lowered, mane flattened, a bounding run along the floor and a skid; roar, rearing onto the hind legs with the rays fanned open, then slamming down; lucid, head raised, eyes clear; restored, seated upright like a temple statue; play_song and perform, seated on its haunches with a pipe of porous volcanic stone held between its forepaws, in profile.

**Summer recalls nothing.** No attack has `recall`, so `Guardian._recall_still_needed()` is false and `GuardianFight.set_recall_pending(false)`: the `hits_to_open`th hit opens the window directly, nothing saturates and `request_recall()` never fires; `recall_after_attacks` 0 and all three moves are in the weighted roll. The fight is pressure, lucidity, relapse only, so `hits_to_open` is one higher than Frost's (9) to keep the pressure phase near the others' length.

Frame sizes (1 px per art px, `Sprite2D` scale (-2, 2), authored facing left, feet on the bottom row, the body centred on the flip axis):
- Scarecrow **128x112** (feet row 111, `Sprite2D` y -112): the 72x78 body leaves 64 art px each side for the claws, and a 2x reference is 256x224, inside PixelLab's 256 px limit, which kept the slender stag's profile (`systems/art-pipeline`). Flip axis: the skirt and torso's centre, not the reaching arms.
- Lion **192x96** (feet row 95, `Sprite2D` y -96): the flip axis is the torso's centre, midway between fore and hind legs; the head reaches ~66 world px forward and the tail ~132 back, so the body turns on its shoulders and the tail overhangs. 96 rows hold the rear-up. 2x would be 384 px: animated at 1x like Frost.

### 2. Shapes, spacing and what a quadruped breaks

| | Scarecrow | Lion |
|---|---|---|
| Body (`CollisionShape2D`) and `ContactHitbox` | capsule r18 h156 at (0, -78); contact reach 26 | **rectangle 132x72 at (0, -36)**; contact reach ~74 |
| Hurtbox | capsule r24 h156 at (0, -78) (skirt and torso, not the arms) | rectangle 140x100 at (0, -50) (torso, head, mane; symmetric because a hurtbox does not turn) |
| Ivo's longest swing on it (Bloom r18 gives 77.5) | ~83.5 | ~129.5 |
| `comfort_distance` / `give_ground_distance` | 88 / 50 | 134 / 96 |
| `GreyhushShield` | RECT 144x160 at (0, -80), feather 12 | RECT 264x136 at (0, -68), feather 12 (covers the tail on either facing) |
| `Talkable` reach / `height_cells` / `face_height` | 66 / 5 / 124 (a 156 px body, like Frost's case; confirm with STORY-19's check) | 114 / 4 / 0 (128 px drawn, like Bloom) |
| `BarkAnchor` (authored facing left, head) | (-28, -132) | (-52, -116) |
| `lucidity_leap_distance` / `lucidity_leap_margin` | 440 / 96 (defaults) | **360 / 144** |
| Locomotion `move_speed` | 70 | 84 |

Every distance above is the target the strips are drawn to; `combat_reach_test` is the judge (give-ground above contact, under the main move's range, under comfort; comfort outside Ivo's reach; every box inside the drawn art), and `attack_range` follows what the keyed boxes measure (`bugs/recall-move-range-exceeds-hitbox-reach`).

Stats: autumn `hits_to_open` 8, `cycles_to_restore` 3, `revealed_notes` 5, `recall_after_attacks` 2, `call_lead_in` 2.2, pace 0.8 / 0.55, `step_out_speed` 1.8. Summer `hits_to_open` 9, `cycles_to_restore` 3, `revealed_notes` 4, `recall_after_attacks` 0, `call_lead_in` 2.2, pace 1.0 / 0.45, `step_out_speed` 1.6. Fewer revealed notes for the greyer regions follows design 02 section 3 ("fragmentada/sugerida para os mais corrompidos"; Orchard 0.25, Caldera 0.15).

What assumes a tall biped, and the answer:
- `Guardian.body_height()` reads only a `CapsuleShape2D`; the lion's rectangle would answer 0. It becomes `body_rect().size.y` (identical for every capsule). A rectangle rather than a rotated capsule because `Character.body_rect()` ignores a shape node's rotation, and the arenas are flat.
- `overhead_band_for` uses the body's width: the lion's band is (132 + 22) / 2 = 77 px, so a pogo on its back is "on top" over its whole length, as it should be; the roar's height 150 covers its back.
- The leap framing puts a 440 px pair at screen x 100 / 540; the lion faces Ivo on landing, so its tail points out and would end at x 672. At 360 apart it ends at 632. The margin 144 keeps the tail out of the arena wall at the landing.
- The bark balloon goes on the side away from Ivo from a `Marker2D` that does not turn with the sprite; for a head 52 px forward the tail would point at the torso. `GuardianTalks` mirrors the anchor's x by facing before `say` (Bloom and Frost sit at x 0, so they are unchanged). The lion's box then sits over its own back; acceptable, but `bark_balloon_test` must keep it off the head.
- The `NoteSheet` slot: the scarecrow's 156 px body is past `CENTRE_CLEARANCE` (140), so the sheet stands aside, correctly; the lion's 72 px body rect and 128 px drawn height both centre it, as for the stag.
- Camera: `frame_pair` uses the feet; nothing else changes.

### 3. Code (five generic seams, no guardian subclass)

1. `GuardianAttack.push_speed` (px/s, 0 none, group "Gust"): the move carries Ivo while it swings.
2. `GuardianGust` (`scenes/characters/guardians/guardian_gust.gd`, Node, `process_physics_priority = -1` like `AirflowBody`, so the carry lands before Ivo moves): while the guardian's current move has `push_speed > 0` and is swinging, it calls `Player.push(Vector2(facing * push_speed, 0))` when Ivo is in front and his feet within `attack_height` of the guardian's. A velocity the air carries, never a force (`systems/air`); it uses no `Airflow` source (option c above). `GustStream` (Node2D sibling, script-owned, never keyed) draws a looping leaf-stream `SpriteStrip` tiled along the band while `GuardianGust.is_blowing()`, mirrored by facing, on the pausable scaled clock; it exposes `drawn_rect()` for the reach test.
3. `AbilityRecallStats.wall_cue: bool`; `WallMobilityComponent.touches_wall()` (public `_grip_normal() != ZERO`, so a `WorldEdges` wall never counts); `Player._recall_cue_met` adds the wall test (the body's judgement, as with the feet).
4. `Player`: rename `_dodge_axis()` to `_escape_axis()` and pass it to `_wall_mobility.update` as well as the roll, so a recalled climb grips with nothing held for `RECALL_ESCAPE_TIME`. Raise that constant only if the test shows the apex comes later.
5. `Guardian.body_height()` from `body_rect()`; `GuardianTalks` mirrors `BarkAnchor.x` by facing.

Plus one application of GRD-05 ("Parede de cinza"): once the recall gives WALL_CLIMB mid-fight, the crag shaft over `orchard_arena` is an exit (`gotchas/a-one-screen-shaft-cannot-shut-out-wall-climb`). `FightWall` gains `across` (cells wide, default 1, growing east); the legend `I` documents it; `orchard_arena.room` gets `31,0 = {"across": 8, "cells": 1}` under the shaft. `caldera_arena`'s top is solid.

### 4. Files, in build order

1. **Text and names** (orchestrator drafts, user approves): `05_roteiro.md` "Os guardiões (STORY-18)" gains autumn and summer lines (design 05 rule 3); names `GUARDIAN_AUTUMN` / `GUARDIAN_SUMMER` and `NOTEBOOK_GUARDIAN_*_BODY`; the WALL_CLIMB memory `SKILL_WALL_CLIMB`, `NOTEBOOK_LORE_WALL_CLIMB` (design 02 section 4: an echo of Ivo's life before; neither key exists).
2. **Art contracts** `tools/art/prompts/guardian_<autumn|summer>_<clip>.md` (14 each) and `portrait_guardian_<autumn|summer>.md`; references `tools/art/sources/guardians/<scarecrow|sun_lion>_ref.png` padded by `pad_reference.py` (scarecrow from `scarecrow_still_2x.png` onto 256x224). The gust's leaf stream: `resources/world/effects/gust_leaves.tres`, drawn by `tools/art/draw_procedural_sprites.gd`. Then generation (section 5) and `CREDITS.md`.
3. **Code** (section 3), each with its test, placeholder strips allowed (cut from the still) so the scenes load.
4. **Resources**: `autumn_guardian/` `autumn_guardian_stats.tres` (id 2, song `release.tres`), `autumn_sweep`, `autumn_gust`, `autumn_hop`, `recall_wall_climb`, `autumn_guardian_locomotion_stats`, `autumn_guardian_voice` (3 lucid barks + retry); `summer_guardian/` the same without a recall (id 3, song `shadow.tres`). Dialogue: `resources/dialogue/speakers/guardian_<id>.tres`, `resources/dialogue/guardians/guardian_<id>.tres` (`guardian_<id>_first` with the `guardian_<id>_gift` HOLD/LET ask, `guardian_<id>_again` with its two variants), both in `dialogue_catalog.tres`.
5. **Scenes** `scenes/characters/guardians/<autumn|summer>_guardian/<autumn|summer>_guardian.tscn`, copied from `frost_guardian.tscn` (every node, the RESET track, the 18-clip library and tree, the leap's dust wiring), shapes and exports from section 2; the scarecrow adds `GuardianGust` and `GustStream`.
6. **Placement**: an `Arena` (1280x384 at (640, 192)) and the guardian at (816, 288) with `arena_path` in `orchard_arena_contents.tscn` and `caldera_arena_contents.tscn` (the Frost arena's pattern; `ReachWorldLoader` reads `GuardianStats.id` from contents, which is what lets `ReachKitCheck.given` count both arenas as exits). `wind_orchards.tscn` / `summer_caldera.tscn`: `has_guardian = true`, `guardian` 2 / 3. Run the kit check: the two "no way out" findings should go, and nothing new may appear.
7. **Notebook**: `notebook_catalog.tres` portraits (`NotebookEntry.art`, an idle frame-0 crop no taller than 60 art px, like Frost's), the `lore_wall_climb` Memories entry; `assets/sprites/hud/portraits/guardian_<id>.png` (width a multiple of 4).
8. **i18n** rows (en, pt_BR): `SPEAKER_GUARDIAN_<ID>`, `BARK_GUARDIAN_<ID>_LUCID_0..2`, `_RETRY`, `DLG_GUARDIAN_<ID>_FIRST_<NN>`, `DLG_GUARDIAN_<ID>_AGAIN_<NN>[_V<k>]`, `DLG_CHOICE_GUARDIAN_<ID>_*`, the names, bodies and the memory. Nothing literal on screen.
9. **Docs**: `systems/guardians` (the two guardians, the gust and wall cue, the lion's shapes; the "before GRD-04" section becomes history), `systems/air` (a guardian move may carry Ivo through `push()`), `systems/rooms` / `docs/maps/README.md` (`across`), `Enums.Guardian` comments, glossary row 38, `CLAUDE.md` Guardians row if its rule changes, roadmap GRD-04, WORLD-16/17 notes.

Tests:
- New `guardian_gust_test`: Ivo grounded anywhere in front (100..1190 px from the wall behind) touches it before 2.0 s; nothing pushes behind the guardian, above `attack_height` or after the swing.
- `player_recall_test`: a `wall_cue` recall waits for wall contact and never opens on a world edge; at a wall the press unlocks WALL_CLIMB, jumps and is wall-sliding by the apex with nothing held; his feet stay above 32 px through 2.0-2.4 s.
- `combat_reach_test`: both scenes in `GUARDIAN_SCENES`; a move with `push_speed > 0` is measured against `GustStream.drawn_rect()` instead of the body art.
- `guardian_contact_test`: the lion's charge hits only with its box.
- `guardian_performance_animation_test`, `guardian_leap_animation_test`, `guardian_facing_test`, `guardian_talks_test`: iterate over all four scenes (they preload Frost and Bloom today). `guardian_leap_framing_test`: all four, asserting the **drawn sprite's** opaque rect, not `body_rect()`, inside `view_rect()` at touchdown.
- `bark_balloon_test`: the anchor follows facing; the lion's box keeps off its head.
- `fight_wall_test`: an `across` wall closes only when clear of Ivo; the orchard's ceiling wall holds a climb.
- `notebook_catalog_test`: the AUTUMN/SUMMER skip removed, both stats in `GUARDIAN_STATS`.
- Unchanged but now covering them: `guardian_voice_test` (finds scenes by folder), `guardian_talk_rooms_test`, `dialogue_catalog_test`, `dialogue_text_fit_test`, `bark_text_fit_test`, `notebook_text_fit_test`, smoke (both arena contents are listed). A `Guardian` body test: `body_height()` 156 / 72.
- Playtest per guardian (`godot-playtester`): the gust delivery and climb from both ends, a pogo, three cures with one failure, the lesson, both talks.

### 5. Art workflow and cost

Per clip: the approved Codex still (already cut) -> padded reference -> PixelLab `animate3` from a contract (`guardian_frost_*.md` is the template: `keep`, `generate`, `view: side`, `direction: west`, `no_background`) -> `cut_inhabitant.py` (`--scale=1`, the scarecrow `--write=1` from 2x frames, `--floor` on the bottom row) -> `despeckle.py` -> `compose_strip.py` where a loop or a ping-pong is composed. `perform_end` first: its playing frame is the reference for `play_song` and `perform`. `hurt` comes from `lean_frames.py` (no generation). Portraits: one Codex picture with both busts, cut by `cut_single_prop.py`. The gust stream is procedural.

PixelLab generations: 13 `animate3` strips per guardian = **26 base**. GRD-07/08 needed about one retry per two clips (effects in the body's colours, turns to the viewer); a side-view quadruped adds risk on the attacks and the leap. **Budget about 40 calls** (26 + ~14 retries); Codex: 1 portrait picture.

## Consequences

- SOLID: a new guardian is data and art (Open/Closed); `GuardianGust`, `GustStream` and the wall cue each do one thing (Single responsibility) and any guardian may use them; `Guardian` keeps its contract (Liskov) and reads no input; the recall cue stays the body's judgement pushed into the component (Dependency inversion).
- Node / Resource / Autoload: moves, recall, stats, voices, talks are Resources; `GuardianGust`, `GustStream` and the scenes are Nodes; no autoload.
- Risks: the gust is the first move that moves Ivo, so its feel (644 px/s on the ground) needs the playtest; the wall slide from the apex must stay above the 32 px band (pinned by test, with more jumps as the player's way to climb); PixelLab may lose the lion's tail or turn it; the lion's balloon over its back.

## User decisions on the open questions (2026-10-30)

- Lines and names: "Aprovar as falas" (`docs/design/drafts/guardian_talks_autumn_summer.md`, now in `05_roteiro.md`): "Guardião da Folha" / "Leaf Guardian" and "Guardião do Sol" / "Sun Guardian".
- The gust that carries Ivo to a wall and the wall-cued WALL_CLIMB recall: "Pode (Recommended)".
- The lion's middle move: "Investida no chão (Recommended)".
- Art budget and the burned shadow: "40 chamadas; sombra depois (Recommended)": about 40 PixelLab calls; the scorched shadows go to WORLD-17.
