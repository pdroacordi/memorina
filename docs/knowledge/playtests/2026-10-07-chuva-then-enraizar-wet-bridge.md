---
id: playtests/2026-10-07-chuva-then-enraizar-wet-bridge
type: playtest
title: PZL-08 wet root bridge - Chuva then Enraizar crosses the 12-cell chasm, but the rain's clock leaves about 1.4 s of slack
status: active
build: d89f0ba + uncommitted PZL-08 (root_grower.gd, spring_trial.room/.tscn); re-run on the later working tree, same result
area_tested: "Spring trial puzzle 5 (wet root bridge), trials_spring at world x 7200, map cols 57-74"
tags: [enraizar, chuva, root-bridge, composition, trials, timing, pzl-08]
related: [bugs/root-bridge-strands-meet-at-a-step, playtests/2026-09-30-enraizar-shaft-and-bridge, playtests/2026-09-30-chuva-basin-and-moat, gotchas/parallax2d-ignores-its-parents-offset, systems/roots-and-climbing]
created: 2026-10-07
updated: 2026-10-07
ratings: { fun: 3, fluidity: 3, aesthetics: 3 }
screenshots:
  - screenshots/2026-10-07-chuva-then-enraizar-wet-bridge/control_enraizar_alone_no_bridge.png
  - screenshots/2026-10-07-chuva-then-enraizar-wet-bridge/wet_bridge_growing_13.00.png
  - screenshots/2026-10-07-chuva-then-enraizar-wet-bridge/on_the_step_under_the_bridge_14.80.png
  - screenshots/2026-10-07-chuva-then-enraizar-wet-bridge/crossing_18.00.png
  - screenshots/2026-10-07-chuva-then-enraizar-wet-bridge/rain_contracts_bridge_breaks_20.50.png
  - screenshots/2026-10-07-chuva-then-enraizar-wet-bridge/late_run_far_bank_20.20.png
  - screenshots/2026-10-07-chuva-then-enraizar-wet-bridge/late_run_broken_20.40.png
  - screenshots/2026-10-07-chuva-then-enraizar-wet-bridge/strand_step_at_the_join_4x.png
---

## What was tested

All runs start Ivo on the stone ledge (col 65, `player_position` [9296, 6142]) with
`known_songs` [6, 7]. Every run redirected `APPDATA`, and the real save's md5 was
unchanged after each one. All `t` values are the runner's unpaused clock.

- `tools/playtest/scripts/song_root_wet_bridge_dry.json`: the control. Enraizar alone
  from the ledge, with frames to t 11 (about 4 s into its sustain).
- `tools/playtest/scripts/song_rain_root_wet_bridge.json`: the solution.
  1. Chuva (notes t 2.6-4.65), then Enraizar (drawn t 7.0).
  2. Climb: jump left to the step, then jump left to the near bank.
  3. Walk right across the bridge to the far bank.
  4. Frames every 0.5 s until t 28 to see the bridge wither.
- `tools/playtest/scripts/song_rain_root_wet_bridge_late.json`: Enraizar drawn 3 s later
  (t 10.0), the same route with no pauses. This finds the slack.
- Scratch runs (not committed):
  - Enraizar 4 s late.
  - The first jump with left held throughout.
  - From the step, jumping right up through the bridge.
  - The way back from the far bank: walking off, then a jump.

## Findings

- **The bridge needs Chuva.** Enraizar alone covers both banks from the ledge and grows
  nothing (`control_enraizar_alone_no_bridge.png`). After Chuva, strands grow from both
  banks within ~1 s of Enraizar's pulse and join between t 13.4 and 14.1
  (`wet_bridge_growing_13.00.png`). The one-way floor holds Ivo at y 6000 across x 9120-9504.
- **The rain sets the deadline, not Enraizar.** The rain opened at t ≈ 6.4 and the bridge
  broke at t ≈ 20.3 in both the on-time and the late run, while Enraizar's pulse was still
  in sustain (green disc in `rain_contracts_bridge_breaks_20.50.png`). That is ~13.9 s of
  wet faces: attack 2 + sustain 10 + ~1.9 s of contraction. The banks are ~240-262 px from
  the rain's origin, so the 600 px radius buys little. Contraction is squared, so the
  radius passes 262 px three-quarters of the way through. The contraction is also shortened
  by grey ground (`contract_min_factor`). The ~2.5 s contraction is inferred from the break
  time, not measured.
- **The crossing window is tight.**
  - On-time run, inputs machine-perfect (Enraizar drawn 0.6 s after the rain appeared,
    notes 0.4 s apart, 0.4-0.8 s idle between moves): Ivo reached the far bank at
    t 18.9, ~1.4 s before the break.
  - Late run (Enraizar 3 s later, no idling): he reached x 9504 at t ≈ 20.23. The frame at
    20.20 shows the bridge whole, the frame at 20.40 shows it broken (`late_run_*.png`):
    about zero margin.
  - 4 s late: the floor went from under him at x ≈ 9330. He fell into the pool (-1 hp) and
    respawned on the ledge.
  - So between seeing the rain and reaching the far bank, the whole hesitation budget is
    ~3 s. It must absorb the gap before playing Enraizar, the speed of the notes, waiting
    for the strands, and both jumps. One wrong note (the error sound, then a replay) very
    likely spends all of it. Every number here comes from the timeline's clock; whether a
    person can make it needs a human playtest. Possible levers are for the designer: the
    rain's sustain, a joined bridge staying while its Enraizar pulse holds, or a shorter
    climb.
