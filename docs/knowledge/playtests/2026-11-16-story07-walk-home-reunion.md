---
id: playtests/2026-11-16-story07-walk-home-reunion
type: playtest
title: STORY-07 the walk home and the reunion - the restored world on the way, the daughter waiting by the window, her run, the five lines at zoom 2, her garden line after
status: active
build: 81293f71 + the STORY-07 step 5 tree (daughter stages, reunion trigger and scene, talks, intents), run in a scratch worktree holding exactly those files
area_tested: "world restored, all four guardians restored, the opening heard; tools/playtest/scripts/story07_walk_home_reunion.json: lighthouse_top, lighthouse_base, threshold_wayshrine and village_gate_east by teleport, then the square on foot to the house door, Up, the reunion scene, its talk (Z through five lines), then Right and Up on her for daughter_garden."
tags: [story-07, return, reunion, daughter, cutscene, dialogue, playtest]
related: [architecture/story-07-epilogue, systems/story, systems/cutscenes, systems/dialogue, systems/notices]
created: 2026-11-16
updated: 2026-11-16
ratings: { fun: 0, fluidity: 4, aesthetics: 3 }
screenshots:
  - screenshots/2026-11-16-story07-walk-home-reunion/w03_village_gate_east.png
  - screenshots/2026-11-16-story07-walk-home-reunion/w05_house_door.png
  - screenshots/2026-11-16-story07-walk-home-reunion/r01_reunion.png
  - screenshots/2026-11-16-story07-walk-home-reunion/r02_reunion.png
  - screenshots/2026-11-16-story07-walk-home-reunion/r05_reunion.png
  - screenshots/2026-11-16-story07-walk-home-reunion/r10_line.png
  - screenshots/2026-11-16-story07-walk-home-reunion/r14_line.png
  - screenshots/2026-11-16-story07-walk-home-reunion/r20_after_reunion.png
  - screenshots/2026-11-16-story07-walk-home-reunion/r21_garden_line.png
---

# STORY-07: the walk home and the reunion

## The walk home (teleports, then on foot)

- lighthouse_top and lighthouse_base: winter (frost_edge's own season), snow falling, the restored mentor on the gallery.
- threshold_wayshrine: winter, its region title shows on the first entry ("Threshold Road").
- village_gate_east and the square: the village in spring at 1.0, and the year's log reads `SPRING>SUMMER turn 0.00 advancing=true` outdoors, `advancing=false` once inside the house.
- What plays on the way cannot be judged from frames or the log: the runner logs no music (STORY-20 applies). Whether frost_edge is still silent after the final battle is unchecked here.

## The reunion

| t | logged / seen |
|---|---|
| 21.5 | Ivo at the house door (x 282), Up |
| 23.5 | inside: Ivo at the door (x 144), blocked; she waits at x 384 by the table under the window, her back to him |
| 24.5 | "!" over her; the frame already pairs them |
| 25.5 to 26.5 | she runs west (her walk at pace 1), he steps east to x 200 |
| 28.5 | the frame settles on the pair at zoom 2 |
| 30 to 43 | the five lines, the daughter's portrait and plate for hers; "You came back in colour." fits; line 05 wraps to two lines |
| 49 | rest: she stands at x 240 facing him (`Reunited`), the frame back at zoom 1, the guitar on its hook |
| 51.7 | Right a few px, Up on her: "The garden, Papa. She's waiting for the song." |

## Findings

- The first run logged `waiting is not found current state` as she entered: the new `waiting` and `reunited` clips were in the actor's library but not in its AnimationTree. Fixed (states added; `story_actor_test` checks every clip is a state) and re-run clean.
- The pair meets in front of the hearth (x 200 and 240): the hearth is a back prop, so they read in front of it, but the frame is busy behind them. A spot east of the firewood would need the guitar talk's cell (col 9). Left as is.
- Waiting by the window: the window hangs high (y 200) over the table, so at zoom 1 she reads as standing by the table rather than looking out. The `story_daughter_window` art (her back at the window) is the real fix.
- The run is a walk at pace 1, so it reads as a quick walk, not a run, until `story_daughter_run` lands.

## What this cannot judge

Audio on the way and in the house; whether the hold before the "!" (0.8 s) lands emotionally.
