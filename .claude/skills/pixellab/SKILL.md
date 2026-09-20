---
name: pixellab
description: Generate or animate pixel-art sprites for Memorina through the PixelLab API (api.pixellab.ai) — a missing guardian animation (hurt, lucid, restored), a placeholder creature, a variant of an existing sheet. Use when the user asks to generate art, animate a sprite, fill in a missing clip, or mentions PixelLab. Key-safe by construction: the key lives only in the PIXELLAB_API_KEY environment variable of the shell that runs it.
---

# PixelLab art generation

`tools/pixellab/pixellab.ps1` is a thin PowerShell client for PixelLab's REST API
(`https://api.pixellab.ai/v1`, bearer auth). It has three commands:

| command | endpoint | what it does |
|---|---|---|
| `balance` | `GET /balance` | credits left, in USD |
| `generate` | `POST /generate-image-pixflux` | one image from a text description (optionally seeded from `-Reference`) |
| `animate` | `POST /animate-with-text` | `-Frames` frames of `-Action` performed by the character in `-Reference`, written one PNG per frame **and** stitched into the horizontal strip this project's `AnimationPlayer` clips read (`Sprite2D.hframes` = frame count) |

## Safety rules (non-negotiable)

1. **The key is never a parameter, never in a file, never in a commit, never printed.** The script
   reads `PIXELLAB_API_KEY` from the environment and nothing else. To run it, the user sets the
   variable in their own shell (`$env:PIXELLAB_API_KEY = '…'`). If the variable is missing the
   script says so and stops — do not ask the user to paste the key into chat, and never write it
   into `.env`, settings, scripts or docs.
2. **Every call costs money.** The script prints `usage:` after each call. Before a batch (e.g. six
   clips for one guardian) run `balance`, estimate, and tell the user what it will cost. Never loop
   generations unattended.
3. **Outputs land outside the repo** (`-Out` defaults to `%TEMP%\pixellab`). Moving art into
   `assets/sprites/...` is a separate step: look at the frames first (Read the PNGs), keep only what
   fits the sheet conventions below, then copy and `--import`. Never generate straight into `assets/`.
4. Generated art is credited as PixelLab-generated in `CREDITS.md` when it ships.

## Project conventions the output must meet

- Characters are authored **facing left** (`-Direction west`); the scenes flip via `Sprite2D.scale.x = -2`
  and `flip_h` (see `guardian.gd`/`brute_shadow.tscn`).
- One PNG per clip, frames side by side, all frames the same size, the body **centred in the frame**
  (an off-centre body jumps on flip — see `docs/knowledge/bugs/`). Match the existing clip's frame
  size so it drops into the same `AnimationPlayer` tracks: Frost Guardian 192×128, Bloom Guardian
  128×96 (after re-padding), Ivo 96×96.
- Transparent background (`-NoBackground` for `generate`; animations inherit the reference's
  transparency).
- Clip lengths must equal the gameplay durations asserted at startup (`Guardian._assert_clip_durations`,
  `GuardianAttack.duration` = frame count × step) — retune the `.tres` or the step when frame counts change.

## Typical flows

**Fill a missing guardian clip** (e.g. a `lucid` tremble or a real `restored` pose):

```powershell
.\tools\pixellab\pixellab.ps1 balance
.\tools\pixellab\pixellab.ps1 animate -Description "two-headed carnivorous flower monster, pixel art" `
    -Action "trembling, dazed, swaying in place" -Reference $env:TEMP\pixellab\bloom_idle_frame0.png `
    -Width 128 -Height 96 -Frames 6 -Direction west -Name bloom_guardian_lucid -Out $env:TEMP\pixellab\bloom
```

Note: a reference must be a **single frame**, not a strip — crop frame 0 out of the sheet first
(PowerShell `System.Drawing`: load the bitmap, `Clone` a `Rectangle(0,0,frameW,frameH)`, save).

**A new placeholder creature**: `generate` with `-NoBackground -Direction west`, then `animate` per clip
using the generated image as `-Reference`.

## Limits and gotchas

- Image sizes are validated server-side per endpoint; a `422` comes back with a `detail` explaining
  the accepted range — the script prints it. Start with the sizes above.
- `animate` frames are only as consistent as the reference: generate the base pose first, review it,
  then animate from that exact file for every clip so all clips share one silhouette.
- Seeds: `-Seed 0` is random; fix a seed to reproduce a result.
- The full parameter list (outline/shading/detail styles, guidance scales, inpainting/masks) mirrors
  the official Python SDK (`pixellab-code/pixellab-python`); the script exposes the subset this
  project has needed. Extend the script rather than calling the API ad hoc, so the key handling
  stays in one place.
