---
id: architecture/grd-12-guardian-fight-engine
type: architecture
title: GRD-12 plan - the shared guardian fight engine (wind-up/strike/recovery, strings, stages from good answers, spawned attacks, solved reposition motions, 8 clip slots) as data, with no gameplay change until GRD-13..17
status: built
tags: [grd-12, guardian, plan, ai, strings, stages, projectiles, hazards, motion, resolver, combat-reach]
related: [systems/guardians, systems/animation, systems/creatures, systems/life-benches-death, architecture/guardian-fight-phase-machine, architecture/corrupted-creatures, architecture/grd-04-autumn-and-summer-guardians, architecture/grd-06-final-battle, architecture/animation-driver-resolver-pattern, gotchas/animationtree-reset-track-overwrites-script-writes, gotchas/body-state-cannot-change-in-the-physics-flush, gotchas/a-teleported-kinematic-body-overlaps-from-its-old-place-for-one-step, gotchas/an-explicit-process-mode-escapes-a-disabled-ancestor, gotchas/time-scale-zero-stops-delta-particles-and-time, gotchas/physics-parent-before-children-one-frame-lag, bugs/recall-move-range-exceeds-hitbox-reach, bugs/a-guardian-lunge-turned-to-follow-a-player-who-rolled-under-it, bugs/the-frost-swipe-hit-ivo-far-from-its-fist, bugs/pogo-over-a-guardian-is-a-free-ride]
created: 2026-11-18
updated: 2026-11-18
source_files:
  - scenes/characters/guardians/guardian.gd
  - scenes/characters/guardians/guardian_ai.gd
  - scenes/characters/guardians/guardian_fight.gd
  - scenes/characters/guardians/guardian_animation_resolver.gd
  - resources/characters/guardians/guardian_attack.gd
  - resources/characters/guardians/guardian_stats.gd
  - tests/scenes/combat/combat_reach_test.gd
  - tests/scenes/characters/guardians/guardian_ai_test.gd
---

# GRD-12 plan: the shared guardian fight engine

**Status: built** (2026-11-18). Roadmap GRD-12. Board `docs/design/drafts/guardian_fights_board.md`. Contract `systems/guardians`. This plan changes that contract only where it says so.

## User decisions (verbatim, 2026-11-18)

- Moves: "Approve as proposed (Recommended)". Stages: "Yes, each answer escalates (Recommended)". Art: "Code first, art per guardian (Recommended)". Life: "Keep 3 notes, damage 1 (Recommended)".

## Context

- Today each move is telegraph (a still IDLE plus the pulse), then the swing (`duration` = the clip), then a 1.4-2.8 s cooldown. There are 3 clip slots, no strings, no projectiles and no motion beyond `lunge_speed`/`leap_impulse`. `guardian.gd` is 30 KB.
- Creatures already have this shape: the pure `MoveClock` (TELEGRAPH, ACTIVE, RECOVER, COOLDOWN, where a recovery is never cancelled) in `systems/creatures`. Flyer reach is measured *flown* (`combat_reach_test._flown`).
- Fixed points: `GuardianFight` is pure and owns the clock. The contact hitbox belongs to the phase. The move `Hitbox` is keyed with a RESET track, so scripts must never write `monitoring`. `WorldFreeze` is the only writer of time scale and pause. The recall's guarantee holds. The Finale seams hold: `set_attacks`, `fight()`, `call_phrase`, `end_lucidity_without_answer`.
- **GRD-12 ships green with no gameplay change.** Every new field defaults to today's behaviour, and no guardian `.tres` or `.tscn` changes its data. Two exceptions: new nodes are added to the five guardian scenes, and the reach audit's widened scope may expose `mentor_spring.tres` (see Risks).

## Options considered

