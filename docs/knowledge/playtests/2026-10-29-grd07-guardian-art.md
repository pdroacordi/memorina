---
id: playtests/2026-10-29-grd07-guardian-art
type: playtest
title: GRD-07 - the tree-stag and the ice golem in our own art; the fights still work, Bloom is no easier, and two pre-existing fight bugs surfaced
status: active
build: 526b1b9 + uncommitted GRD-07 (before = a git archive of HEAD 526b1b9, pack art); Frost give_ground_distance 101.5 for the first 4 runs, 98 from 17:16
area_tested: "spring_woods/bloom_hollow (Bloom at world x -6240, Ivo from -6560), frozen_lake/lake_frost_arena (Frost at 5280, Ivo from 5130), the notebook's Guardians tab (winter trial)"
tags: [guardians, art, grd-07, bloom, frost, recall, lucidity, notebook, playtest]
related: [systems/guardians, systems/notebook, bugs/a-recall-jump-pressed-during-a-swing-counts-a-step-without-jumping, bugs/a-pogo-on-the-frost-golems-head-stops-it-attacking, bugs/the-frost-gives-ground-after-a-swipe-it-walked-in-to-throw, playtests/2026-10-14-core11-sword-reach]
created: 2026-10-29
updated: 2026-10-29
ratings: { fun: 3, fluidity: 3, aesthetics: 4 }
screenshots:
  - screenshots/2026-10-29-grd07-guardian-art/bloom_lash_burst_recall.png
  - screenshots/2026-10-29-grd07-guardian-art/bloom_pounce_and_lash_crops.png
  - screenshots/2026-10-29-grd07-guardian-art/bloom_leap_and_call.png
  - screenshots/2026-10-29-grd07-guardian-art/bloom_colour_lucid_restored.png
  - screenshots/2026-10-29-grd07-guardian-art/bloom_hurt_flinch.png
  - screenshots/2026-10-29-grd07-guardian-art/frost_swipe_slam_charge.png
  - screenshots/2026-10-29-grd07-guardian-art/frost_slam_hits_during_raise.png
  - screenshots/2026-10-29-grd07-guardian-art/frost_colour_breathing.png
  - screenshots/2026-10-29-grd07-guardian-art/frost_call_sheet.png
  - screenshots/2026-10-29-grd07-guardian-art/frost_hurt_charge_walk_strips.png
  - screenshots/2026-10-29-grd07-guardian-art/frost_restored.png
  - screenshots/2026-10-29-grd07-guardian-art/notebook_portraits.png
---

## What was tested

- **Kept as they are:** `core09_bloom_exchange`, `core09_frost_exchange`, `core09_frost_close` and
  `core11_frost_cadence`. Their timings still fit the new art: the moves telegraph and swing at the
  same instants as in CORE-11 (pounce 1.23 / 5.12 s; swipe 1.11 s, then 4.94 s, charge 8.12 s). The
  three Frost timelines were run again after a sibling changed Frost's `give_ground_distance` from
  101.5 to 98 (17:16). The traces were identical to 0.1 px except the third step-in, which moved 3 px.
- **Not repaired: `bloom_guardian_full` and `bloom_guardian_call`.** They predate WORLD-05 and the
  recall. They set no `player_position`, so they start in village_house, and their hard-coded
  answer times cannot follow a fight that now has a recall and two calls. They are replaced by a
  closed-loop driver,
  **`tools/playtest/scripts/guardian_fight_bot_driver.gd`**, with the setups `guardian_bot_bloom.json` and
  `guardian_bot_frost.json`. The driver fights by policy:
  - it approaches and combos in PRESSURE, and presses the armed recall's own action;
  - on `call_window_opened` it draws and plays `stats.song.notes`;
  - it logs phase, move, hitbox open/shut with dx, hp, the guardian's texture/frame/flip, and the
    screen position of every event screenshot.
  It played both fights end to end: Bloom in 40 s, Frost in 60 s, two answers each, lesson,
  RESTORED. `BOT_GOD=1` topped Ivo up at hp 1, so hp numbers in those runs are hits taken, not
  survival.
- Difficulty against HEAD: the same driver with a "poke" policy (hold 68 px, step out of the lash,
  roll under the pounce) and a passive one (walk to 70 px and stand) on both trees. A "bounce"
  policy (double-jump onto the golem and pogo) on both trees.
- The notebook's Guardians tab (`grd07_notebook_guardians.json`, met and restored [0, 1]). Frost
  RESTORED in its arena (`restored_guardians`).
- Each sheet checked with Pillow, every frame of every strip: feet on the bottom row, and the
  lower-body centroid against the frame centre.

## Findings: Bloom (tree-stag)

