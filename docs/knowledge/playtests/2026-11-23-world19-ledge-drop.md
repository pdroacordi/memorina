---
id: playtests/2026-11-23-world19-ledge-drop
type: playtest
title: WORLD-19 drop through `=` ledges - Down + Jump drops with the same latency as a jump, `-` planks never drop, the camera follows; the 6 px pop is followed by a near-stall of ~4 frames
status: active
build: a324c377 + uncommitted WORLD-19 working tree (LedgeDropComponent, LedgeDrop, player.gd, jump_component.gd, character.gd, ivo.tscn, room_legend); nothing under scenes/, resources/ or globals/ changed after this session's --import
area_tested: "orchard_terraces row-17 `=` span (cols 39-42, x -4512..-4384, top y -1376) and its earth block; village_tavern row-13 and row-17 `-` planks"
ratings: { fun: 3, fluidity: 3, readability: 4 }
tags: [world-19, one-way, ledge, drop-through, input, jump, camera, playtest]
related: [architecture/drop-through-ledges, bugs/the-tavern-upper-floor-has-no-way-down, systems/rooms, systems/input, gotchas/a-body-resting-on-a-one-way-cannot-be-pushed-down-into-it]
created: 2026-11-23
updated: 2026-11-23
source_files:
  - tools/playtest/scripts/world19_ledge_drop.json
  - tools/playtest/scripts/world19_ledge_drop_edges.json
  - tools/playtest/scripts/world19_plank_no_drop.json
  - scenes/characters/components/ledge_drop_component.gd
  - scenes/characters/ivo/player.gd
---

## Summary

WORLD-19 works as designed in every case tried. Holding Down and pressing Jump on the orchard_terraces `=` span drops Ivo to the floor below (y -1376 to -1248). The drop starts with the same input latency as a normal jump. Down + Jump on the tavern's `-` planks (row 13 and row 17) jumps and lands back on the plank. Both controls behave: Down + Jump on earth jumps, and Jump alone on the span jumps.

Feel notes (inferred from per-frame traces, not seen):
- The drop is a 6 px snap followed by a near-stall of about 4 frames.
- A refused drop near a ledge's end is a full jump.

No bug filed. Ratings are low-confidence: latency, the pop and the camera are measured from `trace`, and a human should confirm the feel.

## Setup

- Three timelines, one fresh `APPDATA` per run, one import before all runs, all windowed:
  - `world19_ledge_drop.json`: as written. Its positions were correct, so it was not changed.
  - `world19_ledge_drop_edges.json` (new, 7 cases): the edge, order, coyote, long-hold and running cases.
  - `world19_plank_no_drop.json` (new): the tavern `-` checks.
- Skills were empty, so there was no double jump. Every case logged a per-frame `trace`.

## Results

| Case | Input | Result |
|---|---|---|
| Drop, span centre (-4448) | Down, Jump 0.2 s later | Drops, lands y -1248.0 0.58 s after the press |
| Earth block (-4592, -1344) | Down + Jump | Jumps (peak 73 px), lands back at -1344 |
| Span, Jump alone | Jump | Jumps (peak 89 px), lands back at -1376 |
| Span east end (-4379, body half over open col 43) | Down + Jump | Drops, lands -1248 |
| Span west end (-4507, heel 6 px over col 38, earth block one row below) | Down + Jump | Refused: a full jump, lands back on the span |
| Jump then Down 0.05 s later | | Jumps |
| Down and Jump in the same frame | | Drops |
| Second Jump 0.15 s after the drop | | No rise (coyote spent; min y never above the ledge) |
| Down held 1.2 s, then Jump | | Drops (the camera had already peeked) |
| Running right, Down + Jump | | Drops and carries the run (lands x -4388, 112 px on) |
| Tavern row 13 `-` (2349, 12416) | Down + Jump | **Jumps, lands back at 12416. No drop.** |
| Tavern row 13 `-` | Jump alone | Jumps, lands back |
| Tavern row 17 `-` (2272, 12544) | Down + Jump | Jumps, lands back at 12544. No drop. |

No script errors in any run. The only warning was the known `lake_chasm.room` invalid-UID fallback (`playtests/2026-11-18-grd12-engine-regression`).

