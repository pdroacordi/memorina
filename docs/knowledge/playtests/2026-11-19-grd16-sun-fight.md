---
id: playtests/2026-11-19-grd16-sun-fight
type: playtest
title: GRD-16 Sun fight on the engine - bot and dodging-driver runs at a normal frame rate; the first runs were at ~4 fps and are void; the return fires after every stage-1 charge
status: done
tags: [grd-16, guardian, summer, sun, playtest, bot]
related: [systems/guardians, gotchas/scripted-presses-timed-in-real-ms-collapse-at-a-low-frame-rate, bugs/a-pinned-ivo-jumps-the-roaring-lion-only-in-a-frame-tight-window, bugs/the-sun-guardians-roar-never-fires, playtests/2026-11-18-grd12-engine-regression, playtests/2026-11-18-grd15-leaf-fight]
created: 2026-11-19
updated: 2026-11-19
area_tested: "caldera_arena (Sun Guardian): whole bot fight to RESTORED; the dodging driver to RESTORED with and without god mode"
source_files:
  - tools/playtest/scripts/guardian_fight_player_driver.gd
  - tools/playtest/scripts/guardian_fight_bot_driver.gd
  - resources/characters/guardians/summer_guardian/summer_guardian_stats.tres
---

# GRD-16 Sun fight

Runs one window at a time, `APPDATA` redirected per run and checked with a headless `OS.get_user_data_dir()` probe. Before each measured run the run script refuses to start while any other Godot process is running, and both drivers print the median real ms per frame every 600 frames (`[frame]`). Bot: `guardian_fight_bot_driver.gd` with `guardian_bot_summer.json` (double jump and wall climb owned, no roll: the Orchard kit), `BOT_GOD=1`. Driver: `guardian_fight_player_driver.gd`, extended for the Sun, with a 600 s copy of that timeline. It never double jumps or rolls, so every dodge it shows is walking and a single jump. It backs out of the claw string (with a spot behind it or pinned, it jumps the claws late in their wind-up and the bite early in its), jumps the charge and its return 0.34 s before the box arrives, backs out of the roar (pinned, it jumps over the lion holding toward it), steps between the embers, steps out of each sun shaft 0.3 s before it burns, steps out of the pounce's shadow and jumps its embers. It swings from outside the guardian's contact box (body half width + 30 px) and only once stopped, holds ground before a spot toward the guardian, logs what hurt Ivo (`[src]`), and ends a no-god run 3 s after Ivo dies. Numbers are from the final kit (systems/guardians, "The Sun Guardian's fight").

## The first runs are void

