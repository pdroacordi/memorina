---
id: playtests/2026-10-15-story09-village-voices
type: playtest
title: STORY-09 - the village voices at 0.8 and 0.6 - the boy, the water carrier, the seller, the taverner (and his two mugs) and the baker
status: active
build: 08e0d4e (STORY-09 uncommitted)
area_tested: "village_square, village_lane_west, village_tavern, village_bakery"
tags: [story-09, dialogue, villagers, talkable, memory-step]
related: [systems/story, systems/dialogue, systems/props]
created: 2026-10-15
updated: 2026-10-15
ratings: { fun: 3, fluidity: 4, aesthetics: 4 }
screenshots:
  - screenshots/2026-10-15-story09-village-voices/08_a_boy_1_line.png
  - screenshots/2026-10-15-story09-village-voices/08_b_water_1_line.png
  - screenshots/2026-10-15-story09-village-voices/08_c_seller_1_line.png
  - screenshots/2026-10-15-story09-village-voices/08_d_taverner_1_line.png
  - screenshots/2026-10-15-story09-village-voices/08_e_baker_1_line.png
  - screenshots/2026-10-15-story09-village-voices/08_e_baker_2_line.png
  - screenshots/2026-10-15-story09-village-voices/08_f_baker_again_1_line.png
  - screenshots/2026-10-15-story09-village-voices/06_a_boy_1_line.png
  - screenshots/2026-10-15-story09-village-voices/06_b_water_1_line.png
  - screenshots/2026-10-15-story09-village-voices/06_c_seller_0_beside.png
  - screenshots/2026-10-15-story09-village-voices/06_d_taverner_0_beside.png
  - screenshots/2026-10-15-story09-village-voices/tavern_06_vs_08.png
  - screenshots/2026-10-15-story09-village-voices/06_e_baker_1_line.png
---

# STORY-09: the village voices

"Story cast + some villagers (Recommended)" (user, 2026-10-15). The lines are design 05's "Village voices (STORY-09)" table.

Two timelines, both exit 0. Each teleports Ivo beside each villager, presses Up and takes a screenshot of each line:
- `village_voices` at 0.8: the opening's talks heard, the elder's story included;
- `village_voices_06` at 0.6: the same talks, with `restored_guardians` [0, 1].

The `08_` and `06_` screenshots are in `screenshots/2026-10-15-story09-village-voices/`. Each villager has a `_0_beside` shot (the prompt), a `_N_line` shot per line, and a `_9_after` shot.

## At 0.8

| Villager | What the run showed |
|---|---|
| Boy | "Don't move. You moved." with the Boy plate; the girl beside him with her doll |
| Water carrier | "Up's heavy. Down's light. Same water." |
| Seller | "Apples. West orchards. Last ones, till someone goes out there." (one row) |
| Taverner | "Quiet one tonight.", his idle wiping the mug |
| Baker, first visit after the errand | "Morning, Ivo. Round one?", then "She used to come in coughing, at the end. That thing she had. Never did have a name, did it." (two rows) |
| Baker, next visit | "Morning, Ivo. Round one?" alone, as if for the first time |

## At 0.6

| Villager | What the run showed |
|---|---|
| Boy | Alone; the girl is gone. "Don't move." |
| Water carrier | "…" |
| Seller | He and his stall are gone, and there is no prompt |
| Taverner | The patron's seat is empty. Two mugs: one on the counter by him, one on the table in front of the empty bench. Up gives no prompt and no line (`tavern_06_vs_08.png`: 0.6 left, 0.8 right) |
| Baker | "Morning! …Ivo. Ivo. Sorry. Round one?" |

Every plate shows the role name and no portrait, like the baker's errand. Every line fits the box.

## Talk beside a door (review fix)

The boy's talk moved to col 17 (bugs/the-boys-talk-prompt-shows-over-the-bell-tower-door-and-up-enters-the-tower), and both timelines were rerun.
- The boy is visited from x 560.
- Both timelines then place Ivo at x 616, between the talk and the bell tower door: no prompt shows, and Up leaves him in the square (`08_g_band_616`, `08_g_band_616_after_up`).
- At x 580 the talk prompt shows (`08_g_talk_580`).
- `opening_errand` reran green with the baker's narrower talk.

## What screenshots cannot show

- The repeated greeting works through repetition: the run cannot show that it lands, only that it is word for word the errand's line.
- The mugs appear with the 0.6 stage, which changes while Ivo is away from the village (a guardian's restoration), so the player only ever finds them already set. They never see him set them down.
- The water carrier's Talkable is east of the well's lip, so Ivo speaks to her back while she faces the well.