1. **Where stage lives.** (a) A counter in `GuardianAI`. Rejected: the AI would then know the cure, a second truth beside `GuardianFight._cycles`. (b) **`GuardianFight.stage()` = `cycles()`**, with the stage table in `GuardianStats`. The fight derives `cooldown_scale()` (aggression x stage), `chain_scale()` and `max_links()`, and `Guardian` pushes them into the AI. The AI only chooses. **Chosen.**
2. **Move set per stage.** (a) A full `Array[GuardianAttack]` per stage. Rejected: duplicated moves, and it fights the Finale's `set_attacks`. (b) **`from_stage` on each move and each link**, filtering whatever list is current. This matches the board's "Stage" column and composes with the revelation's swap. **Chosen.**
3. **Strings.** (a) A `combo: Array` of moves. Rejected: it cannot express a chance per link or "from stage 1 it pounces twice". (b) **`follow_ups: Array[GuardianFollowUp]`** (link: `attack`, `chance`, `from_stage`, `needs_wall`). A link with a null `attack` repeats the move it follows, because a `.tres` cannot list itself. **Chosen.**
4. **The move clock.** (a) Grow `GuardianAI`'s timers. Rejected: the AI is 440 lines. (b) Generalise creature `MoveClock`. Rejected: it is typed on `EnemyMove`, and chaining would add risk to six species. (c) **A new pure `GuardianMoveClock` modelled on `MoveClock`**: TELEGRAPH, STRIKE, RECOVER, COOLDOWN, READY, plus `chain(next)` (STRIKE to the next link's TELEGRAPH, skipping RECOVER and COOLDOWN). **Chosen.**
5. **Motion.** (a) An enum plus a `match` in `Guardian`. Rejected: branches in one script. (b) Velocity scripts per move. Rejected: they cannot be reach-tested without a scene. (c) **`GuardianMotion` Resource strategies that plan a pure `MotionPath` solved to fit the move's fixed strike time.** The clip stays the clock, `_assert_clip_durations` keeps working, and `combat_reach_test` replays the identical path. Precedent: the `EnemyAI` subclasses. **Chosen.**
6. **Spawn timing.** (a) Method-call tracks in the strike clip. Rejected: the tree would decide gameplay (`systems/animation`). The driver starts a clip only when its name changes, so a repeated link would not refire it, and tests cannot replay it. (b) **`GuardianSpawn.at` (scaled s into the strike), read from the move clock**, as `lunge_delay` is today. **Chosen.** The task says "keyed moment". This is that moment as data, set to a frame time of the clip.
7. **Spawn parent.** (a) A layer in `game.tscn`. Rejected: it outlives the room, has the wrong pause mode and needs manual cleanup. (b) The `Arena`. Rejected: level geometry would own fight objects. (c) **A `GuardianSpawner` Node2D child of the guardian with `top_level = true`.** Spawns get world coordinates, inherit the guardian's pause and visibility (a deactivated room hides and stops them) and are freed with the guardian, so a death rebuild clears them for free. **Chosen.**
8. **Floor hazards.** `HazardZone` was rejected: it is the water-respawn path (body detection, `receive_hazard`, a teleport to safe ground). A burning patch is a **`Hitbox`** (`continuous = true`, the `ContactHitbox` semantics), so it respects i-frames and knockback.

## Decision

### Data (all defaults = today)

`GuardianAttack` (`resources/characters/guardians/guardian_attack.gd`):

| Field | Type, default | Meaning |
|---|---|---|
| `clip_index` | `@export_range(0, 7)`, 0 | strike slot `attack_1..8` |
| `windup_index` | `@export_range(-1, 7)`, -1 | wind-up slot played through `telegraph`; -1 plays IDLE (today) |
| `recovery` | float s, 0.0 | punish window after the string's last link, standing, facing kept |
| `recovery_index` | `@export_range(-1, 7)`, -1 | recovery slot; -1 plays IDLE |
| `from_stage` | int, 0 | the cure stage at which the move joins the set |
| `strikes` | bool, true | the strike clip keys a hit window; false is a pure reposition or spawn move |
| `follow_ups` | `Array[GuardianFollowUp]`, [] | string links, tried in order |
| `motion` | `GuardianMotion`, null | null keeps `lunge_speed`/`lunge_delay`/`leap_impulse` exactly as now |
| `spawns` | `Array[GuardianSpawn]`, [] | spawned attacks fired during the strike |