The runs before the review (`bot1`, `bot2`, `pl1`-`pl6`) ran at about 4 fps: frames came every ~250 ms, because several Godot instances ran at once (a review's probes in parallel with these runs). Game time ran at about 60 % of real time, the driver decided once every ~10 physics steps, and the scripted answer's notes, scheduled in real ms, bunched inside `MemorinaVoice.min_note_gap`, so a note was dropped and the window timed out (`gotchas/scripted-presses-timed-in-real-ms-collapse-at-a-low-frame-rate`). Every number from those runs is withdrawn: the hits, the "hardest of the four", the stage-0 deaths and the answer timeouts. Both drivers now pace the answer's notes on the physics clock (0.45 s of game time apart, and only when the voice will take one), for every guardian.

## Bot (`bot3`, median 5-6 ms per frame)

| run | restored | hits | causes (move current when hit) |
|---|---|---|---|
| GRD-12 regression (old kit) | 70.1 s | 32 | contact 23 |
| GRD-16 final | 56.6 s | 16 | contact 6, claw 4, ember spit 2, charge 2, roar 1, sun shafts 1 |

The bot attacks and never dodges, so the window opens after 24 s and 8 s of pressure. Both answers were good. The roar fired once.

## Dodging driver (median 5-6 ms per frame)

With god mode (`pl7`, `pl10`) and without (`pl11`); `pl9`, without god mode on the driver before it jumped the claws with a patch behind it, died at 37.0 s (3 claw hits, each with an ember patch behind the driver).

| run | stage | pressure | busy | idle between moves | strings |
|---|---|---|---|---|---|
| `pl7` (god) | 0 | 46.9 s | 68 % | mean 0.81 s, max 1.57 | ember spit 6, charge 6, claw 4, roar 2 |
| | 1 | 48.0 s | 80 % | mean 0.58, max 1.11 | ember spit 3, charge > return 3, roar 3, claw 3, sun shafts 2, pounce slam 2 |
| `pl10` (god) | 0 | 30.0 s | 70 % | mean 0.71, max 1.15 | claw 4, charge 4, ember spit 3, roar 1 |
| | 1 | 38.0 s | 81 % | mean 0.58, max 1.08 | charge > return 3, roar 3, sun shafts 2, claw 2, ember spit 1, pounce slam 1 |
| `pl11` (no god) | 0 | 33.0 s | 67 % | mean 0.80, max 1.27 | claw 4, ember spit 4, charge 3, roar 2 |
| | 1 | 28.3 s | 80 % | mean 0.64, max 1.43 | charge > return 3, roar 2, ember spit 2, sun shafts 1 |

| run | restored | hits by source |
|---|---|---|
| `pl7` (god) | 119.5 s | 5, the claw's box, each with an ember patch behind the driver as it backed off (before it jumped the claws there) |
| `pl10` (god) | 92.7 s | 1, a sun shaft |
| `pl11` (no god) | 86.0 s | 0 |

Every answer was good. The roar fired 5, 4 and 4 times. **The return followed every stage-1 charge (9 of 9)**: turned after passing the driver in the open. In the god runs no string was over 33 % of a stage; in `pl11`'s short stage 1 (8 strings) the charge and its return were 3. No two strings alternated, but with `recent_strings` 2 and four stage-0 moves the same three (claw, charge, ember spit) can come round two or three times running; the claw string chained into the second claw in none of these runs, because the driver backs out of the first claw (or jumps it, which ends the string).

## After the feel pass (final kit, 6 ms per frame)

`playtests/2026-11-19-grd16-sun-feel` found four faults. They were fixed in the same change: the floor moves wait for the
embers, the charge stops 80 px past Ivo, the second claw steps in, `far_walks_in` is on and `recent_strings` is 1, the
wind-ups use the strips' most distinct frames, and a death stops a lunge. The driver took the playtester's additions
(`PL_KIT`, `PL_CHARGE=roll` toward the lion, `PL_BOXED`, `PL_PJ`, `PL_FORCE_SEQ`, quitting after a death). Timelines:
Orchard kit `skills [0, 1]` (it jumps the charge), Lake kit `skills [2]` (it rolls through it); `PL_BOXED=1 PL_PJ=1`.

| run | kit | god | restored | hits | stage 0 busy / idle | stage 1 busy / idle | stage-1 returns |
|---|---|---|---|---|---|---|---|
| `og2` | Orchard | yes | 91.4 s | 0 | 71 % / 0.74 s | 75 % / 0.55 s | 2 of 2 |
| `on2` | Orchard | no | 78.7 s | 0 | 69 % / 0.80 s | 79 % / 0.61 s | 3 of 3 |
| `lg2` | Lake | yes | 104.4 s | 1 (a sun shaft) | 68 % / 0.74 s | 78 % / 0.57 s | 4 of 4 |
| `ln2` | Lake | no | 81.5 s | 1 (a sun shaft) | 72 % / 0.68 s | 78 % / 0.59 s | 2 of 2 |

Strings by stage (`og2`, `on2`, `lg2`, `ln2` summed): stage 0 claw 12, charge 11, ember spit 10, roar 7; stage 1 claw 14,
ember spit 12, charge > return 11, roar 10, pounce slam 5, sun shafts 4. No three-move order came round more than twice
running (the feel pass's Lake run had 7 repeats of spit, charge, claw in 19 strings). The roar fired 3-5 times a fight.
With the earlier `recent_strings` 2 (`og1`, `on1`, `lg1`, `ln1`), `ln1` repeated spit, charge, claw three times
running. The return followed every stage-1 charge in all eight runs (15 of 15 rolled through, 11 of 11 jumped).

- **Bot** (`bot5`): restored at 44.4 s with 12 hits (5 body contact, 4 claw, 2 ember spit, 1 charge). It stands and
  swings, so the claw string chained 4 of 4 and reached the bite twice.
- **The claw string still never chains against the driver** (0 of 26 claws). The driver backs off through the whole
  claw and is 200-230 px away when it ends, past the second claw's 190, or it jumps the claw, which ends the string.
  The second claw's range is capped by the on-screen rule (190 plus its wind-up's 120 px drawn back).
- **Spit, then pounce, forced** (`fs2`, `PL_FORCE_SEQ=1`, god mode): 11 pounces. The floor gate put a charge (10) or a
  claw (1) between the spit and the pounce every time; all 11 wound up with no live patch, and none hit.

## Found and fixed

- **Every range had to shrink to keep the lion's wind-ups on screen.** Its drawn tail reaches up to 130 px behind its feet, so a move thrown from 300 px (the old charge) winds up with half the lion off the 640 px view. Ranges are now at most 320 less each wind-up clip's drawn back, measured on the textures (`test_every_move_is_thrown_from_on_screen`): 208 or less.
- **The bite's first frames drew 90-108 px but its box reached 132** (`combat_reach_test`): it plays the leap's longest-reaching frames (leap 5-6, 122-124 px).
- **The wall bounce was rarely reached** (0 of 22 stage-1 charges in three of the void runs; it needs Ivo near the wall the charge runs at). User, 2026-11-19: "Turn after passing Ivo (Recommended)". The charge's lunge went from 460 to 400 px/s so it always ends inside its return's 208 px range.
- **The roar's pinned single-jump answer had a 0.07 s window** (`bugs/a-pinned-ivo-jumps-the-roaring-lion-only-in-a-frame-tight-window`): its body hurt through the wind-up. `body_contact` is false on the roar.
- **The sun shafts outlived the lion's rear**, so the next move's wind-up began while shafts 3-4 still burned. The lion rears for 2.85 s, until the last has burned out.
- **A pinned Ivo who jumped the charge could land into its box**, still open with the lion stopped against the wall. A no-contact move stopped by a wall after a 32 px run spares Ivo for the rest of its strike (engine; `guardian_contact_test`). Not seen in the final runs, which were never pinned under a charge.
- **The sun shafts' warning was a flickering light/dark line** that read as nothing on the dark caldera stone; it is a light core in a dark rim plus the shared floor warning.
- **Driver only:** it swung from 64 px, inside the lion's 74 px contact; it walked into ember patches while closing in; it backed off from a claw into a patch behind it (it now jumps the claw); it jumped the charge with the Frost's 0.24 s lead, late for the lion's 90 px box top (0.34 s now).

## Not fixed

- **The claw string does not chain against a player who backs off through the whole claw** (above). Options: accept
  it (backing off is the claws' answer), or let the second claw reach further than the on-screen rule allows.
- **The tail tip can be off screen during a charge** (the camera's look-ahead): cosmetic, the head is in view.
- **The contact box is the lion's whole 132x72 body.** A player who walks into it is hit; the engine spares one the lion skidded or charged onto (`GuardianBodyContact`). At a normal frame rate the driver was not hit by it once.

## What screenshots cannot show

- Whether the sun shafts' order reads at speed: each is lit 0.6 s and burns 0.3 s, one at a time; the driver stepped out of 19 of 20 in the final runs.
- The lion's walk now runs at 120 px/s on a clip drawn for 84: its feet slide (GRD-18 / GRD-11).
