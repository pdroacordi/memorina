---
id: bugs/ivos-greyhush-shield-colours-a-creature-in-melee-range
type: bug
title: Ivo's GreyhushShield lights every creature-pass pixel inside it, so a corrupted creature turns half orange (scorpion) or brown (boar snout) whenever it is within sword reach
status: resolved
severity: medium
tags: [core-13, creatures, greyhush, greyhush-shield, creature-pass, rendering, corruption-edge]
related: [systems/creatures, systems/greyhush, architecture/corrupted-creatures, playtests/2026-10-29-core13-boar-and-scorpion, bugs/creature-pass-bilinear-blur]
created: 2026-10-29
updated: 2026-10-29
source_files:
  - scenes/characters/components/corruption/corruption_edge.gdshader
  - scenes/world/memory/unshielded_mark.gdshaderinc
  - scenes/world/memory/greyhush_shield.gd
  - scenes/world/memory/greyhush_creatures.gdshader
  - scenes/world/memory/greyhush_common.gdshaderinc
  - scenes/characters/ivo/ivo.tscn
  - scenes/characters/components/corruption/corruption_edge.gd
---

## Summary

Corrupted creatures have no `GreyhushShield`; the creature composite greys them by the memory
field ("colour reads as friend, grey and fraying as foe", `architecture/corrupted-creatures`
§5). But Ivo's own shield (`ivo.tscn:2547`, SILHOUETTE, capsule radius 26, height 16,
feather 12, amount 1.0, centred 29 px above his feet) lights *every* creature-pass pixel
inside its shape, not only Ivo's. So in a grey region, every pixel of the creature within
about 38 px of Ivo's chest shows its full art colour. That is the melee range. Seen in the
2026-10-29 playtest.

## Symptom (reproducible)

- `caldera_bait`, bait scorpion (memory grey): when Ivo stands in strike range (dx 39-45),
  the scorpion's claws and front legs draw in full orange and red. The tail and the rest of
  the body stay pale grey. The creature is split at a soft circular edge around Ivo's chest.
  `screenshots/2026-10-29-core13-boar-and-scorpion/scorpion_coloured_inside_ivos_shield.png`
  (left: Ivo at dx 39; right: the same scorpion with Ivo knocked 75 px away, all grey).
- During a pogo, the raised stinger tip turns orange while Ivo is still ~50 px above it
  (`scorpion_pogo_front_trade_tail.png`, frame p09.30 of each row).
- `threshold_bridge`, boar (memory 0.3): the snout and tusk next to Ivo draw in brown
  (`boar_snout_coloured_inside_ivos_shield.png`, left), and the boar is uniformly grey with
  Ivo away (right).
- Summer trial lure scorpion, after its shadow is gone and the grey is back: the same orange
  front appears once it reaches Ivo (slip_20.50 in the session's run).

Repro: `core13_scorpion_bait`-style approach (spawn -6128, 1814, walk right 1.2-2.2 s and
3.0-3.45 s, stand). Every frame from the tell at ~3.47 s shows it.

## Why it matters

Grey and fraying are how a creature reads as corrupted. Melee is where the player looks most
closely, and that is exactly where the read breaks. The colour also appears *during the
scorpion's tell*: the orange claws are visually louder than the agitated fray that is meant to
carry the tell. A half-coloured silhouette reads as a rendering glitch, not as design.

## Cause (from reading, not instrumented)

The brute carried its own `GreyhushShield` (amount 0.422), so a slightly coloured enemy never
stood out. The creature composite (`greyhush_creatures.gdshader`) shades every pixel of the
`CanvasPass.CREATURES` render with `gh_memory`, which folds in every shield's shape. A
SILHOUETTE shield is described as "only the creature's own drawn pixels are lit"
(`greyhush_shield.gd:29`), but on a shared pass the shader cannot tell Ivo's pixels from a
creature's pixels.

## Fix (for the implementer; not applied)

Options, to decide with the greyhush owner:
- Give the creature pass a per-pixel "unshielded" mark: for example, `CorruptionEdge` writes a
  flag into the sprite's output (alpha or a spare channel) that the composite reads to skip
  shield light. This keeps one pass.
- Draw corrupted creatures on their own `CanvasPass` whose composite ignores shields.
- Mask each shield by its owner's silhouette (a per-shield mask texture). This is the general
  fix, but it costs more.

Add a playtest check: a creature at stop distance from Ivo in a 0.0-memory room has no pixel
with saturation above the grey threshold.

## Resolution (2026-10-29)

Chosen: a per-pixel unshielded mark in the creature pass's alpha (the first option).

- `unshielded_mark.gdshaderinc` defines `GH_UNSHIELDED_ALPHA` (253/255) and `gh_is_unshielded(alpha)`.
- `corruption_edge.gdshader` writes that alpha on every pixel it draws.
- `greyhush_creatures.gdshader` reads it. A marked pixel is shaded by `gh_memory_weighted(px, 0.0, ...)`, the field with no shield light, and composited fully opaque. Every other pixel is unchanged (`gh_memory` is `gh_memory_weighted(px, 1.0, ...)`).
- Ivo, villagers and CORE-04's teachers draw ordinary alpha, so their own shields still colour them. A corrupted creature stays grey by the field even inside Ivo's shield.

Why this one:
- **One pass, no new viewport and no new cull bit:** "each CanvasPass owns its bit" is untouched. The water reflection, the lesson dim and the foreground clip keep reading the one creature texture.
- **Overlaps resolve by draw order for free.** An opaque Ivo drawn over a creature pixel writes alpha 1 and is lit. A separate unshielded-mask pass cannot know the draw order: it would grey Ivo wherever he stands in front of a creature, which is common in melee.
- **The formula is unchanged:** only the shields' weight is scaled, and the shields are rendering only, so `MemoryFieldMath` has no twin to change.

Limits, accepted:
- A creature pixel drawn over an opaque Ivo pixel composites to alpha 1, so it is lit there. This happens only where the two bodies overlap.
- Two corrupted creatures overlapping also lose the mark where they overlap.
- Another creature-pass item whose antialiased alpha happens to be exactly 253 loses shield light on that pixel. The rain splashes and the recall aura's rays can.
- A marked pixel shows 253/255 coverage in the raw pass (the water reflection reads it raw): invisible.

Not re-played: check a creature at stop distance in a 0.0-memory room for coloured pixels.