- `GuardianFollowUp` (Resource): `attack: GuardianAttack` (null: the same move again), `chance: float` (0..1, scaled by `chain_scale`, clamped to 1), `from_stage: int`, `needs_wall: bool` (chains only when the strike ended against a wall or the arena edge ahead: charge-back, wall bounce).
- `GuardianStage` (Resource): `cooldown_scale: float` (1.0), `chain_scale: float` (1.0), `max_links: int` (3; capped by `GuardianRepertoire.MAX_LINKS`, 4).
- `GuardianStats.stages: Array[GuardianStage]`, indexed by good answers. Past the end, the last entry applies. An empty array is neutral.
- `GuardianSpawn` (Resource): `scene: PackedScene`, `at: float` (s into the strike), `on_landing: bool`, `placement: Placement { FRONT, AT_IVO, AROUND_IVO, ACROSS_ARENA, BOTH_SIDES }`, `count: int` (1), `spacing: float` (px), `interval: float` (s between instances: columns lit in sequence), `offset: Vector2` (px from the feet, facing east), `damage: int` (1), `knockback_strength`, `knockback_lift`. Kind tunables (speed, warn, life, size, colours) are exports on the kind scene's root. A guardian's variant is that scene instanced with overrides and no script.
- `GuardianMotion` (Resource, base) `plan(ctx: MotionContext) -> MotionPath`. Subclasses in `resources/characters/guardians/motion/`: `StepMotion` (backstep or hop: `distance` px, signed; `delay`; `time`), `DashMotion` (`speed`, `delay`, to the arena edge less `margin`), `LeapMotion` (`target` FAR_SIDE / IVO_SPOT / PAST_IVO, `height` capped under the arena top less body height, `delay`, `air_time`, `passes_through`), `DiveMotion` (`height`, `rise_time`, `hang`, `dive_time`, aim locked at strike start), `BlinkMotion` (`at` s, `behind` px; takes the other side when the arena clamps it within `min_gap`). Every plan is solved to finish inside `duration`: speed varies, time does not.

### Pure logic (RefCounted, each with a gdUnit4 suite)

| Class | Path | Job |
|---|---|---|
| `GuardianMoveClock` | `scenes/characters/guardians/guardian_move_clock.gd` | phases, `elapsed()` in STRIKE, `chain()`, `cancel()` (clears all, no cooldown: lucidity), and RECOVER, which is not cancellable by `provoke()` |
| `GuardianRepertoire` | `.../guardian_repertoire.gd` | static: `available(attacks, stage)`, `next_link(move, stage, chain_scale, links_done, max_links, in_range: Callable, at_wall, recall_requested, roll: Callable)`. **No RNG draw when a move has no eligible link**, so legacy fights keep their random stream |
| `GuardianMoveGraph` | `.../guardian_move_graph.gd` | static: `moves(stats)` = roots + links (transitively, deduped) + `finale.revealed_attacks`; used by the reach test, the clip asserts and the invariants test |
| `MotionPath`, `MotionContext` | `resources/characters/guardians/motion/` | `at(t) -> Vector2` offset, `duration`, `blink_at`/`blink_to`, `holds_vertical(t)`; the context holds start feet, facing, target feet, arena `Rect2`, margin, gravity, body height and strike duration |
| `SpawnPlacement`, `SpawnContext` | `scenes/characters/guardians/spawns/` | where each of `count` instances goes, from origin, facing, Ivo's feet, arena and floor y |

`GuardianFight` gains `stage() -> int` (= `_cycles`), `stage_tuning() -> GuardianStage`, `chain_scale()`, `max_links()`, and `cooldown_scale()` becomes the aggression factor times the stage's. A failure leaves the stage alone (design 02 §3 unchanged).

### Nodes (composition, each one job)

