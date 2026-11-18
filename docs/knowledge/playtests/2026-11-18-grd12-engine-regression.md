---
id: playtests/2026-11-18-grd12-engine-regression
type: playtest
title: GRD-12 regression - all four guardian fights play the same on the refactored engine as on HEAD (same moves, travel, landings, recall, cures, deaths)
status: active
build: e9bd9ced + uncommitted GRD-12 working tree (guardian.gd, guardian_ai.gd, guardian_mover.gd, guardian_spawner.gd, hit_gate.gd, resolver, the five guardian scenes), against a `git archive HEAD` export of e9bd9ced
area_tested: "bloom_hollow (Bloom), lake_frost_arena (Frost), caldera_arena (Summer), orchard_arena (Autumn): whole bot fights to RESTORED, plus passive (standing) runs"
tags: [guardians, grd-12, regression, mover, lunge, leap, recall, playtest]
related: [systems/guardians, architecture/grd-12-guardian-fight-engine, playtests/2026-10-29-grd07-guardian-art, playtests/2026-10-30-grd09-leap-framing, playtests/2026-10-30-grd04-autumn-summer-fights, bugs/the-sun-guardians-roar-never-fires]
created: 2026-11-18
updated: 2026-11-18
source_files:
  - scenes/characters/guardians/guardian_ai.gd
  - scenes/characters/guardians/guardian_mover.gd
  - scenes/characters/guardians/guardian.gd
  - scenes/combat/hitbox/hit_gate.gd
screenshots:
  - screenshots/2026-11-18-grd12-engine-regression/bloom_main_vs_head.png
  - screenshots/2026-11-18-grd12-engine-regression/frost_main_vs_head.png
  - screenshots/2026-11-18-grd12-engine-regression/autumn_main_vs_head.png
  - screenshots/2026-11-18-grd12-engine-regression/summer_main_vs_head.png
---

## Summary

GRD-12 is meant to change no gameplay. Each guardian was fought by `guardian_fight_bot_driver.gd` on the working tree
("main") and on a HEAD export ("head") with the same policy. **All four PASS.** Moves, clips, lunge and leap travel,
landing heights, the recall, the lucidity leap, the cures and RESTORED match. Passive runs give the same move order
and the same death time to 0.1 s. There are no new errors. One pre-existing defect was found and is the same on HEAD:
the Sun Guardian's roar never fires (`bugs/the-sun-guardians-roar-never-fires`).

## Setup

- `"$GODOT" --path <tree> -s res://tools/playtest/scripts/guardian_fight_bot_driver.gd`, with `guardian_bot_<g>.json`.
  `APPDATA` was redirected per run and checked with a headless `OS.get_user_data_dir()` probe.
- `BOT_GOD=1` for the full fights. Bloom was also run once without it on each tree. `BOT_PASSIVE=1` ran on 30-40 s
  copies of the bloom, frost and summer timelines.
- The HEAD export was imported once. No file under `scenes/`, `resources/` or `globals/` changed after that import.
- Run order: main and head runs alternate, one after another. Only one game window was open at a time.
- Numbers come from the `[bot]`/`[spr]` logs through a scratch `summ.py`. It reports phases, hp changes, telegraph and
  swing durations, the clip texture per attack state, and each strike's x travel, peak y and landing y.

## Results (main vs head)

| Guardian | RESTORED at | Ivo hits taken | Strike travel (main / head) | Peak, landing | Recall |
|---|---|---|---|---|---|
| Bloom (god) | 41.3 s / 42.1 s | 4 / 4 | pounce ±192.4 / ±192.4 | 48.4 px up, lands y 285-288 in both | burst launch + double jump at 7.3 s in both |
| Bloom (no god) | Ivo dies 23.8 s / 24.1 s, both by a pounce, before the second cure | 3 / 3 | same | same | same |
| Frost (god) | 66.2 s / 67.0 s (3 cures) | 8 / 8 | charge -310.6 to -311.8 / same | on the floor (y -1632.0/-1632.1) | roll at the charge, 6.5 s in both |
| Summer (god) | 70.1 s / 69.8 s (2 cures) | 32 / 32 (23 / 22 body contact) | charge ±287.7 / ±287.8 | on the floor (y 1824) | none (by design) |
| Autumn (god) | 87.8 s / 78.6 s (3 cures) | 5 / 4 | hop ±240 / ±240 (one -229.7 against the wall in both) | 74.6 px up, lands y -1248.1 | gust to the wall, wall climb recalled at 8.87 s in both |

