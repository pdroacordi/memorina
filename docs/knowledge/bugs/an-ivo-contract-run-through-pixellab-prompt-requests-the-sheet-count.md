---
id: bugs/an-ivo-contract-run-through-pixellab-prompt-requests-the-sheet-count
type: bug
title: Running an Ivo clip contract through `pixellab.ps1 -Prompt` asks PixelLab for the sheet's frame count, not the generation's
status: resolved
severity: low
tags: [art, pixellab, contracts, tooling, ivo, core-08]
related: [architecture/ivo-at-2x, systems/art-pipeline]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - tools/pixellab/pixellab.ps1
  - tools/art/art_prompt.gd
  - tools/art/prompts/ivo_death.md
  - tools/art/prompts/ivo_wall_slide.md
---

## Summary

CORE-08 made `frames:` in an animate3 contract mean the frames kept in the sheet (`ArtPrompt.problems` requires
`keep.size() == frames`). `pixellab.ps1 Use-Prompt` still reads `frames:` as the `frame_count` it sends
(`pixellab.ps1:160,166`). Six of the 18 Ivo contracts kept a different number of frames than they generated, so the
documented `-Prompt <id>` route requests the wrong count.

## Symptom

Status: resolved 2026-10-11 (found in the CORE-08 review from the code; no call was made). Requested counts against the counts used:

| Contract | `frames:` (sent) | generated (`-Frames` in the body) | `--keep` |
|---|---|---|---|
| ivo_death | 10 | 16 | 6-15: frames 11-15 do not exist, so the cut fails |
| ivo_attack_ground, ivo_attack_run, ivo_land | 9 | 10 | odd count; the script's own comment says 4-16, even |
| ivo_roll | 7 | 8 | odd count |
| ivo_jump | 6 | 8 | the keep 1-6 holds, but the motion is spread over a different count |
| ivo_wall_slide | 1 | 6 (a frame of `wall_land`) | 1 frame is outside the API's range, and the clip is not its own generation |

Each body spells out the correct explicit command, so the shipped sheets reproduce exactly. The review re-ran all 18
`cut_inhabitant.py` lines and got byte-identical PNGs. Only the `-Prompt` path, which `tools/art/prompts/README.md`
step 3 shows, is wrong.

## Root cause

One field carries two counts. Before `keep` existed, a sheet's frame count was always the generation's count
(closed loop, last frame dropped).

## Fix

Applied 2026-10-11. An animate3 contract with a `keep` carries `generate:`, PixelLab's frame_count. `ArtPrompt.keep_fits` requires it to be even, 4..16, and to reach every kept index. `pixellab.ps1 Use-Prompt` sends `generate:` when present, `frames:` otherwise. `ivo_wall_slide` is now `command: cut` with `cut_from: ivo_wall_land`, and `Use-Prompt` refuses a cut. All 18 Ivo contracts carry their real counts; their cut lines still reproduce the shipped sheets byte for byte.

## Prevention

`art_prompt_test`: `test_a_kept_animation_needs_its_generation_count` checks generate; `test_every_cut_fits_its_source_generation` checks every cut's keep against its source's generation; `test_the_library_is_sound` runs `keep_fits` on every animate3 contract.