- **`GuardianAI`** (refactored onto `GuardianMoveClock` and `GuardianRepertoire`). It gets new pushed properties: `stage`, `chain_scale`, `max_links` and `blocked_ahead`, which is a continuous property and not a signal. Its existing signals now fire per link. `is_recovering()` is new. `facing_intent()` is 0 during a strike and a recovery. Picks, `_tallest_reach()` and the overhead logic use `available()`. The recall cadence counts a string once, at its end. `request_recall()` drops the remaining links. A link chains only if it is in range (`_in_range`), so every move is still thrown only inside its own `attack_range`.
- **`GuardianMover`** (new Node child, `scenes/characters/guardians/guardian_mover.gd`). The legacy lunge and leap block moves here verbatim from `Guardian._process_motion`. It plans `motion` at strike start, then writes velocity from `MotionPath` each frame, suspends gravity in a hang, uses `Character.teleport` for a blink (never a position write) and faces Ivo after it. It reports `owns_vertical()`, `is_intangible()` (a blink's out-to-in) and `against_wall()`. `Guardian` calls it from `_process_motion` (the parent calls down in the same frame, so the parent-before-child lag does not apply). The pass-through rule above the take-off floor becomes one `Guardian._pass_through_above(floor_y)` shared with the lucidity leap; the two never run at once.
- **`GuardianSpawner`** (new Node2D child, `top_level`, `.../guardian_spawner.gd`). `begin(attack)` arms the move's spawns, and `tick` fires each one at `at`, or `on_landing`, once per strike. It aims at `fought_player()`, places against `Guardian.arena_bounds()` (made public) and the floor, and pushes the spawn's damage and knockback into the spawned `Hitbox`. `clear()` frees everything live: each child's hitbox `set_deferred("monitoring", false)` and then `queue_free()`, because a clear can come from inside a hit's physics flush.
- **Spawn kinds** (`scenes/characters/guardians/spawns/<kind>/<kind>.tscn`, each a root script plus a `Hitbox` child; the script owns its scaled `_physics_process` clock, its warn/live/fade phases and the hitbox's `monitoring`; no AnimationPlayer, no `TIME`/`FRAGCOORD`; frames or `_draw` snapped to the 2 px art grid; a light/dark value pair so it reads in grey; `CanvasPass.join_layer(self, CanvasPass.CREATURES)` in `_ready`, because a node added later does not inherit the bit; INHERIT process mode). The kinds and what they cover:
  - `FloorRunner`: thorn row, ice wave (BOTH_SIDES); it re-probes the floor per step and stops at a gap or the arena edge.
  - `FallingShard`: icicles; a glint at Ivo's x, then the fall.
  - `Boomerang`: leaf blades, out and back.
  - `Lob`: embers and seed pods, a ballistic arc that leaves a `FloorPatch`.
  - `FloorPatch`: burn or thorns for `life` s, `continuous`.
  - `LightColumn`: lit first, then it burns.

  Each exposes pure `hit_transforms(ctx) -> Array[Transform2D]` and `drawn_rect(ctx)` for the tests.
- **`Guardian`** (thinner):
  - `_on_attack_started` calls `_mover.begin`, `_spawner.begin` and `_animation_driver.request_replay()`. The replay is needed because a repeated link reuses the clip name, and without it the Hitbox keys would not rerun.
  - `_push_tuning()` (stage, chain, cooldown) runs from `_close_call` and on RELAPSE->PRESSURE.
  - `_on_phase_changed(to != PRESSURE)` calls `_spawner.clear()`. Live spawns are also cleared when a recall move with a missing skill starts, so no stray thorn lands inside the recall window.
  - `body_hurts()` and `_on_hit_received` also refuse while `_mover.is_intangible()`. A recovery keeps the move's `body_contact`.
- **`GuardianAnimationResolver`**: `ATTACK_1..8`, `WINDUP_1..8`, `RECOVER_1..8` as consts in a `SLOT_CLIPS` table. `CLIPS` (the required set, `guardian_voice_test`) does not change. The `resolve()` order after the phases is: strike, then recovery (slot or IDLE), then telegraph (wind-up slot or IDLE, as today), then hurt, walk, idle. No transitions and no `advance_expression`.
- `_assert_clip_durations` walks `GuardianMoveGraph.moves`:
  - strike length == `duration`;
  - wind-up length <= `telegraph`;
  - recovery length <= `recovery`.

  The wind-up and recovery clips hold their last frame. Clips are added to a guardian's tree only when its data uses a slot (GRD-13..17), as placeholder frames cut from today's strips, with real art in GRD-18.

### Signal contracts

Signals go up and calls go down. AI -> Guardian: `attack_telegraphed`, `attack_started`, `attack_finished` (per link, unchanged names). Guardian -> its children: direct calls (`_mover.begin`, `_spawner.begin`/`clear`), as it already calls `_hitbox` and `_call`. Spawn -> spawner: `expired` (frees it). A spawn's `Hitbox.hit_landed` reaches Ivo's hurtbox like any hitbox, and `Player.hurt` already drives the hit-stop and the shake. There are no new `Player` or `WorldFreeze` calls and no autoload.

## Consequences

- **Tests to add or extend:**
  - `guardian_ai_timeline_test`, written first against today's code: seeded `seed()`, all five stats, a scripted Ivo, 20 s of telegraph, start and finish times as a golden array. It must pass unchanged after every step.
  - `guardian_move_clock_test`, `guardian_repertoire_test` (stage filter, chance scaling and clamp, `needs_wall`, `max_links`, recall preempts, no roll without links).
  - `guardian_fight_test` (stage = cycles, cooldown = aggression x stage, a failure keeps the stage, empty stages are neutral).
  - `guardian_move_graph_test`. Invariants: a recall move has `from_stage` 0 (else no window could ever open), no link is a recall move, a recall move has no spawns, every string ends within `MAX_LINKS`, and every slot referenced exists in that guardian's tree.
  - `motion_path_test` and one suite per motion (lands on target inside arena margins; apex under the arena top; dash stops at the edge; blink swaps sides).
  - `spawn_placement_test` and one suite per kind (hitbox off in warn, on in live, freed after; ticks only on delta).
  - `guardian_spawner_test` (fires once per strike and twice for a repeated link; cleared on PRESSURE->LUCIDITY, RESTORED and a recall start; stopped under tree pause).
  - `guardian_mover_test` (teleport with no stale overlap; hang gravity off).
  - Resolver tests for wind-up, recovery and replay.
- **`combat_reach_test`** iterates `GuardianMoveGraph.moves` (links and revealed moves included).
  - `strikes = false`: the strike clip keys no `Hitbox:monitoring` true.
  - Motion moves: the keyed box swept along the same `MotionPath`, for an Ivo at the near end, at `attack_range` and at `attack_height`. It must touch at every distance for aimed motions, the flyer rule from `systems/creatures`.
  - Spawns: `hit_transforms` against an Ivo at 8 px steps from near to `attack_range`. Aimed kinds touch at each step. Spreads leave a gap of at least Ivo's width plus 8 px. Runners and waves stay under his jump apex (144). Anything from above or below warns for at least `MIN_WARN` (0.35 s). Every spawn's hit box stays inside `drawn_rect` plus `DRAWN_SLACK`.
- A test fixture guardian (`tests/fixtures/guardians/engine_guardian.tscn`, Bloom strips, data exercising every feature) drives the scene suites. The kind scenes and the fixture go into `tools/smoke/scenes.txt`.
- **i18n**: GRD-12 adds no user-facing text. Assert messages are developer-only. A later spawn name or tutorial line goes through `tr()`.
- **Docs in the same change**:
  - `systems/guardians`: engine section, slots, stages, spawn clearing.
  - `systems/animation`: optional slots versus required `CLIPS`.
  - The `CLAUDE.md` Guardians row: "spawned attacks are Hitboxes cleared out of PRESSURE; a motion is solved to the clip's time".
  - The roadmap row.
- **Build order**: (0) golden timeline test; (1) Resources and `GuardianMoveGraph`, with the reach test moved onto the graph; (2) `GuardianMoveClock` and `GuardianRepertoire`, then the AI refactor; (3) `GuardianFight` stage API and `_push_tuning`; (4) resolver slots, replay and graph asserts; (5) `GuardianMover` (legacy lunge first, identical, then the motions) and the flown reach checks; (6) `GuardianSpawner`, placement, the six kinds and smoke; (7) docs, `verify-gates`, and one bot fight each on Bloom and Frost to confirm nothing moved.
- **Risks**:
  - Widening the reach audit to `revealed_attacks` may fail `mentor_spring` (range 110, a strike-only clip). If it does, fix its range as data in GRD-12 and say so, or list it with a reason until GRD-17.
  - The RNG stream diverges if the refactor draws `randf()` where it used not to. Guard: the golden test plus the no-roll rule.
  - Links with telegraph 0 behind a box open to its clip end keep `monitoring` true, so a second `area_entered` does not fire on an Ivo still inside. It is harmless under his 0.85 s i-frames, but the per-guardian items should know.
  - `combat_reach_test` runtime grows with the moves times the distances. Spawn scans use 8 px steps.
  - The dive's aim is locked at strike start ("move out"). Locking it at the hang's end needs a replan, so leave that to GRD-15 if its playtest asks.
  - Design 02 §3 says only that a failure escalates. The approved stage escalation on success should be recorded there by whoever owns the design text. GRD-14's charge-back reuses the recall charge's pattern, which the per-guardian items should check against 02 §4 ("não reutilizado como padrão geral").
- **One note per string** ("One note per string (Recommended)", user, 2026-11-18): getting caught by a string costs at most one life note. A string is one move for damage: a `Hitbox` gate refuses a link's hit on a target the same string already hurt (the move box is keyed and cannot be switched off from script).
