---
id: bugs/ivo-sheet-test-lets-a-held-prop-sheet-use-opaque-black
type: bug
title: ivo_sheet_test adds a held prop's transparent pixels to the allowed colours, so opaque black passes in ivo_guitar.png
status: fixed
severity: low
tags: [tests, art, palette, ivo, guitar, story]
related: [systems/story, systems/art-pipeline]
created: 2026-10-15
updated: 2026-10-15
source_files:
  - tests/scenes/characters/ivo/ivo_sheet_test.gd
  - assets/sprites/world/props/interiors/ivo_house/guitar.png
---

## Summary

FIXED 2026-10-15 (STORY-03 phase A review, 2026-10-15). `test_every_colour_is_from_the_palette` extends the allowed set with every pixel of the guitar prop, transparent ones included, and forces the alpha byte to 0xff. The prop's transparent pixels are (0, 0, 0, 0), so opaque black `0x000000ff` becomes allowed for `ivo_guitar.png`. Black is not one of the 27 colours in `ivo_palette.png`.

## Symptom

Not a wrong pass yet: measured with PIL, `ivo_guitar.png` has no opaque black today. A later regeneration that leaves a black outline or a black matte in the guitar sheet would still pass the palette test.

## Root cause

`tests/scenes/characters/ivo/ivo_sheet_test.gd`, in the `HELD_PROPS` loop: `allowed[prop.get_pixel(x, y).to_rgba32() | 0xff] = true` runs for every pixel, with no check on alpha. The sheet's own loop skips `data[i + 3] == 0`, but this loop does not.

## Fix

Fixed 2026-10-15. `ivo_sheet_test.test_every_colour_is_from_the_palette` skips a `HELD_PROPS` pixel whose alpha is 0 before adding its colour, the rule the sheet loop already uses, so transparent black never joins the allowed colours.

## Prevention

When a test widens an allowed colour set from an image, read only opaque pixels. A transparent pixel's RGB is usually black or whatever the exporter left there, so it is not a colour of the art.