- **Spacing is as specified.** In its cooldown it paces at 81-103 px (comfort 82), outside Ivo's
  77.5. The scripted step-in lands the slash at 70.5 px and the chop at 50.8 (hits 0.14, 0.29), and
  it gives ground once he is at 46. `core09_bloom_exchange`: both pounces rolled under, Ivo at full hp.
- **The lash connects every time it is thrown.** It is telegraphed at 49-51 px and hits a grounded
  Ivo on the hitbox's first frame, 4 of 4 times. It does not read as a strike, though
  (`bloom_lash_burst_recall.png`, `bloom_pounce_and_lash_crops.png`). The strike frame leans the stag
  in and reaches one thin arm to Ivo's head height, with no smear. At 1x it is Ivo's red flash
  that says "hit". The art flag "lash weak" is confirmed. The telegraph's red tint does read.
- **The fight is no more passive and no easier than on HEAD.** A standing Ivo is not left alone:
  the stag walks in from 70 to 50 px and lashes, pounces again, and kills him at 12.8 s in both
  builds (pounce, lash, pounce: hits at 1.5/1.6, 5.6/5.8, 12.8 s). Against the poke policy neither
  build ever lashes (Ivo never stands inside 52 px). Both take 0 damage, and both open the first
  window at 10-11 s. The GRD-07 build fills the second bar a little slower (0.63 at 35.9 s against
  0.88 on HEAD) because Ivo's reach on the slimmer body fell to 77.5. A reach shorter than Ivo's
  is not exploited by a simple spacing policy: the stag's pounce (range 220) and the burst cover
  the gap. Whether that feels fair in the hand needs a human.
- **The burst still launches Ivo for the double-jump recall** (`bloom_lash_burst_recall.png`, frames
  16-21). The recall opens at the swing start. With the presses held back until the launch, the
  hitbox opens at 59 px and lifts him, and two airborne presses recall the double jump. Unchanged.
  The burst art (arms out, a leg kicked back) shows no ground shock, so the launch has no visible
  cause. Art flag "stamp weak" confirmed.
- **The pounce lands on him.** Every pounce that was not rolled under hit, either as it came down on him or through contact as it landed. The leap clip reads as a jump with a
  tucked knee (`bloom_pounce_and_lash_crops.png`).
- **Lucidity leap and landing with the taller body** (`bloom_leap_and_call.png`). The stag springs
  from the lucid pose and its whole 120 px body clears the top of the frame (feet at screen y
  -65 at the apex). It comes down 440 px from Ivo. The touchdown happens just outside the frame
  (screen x 882 of 640). The camera then pairs and the stag slides in with a dust puff about
  0.2 s later. That was the design before GRD-07 too (`features/lucidity-leap`).
- **The call sheet and the shield cover the stag** (`bloom_colour_lucid_restored.png`). The sheet
  hangs above the pair on Ivo's side and never overlaps the stag. Each call note breathes colour
  over the whole stag, from the blossoming antler tips to the hooves. Between notes it falls back
  to grey. In the relapse and RESTORED the stag is fully coloured. The radius 20 x height 40
  shield is enough.
- **Lucid and restored play their own strips** (`[spr]` log: `bloom_lucid` from the phase change,
  `bloom_restored` from 39.06 s, looping fr 0-3). At game scale both are hard to tell from idle:
  the differences are a few pixels of arm and head.
- **Hurt flinch** (`bloom_hurt_flinch.png`): a red flash and a small lean back. In 5 of its hurt
  plays the stag's `flip_h` changed mid-clip (it was giving ground or pacing). The strips are
  centred to within 1 art px, so a turn does not jump the body, but the stag flinches facing away
  from Ivo.

## Findings: Frost (ice golem)

- **Feet sit on the floor.** Every frame of every strip has its lowest opaque row at 127, and with
  the Sprite2D at y -128 the feet meet the snow line in every frame seen. There is no float and no
  sink (`frost_swipe_slam_charge.png`, `frost_restored.png`).
- **The swipe lands on a grounded Ivo close in and at ~100 px.** It hit at 46 px
  (`core09_frost_close`), at 72-73 px (bot) and at 84.4 and 101.4 px (`core11_frost_cadence`), in
  the hitbox's first two to nine frames. A step back to 115 px dodges it, and the punish lands
  slash 62.6, chop 73.8 and a third at 73-76 px (`core09_frost_exchange`, 3 of 8, as in CORE-11).
  The strike frame reads: the arm sweeps across in front of the body at head height.
