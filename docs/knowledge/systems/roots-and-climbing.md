---
id: systems/roots-and-climbing
type: system
title: Enraizar's roots and climbing
status: active
tags: [root, climb, enraizar]
related: [architecture/roots-join-earth-to-earth]
created: 2026-10-02
updated: 2026-10-02
source_files: []
---

# Enraizar's roots and climbing

Moved verbatim from `CLAUDE.md` ("Roots and climbing") on 2026-10-02.

Design 02 section 7.1: Enraizar's one rule is **roots join earth to earth**.

- **Where** is read once per pulse from the room's own map (`RootSpanFinder`, pure, tested): a BRIDGE between the tops of two earth banks facing each other across air (banks, not walls: both have air above), a SHAFT where two earth walls face each other across a narrow gap for several rows, a PILLAR from an earth floor to an earth ceiling. Stone never roots - the material tells the player where the song works - so a ledge that must not grow anything is stone.
- **What grows** is decided every frame by `RootGrower` (the song's `PulseEffect`) through one `RootSpanView` per span: two strands per crossing (`RootStrands`, pure, tested) grow from both faces while each face is inside the pulse's CLEAN disc, at the memory under each tip, sharing the gap when they would pass; a face the pulse leaves withers its root back, so a joined span breaks at its tips first. Joined, a bridge is a one-way floor (toggled deferred) and a shaft's rungs and a pillar are `Climbable` shapes, one per rung. Only the pillar under Ivo's own feet grows. Wet earth (inside a Chuva pulse at both faces) lets a bridge reach `wet_bridge_cells` instead of `max_bridge_cells`. The strands are drawn from `root_strand.png`, repeated along the line and centred on it by the sprite's LOCAL offset (a rotated sprite's art otherwise falls on the other side of its line).
- **Enraizar's pulse is its own** (`root_pulse_stats.tres`, 280 px): its radius is the puzzle - the root bridge is covered from one low stone ledge and not from the near bank.
- **Climbing is a state, not steps** (the user's choice for the shaft): `Climbable` (an Area2D on physics layer 3, `grip` WALL or POLE) is only a place; `ClimbComponent` (generic, in components/ - nothing gates it but the roots) is the holding: climb speed in any direction, no gravity, a pole pulls the body onto its axis, and it reports how it came off (`Exit.LET_GO` falls; `Exit.OVER_THE_TOP`, climbing out of the top with up held, hops `top_hop_height` onto the ledge). `Player` owns the judgement: up held grabs (`_try_climb`, not while rolling, hurt or playing), a jump from a hold is a ground jump, a hit knocks him off (`MotionState.CLIMB`). `PlayerAnimationResolver` has `climb` / `climb_hold` (a wall, from the side) and `climb_back` / `climb_back_hold` (a pole), above the airborne block; the sheets are the template's climb strips at 2x.