## Press-to-fall latency (measured)

- On the `_process` clock, the first frame with a changed y comes 0.031 s after the step's time in all three cases:
  - drop: step 1.400, moved 1.431;
  - earth jump: step 4.000, moved 4.032;
  - ledge jump: step 6.300, moved 6.331.
- In the edges run, every drop and jump moved on the first or second physics frame after the press. The drop adds no frame over a jump.
- What a player feels on a pad is not measured here.

## The 6 px pop (measured; visibility inferred)

- **Frame by frame.** In the press frame the feet go from -1376.00 to -1370.00. The next frames add only 0.14, 0.27, 0.41 and 0.54 px (vy starts at 0 and gains 8.2 px/s per frame). So the drop reads in data as **a 3-art-px snap, then about 4 frames of near-hang (~1.4 px in total), then the fall**. A normal jump's first frame moves 8.2 px and keeps going.
- **The camera moves with the snap.** `cam_centre` y moves the same 6 px in the same frame (-1423.4 to -1417.4). On screen, Ivo stays put for that frame, and the ledge and world shift up 3 art px under him. A jump's first frame shifts the camera more (10.3 px). The snap is therefore no larger than ordinary motion on screen.
- **Ask a human:** does the stall after it read as a hitch? If it does, a small initial fall speed would hide it. That is the implementer's call; architecture already mentions a one-frame crouch clip.
- **The frames.** Ivo is drawn in front of the ledge as he passes through it, in the fall pose with both arms up. That pose is different from the jump's rising pose, so the drop does not read as a jump ([screenshots/2026-11-23-world19-ledge-drop/drop_pop_before_after_2x.png](screenshots/2026-11-23-world19-ledge-drop/drop_pop_before_after_2x.png): left t 1.0 standing, right t 1.5, 0.1 s after the press).

## Camera follow (measured)

- **During the fall.** The camera leads the fall slightly: `cam_centre - feet` goes from -47 to -34 over the first 0.45 s. It then clamps at the room's bottom (-1332), 0.5 s after the press, before the landing at 0.58 s.
- **On screen.** Ivo stays in frame throughout. He lands 84 px below the view centre ([drop_landed.png](screenshots/2026-11-23-world19-ledge-drop/drop_landed.png)).
- **Down held longer than ~0.35 s.** The look-down peek begins. With Down held 1.2 s, the camera had already eased to the room's bottom before the press (max 4.2 px/frame), so the drop itself moved no camera ([long_down_peek_then_drop.png](screenshots/2026-11-23-world19-ledge-drop/long_down_peek_then_drop.png)). This works as a preview of the landing.
- **A quick drop (Down 0.2 s before Jump)** gets no peek.
- The smoothness of the follow cannot be judged from frames.

## Feel notes

- **A refused drop is a jump (by design, may surprise).** Standing within 11 px of the span's west end, where the body's heel is over col 38 with the earth block one row under it, Down + Jump launches a full jump instead of dropping. Ivo visibly stands on the span ([heel_west_refused_jumps.png](screenshots/2026-11-23-world19-ledge-drop/heel_west_refused_jumps.png)). On the tavern planks, too, Down + Jump is simply a jump ([tavern_plank_jumps.png](screenshots/2026-11-23-world19-ledge-drop/tavern_plank_jumps.png)). This matches the architecture ("plank jumps"). A player who tried to drop and was launched upward may still read it as a misfire. A no-op on refusal would be the alternative; that is a design question, not a defect.
- **The drop is silent.** `dropped_through` exists for a later sound. Audio was not measured.
- **Untested:** a drop with the double jump owned (a second press would double-jump back up through the ledge, by the architecture's choice), a drop in a gust, and a drop from a ledge with a creature below.

## What this cannot judge

Input latency as felt on hardware, whether the 6 px snap plus stall reads as a hitch at 60 Hz, the camera's smoothness, and the sound. The 3/5 fun and fluidity ratings come from the data alone and need a human pass.

## Previously filed

`bugs/the-tavern-upper-floor-has-no-way-down` is unaffected: the tavern planks are `-` and still do not drop (by the user's decision of 2026-11-22). Its stairwell remains the way down.