Passive (standing Ivo) runs:

- Bloom: pounce, lash, burst, lash, pounce on both trees. Ivo dies at 12.3 s on both (GRD-07 measured 12.8 s).
- Frost: swipe, slam, charge, swipe on both. Ivo dies at 14.3 s on both.
- Summer: 7 charges and 3 claws in the same order on both.

The two trees fire each passive strike within 0.03-0.08 s of each other. The bot fights match exactly through the
first cure. After it, small timing differences change the weighted picks, so the later move mix diverges in both
directions. Autumn's 9 s gap comes from that: head drew 3 sweeps, main 1. Earlier reports give the same scale: GRD-04
had autumn at 88 s and summer at 74.5 s with the talk driver.

## Findings

- **Clips play at their moments.** Every strike's `[spr]` run is the move's own `attack_N` strip, frames 0..last, in
  both trees: bloom lash `attack_1`, burst `attack_2`, pounce `attack_3`; frost swipe/charge/slam
  `attack_1/2/3`; summer claw/charge `attack_1/2`; autumn sweep/gust/hop `attack_1/2/3`. Every telegraph shows the
  idle strip (default `windup_index` -1). Telegraph and swing durations agree within 0.05 s. In no strike did a
  walk or idle frame appear.
- **Lunges and leaps move the body and land.** The pounce, charge and hop travel the same px as on HEAD, rise to the
  same peak and come back to the floor's y. No guardian floats, slides past its travel, sticks or sinks through the
  floor: the minimum y during non-leap strikes equals the floor y in every run. The pounce's first logged landing
  frame reads y 285.0 rather than 287.9 on both trees, so it is pre-existing.
- **The lucidity leap** clears the top and lands in frame. The highest point is y -45.3 (bloom) and -1965.3 (frost) on
  both trees. On every leap the guardian is staged at screen x 551-556 (summer 509), the same as GRD-09. All
  `lucid` burst shots keep the body inside 0..640. The only frames that leave it are relapse/unstaged and restored
  frames, where the camera unpairs and the guardian walks off, and these match HEAD frame for frame.
- **The recall happens.** Bloom: burst, launch, double jump. Frost: the roll at the charge. Autumn: the gust to the
  west wall and the wall climb. All three fire at the same time on both trees.
- **HitGate:** Ivo took the same number of hits on both trees in every run except autumn, where main took one more
  (5 vs 4, a different move mix after the first cure). No single strike hit twice where HEAD hit once. With no shipped `follow_ups`, a "string" is one move, so this is the expected null result.
- **Logs:** no script errors on either tree. Main prints one extra line on the first room build: `WARNING:
  lake_chasm.room: invalid UID 'uid://s3gvwyy8befk' ... room_legend.tres`. It comes from a stale import cache in the
  main tree; the file itself has no such uid, and the freshly imported HEAD export never prints it. It is not from
  GRD-12. Running `--import` in the main tree should clear it.
- **Pre-existing (same on HEAD):** the Sun Guardian's roar was never thrown in 4 summer runs (about 45 strikes). See
  `bugs/the-sun-guardians-roar-never-fires`.

## What screenshots cannot show

These runs were judged from logs and paired frames, not watched. Weight, the feel of a landing and input latency
cannot be judged from them. The `summ.py` travel and timing figures are the evidence for "the same". The four contact
sheets show the same pose in the same place in both trees for the pounce, the burst recall, the lucidity staging, the
frost slam, charge and recall, the autumn hop and wall recall, and the summer charge and claw. No fun or fluidity
rating is given: this was a regression check, and both builds behave the same.
