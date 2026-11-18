---
id: bugs/a-jump-over-the-mentor-wakes-zone-skips-the-awakening
type: bug
title: The lantern's MentorWakesZone is 100 px wide, so a running jump, a roll or a swing carries Ivo across it without the awakening starting, and he reaches a still keeper with no fight
status: fixed
severity: medium
tags: [story-38, cutscene, trigger, zone, lighthouse, mentor, finale]
related: [architecture/story38-the-keeper-wakes, systems/cutscenes, systems/story, bugs/a-hop-at-the-bridge-turn-back-replays-the-line]
created: 2026-11-17
updated: 2026-11-17
source_files:
  - scenes/world/rooms/frost_edge/contents/lighthouse_top_contents.tscn
  - scenes/world/cutscene/cutscene_director.gd
  - scenes/world/cutscene/cutscene_trigger.gd
  - scenes/characters/ivo/player.gd
---

## Symptom

Found in the STORY-38 review (2026-11-17, uncommitted). With the four guardians restored, Ivo comes up the hatch
(col 36, x 1168) and runs west. If he jumps anywhere east of x 940, he lands west of x 840, beside or past the still
keeper (x 720). The awakening does not play: the keeper stands in StillAtLamp, the guardian body stays absent and no
fight begins. Nothing happens until he walks back east and stands in the strip on the floor. The same happens if he
rolls through it, or swings the sword while crossing it.

`systems/cutscenes` ("The keeper wakes") and the plan say the zone is full height "so it cannot be jumped over". The
height is real, but height does not stop a jump.

## Root cause

`CutsceneDirector._tick_trigger` (`cutscene_director.gd`, the `ivo.can_begin_scene()` gate) starts a zoned scene only on
a tick where Ivo is inside the zone and `Player.can_begin_scene()` holds. That requires `_free_for_up(is_on_floor())`
(`player.gd:835`): on the floor, not rolling, not attacking. `MentorWakesZone` is x 840..940 (`lighthouse_top_contents.tscn`,
`wakes_zone_rect` 100 x 704 at x 890). That is narrower than every way Ivo crosses ground without touching it as free:

- a running jump covers 271 px (`docs/maps/README.md`, reach table), 434 px with the double jump;
- a roll is 0.37 s of not-free movement;
- an attack is not free for its whole swing.

The plan's first width (x 840..1100, 260 px) was narrowed to 100 px to shorten the pace-0.4 walk ("Built"). Even 260 px
would not cover a 271 px running jump.

`mentor_wakes_test.test_every_way_from_the_hatch_to_the_keeper_crosses_the_zone` checks only geometry: the zone spans
the floor between the hatch and the keeper, floor to roof. It never asks whether Ivo is grounded and free on some tick
inside it.

## Fix

Fixed 2026-11-17 (uncommitted). `MentorWakesZone` is now x 0..940, the whole room west of the hatch's pocket, floor to roof (`lighthouse_top_contents.tscn`, `wakes_zone_rect` 940 x 704 at x 470). Wherever a jump, roll or swing lands him on his way to the keeper, his first grounded, free tick starts the scene. The walk to `ivo_stand` runs at pace 0.6 (115 px/s), so the farthest landing a double jump allows (about 285 px off) walks in about 2.5 s. `mentor_wakes_test.test_no_jump_from_the_hatch_lands_past_the_zone` sweeps a running jump and a double jump (`MapGuide.ivo_reach()`) from every take-off between the hatch and the zone's east edge, every 4 px. It requires each landing to fall inside the zone and the walk from it to take 3 s or less; against the old 100 px strip it fails (a double jump from the hatch lands at x 756). `systems/cutscenes` no longer says the zone "cannot be jumped over".

Original direction: make the zone hold everywhere Ivo can land on his way to the keeper, not only one strip that he must touch
down in. For example, extend it west past the keeper to the lamp or the room's west wall (x 0..940). Wherever he lands,
his first grounded, free tick then starts the scene, and the walk brings him to `ivo_stand` (824) from either side. If a
far-west start makes the pace-0.4 walk too long, cap the walk instead: a faster pace, or a `CutscenePlace` when the
distance is large. Then extend the test: sweep a running jump and a double jump from every start between the hatch and
the zone, and require a grounded tick inside it.

## Prevention

A `CutsceneTrigger` zone that must catch Ivo "on the way" has to be wider than his widest grounded-free gap, which is
the running double jump (434 px), or it has to cover the whole area he can land in. A zone test must check grounded
reach, not only geometry.
