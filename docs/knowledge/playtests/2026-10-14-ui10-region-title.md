---
id: playtests/2026-10-14-ui10-region-title
type: playtest
title: UI-10 region title - first crossing into Threshold Road, a second crossing, a new game, Frost Edge in pt_BR under the pause
status: active
build: 3e1ed83 (UI-10 uncommitted)
area_tested: "village_gate_east -> threshold_fields and back; a new game in village_house; threshold_wayshrine -> frost_shore with the pause opened during the hold"
tags: [ui, hud, region, playtest]
related: [systems/region-title, systems/screens, systems/songs-and-the-memorina]
created: 2026-10-14
updated: 2026-10-14
ratings: { fun: 3, fluidity: 4, aesthetics: 4 }
---

# UI-10 region title

Timelines: `tools/playtest/scripts/region_title_threshold.json`, `region_title_new_game.json`, `region_title_frost_edge_pause.json` (real clock). The runner's `log` now prints `title=<alpha> '<name>' announced=<n>`. Stills: `screenshots/2026-10-14-ui10-region-title/`.

## What was measured

- **First crossing** (from x 4380, right held 0.9 s): the cut to `threshold_fields` came at about t 1.75. The logged alpha was 0.55 at t 2.25 (`01_fade_in`, mid-rise), 1.00 at 3.25 (`02_hold`), 0.65 at 5.8 (`03_fade_out`) and 0.00 at 6.6 (`04_gone`). `announced` went from 0 to 1. The gate is the first room, but the village has `shows_title = false` and is not recorded. Re-run after that change: same alphas.
- **Second crossing:** after walking back into `village_gate_east` and east again, alpha stayed 0.00 at +0.6 s and +1.8 s after the cut, and `announced` stayed 1 (`05`, `06`).
- **New game** (no `player_position`): Ivo starts in `village_house`, `announced` is 0 and alpha 0.00 throughout (`07`, `08`). The village is never titled.
- **Frost Edge, pt_BR:** "Borda Gelada" / "Onde o mundo se esqueceu primeiro" at full alpha over the frozen shore (`09`). The pause, opened during the hold, dims the title with the world (`10`). Alpha stayed 1.00 for 3.3 real seconds under it (`11`). At 9.4 s, 1.9 s after resuming, alpha was 0.61 (`12`): the fade had restarted where it stopped. With no freeze the card would have gone at about 6.4 s.
- No errors or warnings in any run.

## Reading

- The name reads over the grey winter sky and the frost shore's pale ground. The outline font's built-in inner contour, together with the Label's dark outline, gives cream letters a dark engraved line. That works on the light grey.
- The ruled line under a long name ("Threshold Road") is wide, about 350 screen px. It reads as a banner, not a hairline.
- The epithet at 8 px with a 2 px outline is legible at the 2x scale.
- Not judged from stills: whether 0.8 s in, 2.5 s hold and 1.0 s out feels right in motion. The numbers are the user's "about 2.5 s".
- Not tested: a bright summer or caldera background. The cream may lose contrast there, and the dark outline is what would carry it.
