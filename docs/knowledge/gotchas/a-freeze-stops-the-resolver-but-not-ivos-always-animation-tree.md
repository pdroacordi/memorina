---
id: gotchas/a-freeze-stops-the-resolver-but-not-ivos-always-animation-tree
type: gotcha
title: A freeze stops Ivo's resolver but not his ALWAYS AnimationTree, so a one-shot playing at the freeze ends and holds its last frame
status: active
tags: [animation, animation-tree, pause, performance, memorina, story-11]
related: [systems/animation, systems/songs-and-the-memorina]
created: 2026-10-15
updated: 2026-10-15
source_files:
  - scenes/characters/ivo/ivo.tscn
  - scenes/characters/ivo/player_animation_resolver.gd
  - tests/scenes/characters/ivo/player_beat_test.gd
---

# A freeze stops the resolver but not Ivo's ALWAYS AnimationTree

During a performance or lesson `Ivo/AnimationTree` is ALWAYS, so `memorina_idle` loops while the tree is paused
(`systems/songs-and-the-memorina`, pause-mode map). The resolver picks clips in `Player._process_motion`, which is
pausable. Under the freeze the tree plays on, but nothing picks the next clip.

If the freeze starts while `memorina_draw` (a one-shot) is still playing, the tree finishes the draw and holds its
last frame for the whole performance, because the sequence to `memorina_idle` waits for the resolver.

Today this cannot happen. The draw is 0.33 s. The earliest freeze comes after a lesson's `lesson_lead_in` (0.5 s), or
after a song is matched: six notes at `MemorinaVoice.min_note_gap` (0.25 s) take at least 1.25 s.
`player_beat_test.test_the_draw_ends_before_the_earliest_freeze` fails if a longer draw, a shorter lead-in or a shorter
song breaks this.

**Rule:** any clip the resolver must leave on its own while Ivo is about to be frozen must end before the freeze can
start, or the freeze must start from a loop.