- **The shortcut beats the documented route.** From the step, a jump right goes up through
  the one-way bridge (64 px above the step, `on_the_step_under_the_bridge_14.80.png`). Ivo
  lands on it at x ≈ 9369 and reaches the far bank 1.8 s after leaving the step. Going via
  the near bank took 3.1 s. Players will likely find this route, and it buys ~1.3 s. The
  room comment and `spring_trial_test` only describe the near-bank route; both routes
  work.
- **The climb: the first jump is the precise one.**
  - Ledge to step: the jump travels ~130 px left and the step is one cell (32 px).
    Released at 0.7 s, Ivo landed at x 9166. With left held throughout, he flew past the
    step into the one-cell gap at col 60, fell into the pool (-1 hp) and respawned on the
    ledge.
  - From the logged trajectory, the release window is roughly 0.55-0.8 s after the press.
    That is an inference about difficulty, not felt.
  - Step to near bank: easy (64 px up). But the near bank is only 3 cells wide, with
    puzzle 4's chasm behind it, so a long hold carries on into that chasm. This is inferred
    from the landing x and was not run.
- **The far bank is a one-cell cul-de-sac.** The new room comment says the way back is "a
  drop onto the ledge". Walking off the far bank lands in the pool (-1 hp, respawn on the
  far bank). A running jump left with left released at ~1.2 s lands on the ledge
  (x 9294), but Ivo is over the ledge for under 0.2 s of his fall. It is a precise jump,
  not a drop.
- **Safe ground after a failed crossing.** In the 4 s-late run, Ivo landed on the near bank
  already moving right and never had both 16 px probes on it. The respawn therefore went to
  the ledge, not the bank. That is fine for a retry. Not a bug.
- **Camera at the new right bound (x 9600).** The camera stops scrolling as Ivo nears the
  far bank: with Ivo at 9526, the view spans ~8966-9606. The stone wall (cols 73-74) fills
  the last 64 px, and there is no void past the edge (`crossing_18.00.png`, the `s_after`
  frames). How smooth the stop is cannot be judged from frames. During the climb the camera
  follows the jumps up, so the second jump's frame is mostly trees.
- **Backgrounds.** Only the two front tree layers show, and below the tree line (world
  y ≈ 6064) the background is a flat clear-colour band behind both chasms. That matches
  `gotchas/parallax2d-ignores-its-parents-offset` (written 2026-10-07 by another session):
  the 0.1-0.4 layers drift off screen because the region sits at x 7200. Puzzle 4's chasm
  shows the same, so PZL-08 did not introduce it. Not re-filed.
- **Bug: the strands meet at a 4 px step.** The far bank's strand draws 4 game px above the
  near bank's on every joined bridge (`strand_step_at_the_join_4x.png`). Filed as
  `bugs/root-bridge-strands-meet-at-a-step`.
- Minor, not specific to PZL-08: Ivo pressed against the far wall stays in the `run` clip
  at zero velocity.
- Minor: the pool stays flush with the ledge top (y 6160) through the rain. Ivo stands at
  the waterline unharmed, and it reads correctly.
- Harness noise: every run printed `No loader found ... empty_house.room`. It comes from
  another session's untracked solstice-trial work and does not touch this room.

## Ratings rationale

- **Fun 3 (low confidence, inferred).** The composition is legible: the dry try shows
  nothing, then rain plus roots spans the gap, which is what §7.4 promises. The deadline
  is a race that only perfect scripted input clears with any comfort. A person who watches
  the rain or fumbles a note is likely to fail, and the failure state (the bridge gone from
  under him) is not explained on screen beyond the rain stopping.
- **Fluidity 3 (inferred from timing).** Two jumps onto one-cell stone with release windows
  of about 0.2-0.3 s, inside a ~3 s hesitation budget. The shortcut through the bridge
  helps. Input latency and how the jumps feel are not judged.
- **Aesthetics 3.** The rain, the green pulse and the braided bridge read well, and the
  right edge is clean. The 4 px strand step and the flat background band under the tree
  line are visible in most frames.

## Follow-up (2026-10-07)

The user chose "Unida, segura": wet earth is needed to reach, not to hold, so a joined
bridge stays while Enraizar's pulse covers its faces (`RootSpanView.advance`). Re-run of
`song_rain_root_wet_bridge_late.json`: Ivo reaches the far bank at t 20.47 with hp 3, and
the bridge is still whole at t 23.0, past the 20.3 at which the rain used to break it.
The slack is now Enraizar's 12 s sustain, not the rain's.