- **The charge plays its own clip and still opens the roll recall.** It plays `frost_attack_2`
  (14 frames) and the recall opens at its swing start. A roll 0.1 s later recalls ROLL and carries
  Ivo through the golem (x 5216 -> 5358). The shoulder ram is subtle: in the strip
  (`frost_hurt_charge_walk_strips.png`, middle row) it is barely different from idle. Art flag
  "charge subtle" confirmed. Low: once the recall is learned, every charge that hit (3 of 3) hit
  through the **contact** box at 41-42 px, a frame before the shoulder box opens at 0.5 s. So the
  charge's own 520/160 knockback never applies, only contact's 460/120. On HEAD the swipe box
  opened on the same frame Ivo was reached (42.8 px), so the hit was a coincidence there too.
- **The slam hits a grounded Ivo, but before the fists come down** (`frost_slam_hits_during_raise.png`).
  It was thrown at 72-75 px and hit 4 times out of 4, each on frame 6, with both fists raised
  overhead. The fists strike the ground on frames 7-8, after Ivo has been knocked away. It reads as
  being hit by the wind-up. The doc records the frame-6 column on purpose. It is a readability
  note for the art flag "slam patched".
- **The slam does not swat a bouncing player**, in either build. A double jump onto the golem
  followed by pogoes got no slam in 20 s on GRD-07 (two runs), and one missed slam per run on HEAD.
  The golem walks out from under him and throws nothing for 6-14 s. The cause is the AI's overhead
  rule (150 px reach, 176 px body), not the art:
  `bugs/a-pogo-on-the-frost-golems-head-stops-it-attacking`.
- **Colour in the grey** (`frost_colour_breathing.png`): each note saturates the crystals and body
  blue. At the shield's rest level the trailing fist and the outer shoulder crystals stay grey,
  and the colour reaches them only at a note's full swell. Low. The fists are narrower than the
  old golem's, so this was not made worse.
- **The call sheet** (`frost_call_sheet.png`) hangs top-left on Ivo's side, clear of the 184 px golem.
- **Lucid and restored play their own strips.** RESTORED loops 6 frames. Low: on a later visit the
  restored golem stands facing east, its back to Ivo entering from the west (`frost_restored.png`).
- **Walk twists** (strip, bottom row). Frames 4-9 turn the golem from three-quarter to a narrow
  side profile and back, so in a pace it seems to rotate. Art flag confirmed.
- **Hurt** plays only when a hit lands while the golem is neither telegraphing nor swinging. That
  happened in 5 plays across the full fight. The strip flings an arm forward (centroid shifts 8 art
  px), which reads more as a reach than a recoil. It never flipped mid-clip.
- **The golem turns its back while giving ground** (`core09_frost_exchange` d4, the punish chop
  lands on its back). It also turned its back in the CORE-11 build's pacing.

## Notebook

`notebook_portraits.png`. Both portraits fit their page slot: the whole stag (24x60) and the golem
from the waist up (60x60), with no clipping into the list or the text. A corrupted guardian shows
greyed, a restored one in colour. The Bloom portrait is visibly narrower than the Frost bust, as
designed.

## Bugs filed

- `bugs/a-recall-jump-pressed-during-a-swing-counts-a-step-without-jumping` (medium, pre-existing).
  A jump pressed while Ivo is still in a sword swing when the burst's recall opens counts as step
  1 but does not jump. The airborne-only last step then cannot be given, and the recall is
  missed. Seen on all 3 bursts that came mid-combo, across 2 runs.
- `bugs/a-pogo-on-the-frost-golems-head-stops-it-attacking` (medium, pre-existing, both builds).
- `bugs/the-frost-gives-ground-after-a-swipe-it-walked-in-to-throw` was already filed by the review
  and fixed (98). Re-run on 98: the cadence swipes start at 102.7 / 101.4 px, as before, and the
  follow-up retreat is hidden by the swipe's knockback in every run here.

## Ratings rationale

- **Fun 3** (mostly inferred). Both fights play end to end with the same loop and cadence as
  before. Measured difficulty is unchanged against HEAD under two simple policies. The lash and
  the burst no longer show what hits Ivo, which costs readability rather than fairness.
- **Fluidity 3.** No stuck states or new flips in the traces. The stag still turns during its
  flinch, and the recall-during-swing miss is an old trap that the closer stag makes more likely.
- **Aesthetics 4.** Both guardians are clearly ours and fit their arenas. The golem's palette reads
  as ice in the grey cave, and the stag's blossoms are the one warm note in the grey woods. Docked
  for the four weak clips (Bloom lash and stamp, Frost charge, Frost walk twist) and the slam's
  timing.

## What screenshots cannot show

- Audio: the groan, the octave-down voice.
- How the leap reads in motion: the stag is off-frame for about 1.5 s.
- Whether a 77.5 px reach against a stag that paces at 82 feels like a fair dance or a chase.
- The weight of the golem's walk.
- Input latency and camera smoothing were not judged. Every bot press reacted to state, so
  "connects" means the game state agreed, not that a person could read it in time.
