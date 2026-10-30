---
id: bugs/the-bloom-bark-balloon-falls-under-the-call-slot-onto-the-stags-body
type: bug
title: The Bloom guardian's bark balloon falls under the call slot and covers the stag's head and body
status: resolved
severity: medium
tags: [guardians, bark, balloon, story-18, bloom, ui, placement]
related: [systems/guardians, playtests/2026-10-30-grd08-story18-guardian-clips-and-talks, bugs/the-lucidity-leap-lands-outside-the-frame-so-its-land-clip-is-not-seen, architecture/guardian-performance-and-talks]
created: 2026-10-30
updated: 2026-10-30
source_files:
  - scenes/ui/balloon_placement/balloon_placement.gd
  - scenes/ui/bark_balloon/bark_balloon.gd
  - scenes/characters/guardians/bloom_guardian/bloom_guardian.tscn
---

## Summary

On every Bloom bark (5 of 5 in two fights) `BalloonPlacement.beside` finds both sides overlapping
the encounter slot and takes its fallback, "the first side under `avoid`". That puts the box at
y 172-230 game px, below the stag's head anchor (y ~152), so the paper covers the stag from its chin to its knees.
Only the antler tips and hooves show, and the tail points down into its chest. Frost is not affected:
its sheet stands aside, and all 8 Frost barks sat above the golem's head with the tail on it.

## Reproduction

`tools/playtest/scripts/guardian_fight_talk_driver.gd` with `guardian_bot_bloom.json` (max_duration 260),
`BOT_GOD=1`. `[bark]` lines:

| Bark | box (game px) | guardian screen x at open | slot |
|---|---|---|---|
| LUCID_0 | (380,172) 256x58 | 886 (off screen) / 679 | (158,40) 256x128 |
| LUCID_1 | (4,172) 250x34 or (386,172) | -40 / 671 | same |
| RETRY | (4,172) 180x34 | -42 | same |

The box never moves for the bark's 2.16 s. The stag settles at screen x ~91 or ~550, inside
the box's x range. Screenshot: `playtests/screenshots/2026-10-30-grd08-story18-guardian-clips-and-talks/bloom_bark_covers_the_stag.png`
(top: LUCID_1 at 35.61 s; bottom: LUCID_0 at 12.50 s).

## Cause

The Bloom stag is under `CENTRE_CLEARANCE`, so the sheet hangs centred above the pair (slot x 158..414,
y 40..168). Its head anchor (y -112) puts the wanted box (y ~90..148) inside the slot's band on both
sides: the east box is clamped back from the screen edge, and the west box overlaps the slot's left part.
The fallback `avoid.end.y + margin` then puts the box under the slot, and that is below the anchor. The
fallback assumes "under the slot" is still above the speaker, which is false for any speaker whose
head is above the slot's bottom (168).

## Fix direction (not decided)

Some options: when the box would sit below the anchor, place it beside the BODY (anchor y + box
height) on the side away from Ivo, outside the guardian's x extent; or shrink the bark to one row
for Bloom; or let the box overlap the slot's empty right half (the staff is on the left). This is a
placement/design call (GRD-09 is reworking the landing framing too).

## Fix (2026-10-30)

`BalloonPlacement.beside` takes the speaker's body (`body: Rect2`, art px) and, when both sides overlap the slot, picks
the free spot nearest the anchor (tail tip to anchor) among: above the head slid sideways off the slot, with the tail's
tip still under the box; or below the head beside the body (`GAP` outside `body`), lowered under the slot when needed,
with the tail rising from the box's top edge (`BalloonPlacement.tail_points_up`, drawn by `BarkBalloon._draw_box`).
A spot must be inside the screen unclamped, off the slot, and (below the head) off the body. The old "under the slot"
spot is kept only when nothing fits. `GuardianTalks` passes the guardian to `BarkBalloon.say`, which reads
`Character.body_rect()` each frame. The function stays pure.

For Bloom there is no room above the head: the 128-art-px box does not fit between the slot (x 79..207) and either
screen edge. The box now sits beside the stag's body on the side with room, its top under the slot (y 86 art px), the
tail up to the head. `bark_balloon_test.test_the_bloom_bark_keeps_off_the_sheet_and_the_stag` holds both landings
(head (275, 76) side 1 and (46, 76) side -1; slot (79, 20) 128x64; box 128x29): off the slot, off the body, inside the
screen, tail tip within 32 art px of the head.

Re-run (`guardian_fight_talk_driver.gd`, `guardian_bot_bloom.json` at 260 s, `BOT_GOD=1`): LUCID_0 settles at box
(266,172) 256x58 game px with the stag at x 549 (body from 533), LUCID_1 at (118,172) 250x34 with the stag at x 90
(body to 106). Both clear the stag and the sheet; Frost's barks are unchanged (above the crown). Screenshot:
`playtests/screenshots/2026-10-30-grd08-story18-guardian-clips-and-talks/fix_round_bloom.png` (top row).
