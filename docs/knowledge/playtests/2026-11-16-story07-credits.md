---
id: playtests/2026-11-16-story07-credits
type: playtest
title: STORY-07 the credits and the rest on the stone - the full ending from a due save (epilogue, credits, rest, save), the roll in en and pt_BR over a year in the wide garden, a skip that lands black and rests, a load that arrives seated on the stone; a second seat's Down prompt over Ivo fixed
status: active
build: 7c6c05f2 + the uncommitted STORY-07 step 11 tree in the main working tree; the en run re-run after the prompt fix
area_tested: "tools/playtest/scripts/story07_ending.json (en: world restored, five flashbacks seen, reunion heard; Down on the stone, the whole epilogue, the credits to their end, the rest, stand, Down again), story07_credits_ptbr.json (pt_BR, epilogue seen: Down on the stone plays the credits from CreditsSeat), story07_credits_skip.json (en, real clock: pause at 10.5 s of the roll, Skip scene), story07_reload.json (a committed bench garden_stone, credits seen: the world arrives there)."
tags: [story-07, credits, cutscene, bench, save, year, i18n, playtest]
related: [architecture/story-07-epilogue, systems/cutscenes, systems/life-benches-death, systems/story, systems/music, playtests/2026-11-16-story07-epilogue, playtests/2026-11-16-story07-year]
created: 2026-11-16
updated: 2026-11-16
ratings: { fun: 0, fluidity: 4, aesthetics: 3 }
screenshots:
  - 2026-11-16-story07-credits/en_c01_wide.png
  - 2026-11-16-story07-credits/en_c02_title.png
  - 2026-11-16-story07-credits/en_c03_art.png
  - 2026-11-16-story07-credits/en_c06_godot.png
  - 2026-11-16-story07-credits/en_c07_licence.png
  - 2026-11-16-story07-credits/en_c09_logo.png
  - 2026-11-16-story07-credits/en_c11_rest_under_black.png
  - 2026-11-16-story07-credits/en_c12_after_rest.png
  - 2026-11-16-story07-credits/ptbr_p04_014.0.png
  - 2026-11-16-story07-credits/ptbr_p06_026.0.png
  - 2026-11-16-story07-credits/ptbr_p08_040.0.png
  - 2026-11-16-story07-credits/k03_pause_skip.png
  - 2026-11-16-story07-credits/k_14.30.png
  - 2026-11-16-story07-credits/reload_r01_seated.png
  - 2026-11-16-story07-credits/before_fix_prompt_over_ivo.png
---

# STORY-07: the credits and the rest on the stone

Four windowed runs of the playtest runner (memory-only saves). Timings are the runner's unpaused clock `t`.

## The full ending (en, `story07_ending`)

- The epilogue plays as in `playtests/2026-11-16-story07-epilogue` and ends at about 50.8 s; the credits begin on the same frame's deferred call (the log at 50.83 s already shows the roll at 0.3 s of 63.5).
- The frame pulls out over 3 s to zoom 0.5 on the whole garden (`en_c01_wide`); the column rolls up the middle, cream on the garden, readable over sky, cliffs and trees (`en_c02_title`, `en_c03_art`). Headings in the title font, roles dim, names bright; the rows fade at both edges.
- The year passes under the text: autumn and winter show on the tree, the bushes and the backdrop during the licence (`en_c06_godot`, `en_c07_licence`), and the logo stands on spring again (`en_c09_logo`, `season=SPRING turn=0`): the 56 s year ends before the logo's hold.
- The roll ends at 63.5 s, the 1.5 s black falls, the rest lands under it: the log at 116.4 s shows `bench=garden_stone ending_finished=true epilogue_due=false` with the fade already clearing; the bloom shows through the clearing black (`en_c11_rest_under_black`), and the garden is back at Ivo's rest zoom with the life notes back (`en_c12_after_rest`). No error in the log.
- Left stands him; Down sits him on the stone again, now the bench (an ordinary rest, `bench=garden_stone`).

## The roll in pt_BR (`story07_credits_ptbr`)

With the epilogue seen and the credits not (a dropped roll), Down on the stone plays the credits from `CreditsSeat`. Every key reads in Portuguese (`ptbr_p04_014.0`: "Um jogo de", "Arte", "Interface, ícones e fontes", "Direção de arte e a arte feita para este jogo"; `ptbr_p06_026.0`: "Música", "Agradecimentos", "Obrigado por jogar", "Feito com Godot Engine"); the names and the licence stay as written (`ptbr_p08_040.0`). The roll lasts 63.5 s, as in en. Its end rests on `garden_stone` and the fade clears.

## The skip (`story07_credits_skip`, real clock)

At 10.5 s of the roll the pause menu offers "Skip scene" (`k03_pause_skip`). The skip lands the scene at once: black, the year settled (spring), the frame cut back to Ivo, the rest under the black (`bench=garden_stone` at 14.0 s), the black clearing over 1.5 s with the bloom and the quill showing (`k_14.30`). Ivo then stands and walks freely.

## The load (`story07_reload`)

A committed save on `garden_stone` with the credits seen: the world arrives seated on the stone in the garden behind the opening fade (`reload_r01_seated`), the afternoon kept. Left stands him; Down rests there again.

## Found and fixed

1. **A second seat's prompt over Ivo** (`before_fix_prompt_over_ivo`, the first en run): once the epilogue was seen, `CreditsSeat` opened on the stone Ivo already sat on, and as it was neither occupied nor closed, its Down glyph showed over his head through the whole roll. `Seat.offers()` now also requires no sitting Ivo in reach, and `SitComponent` refreshes the other seats it overlaps when he sits or stands (`seat_gate_test.test_a_seat_beside_the_one_he_sits_on_shows_no_prompt`). The re-run shows no glyph.

## Notes

- The licence's four paragraphs follow each other with the column's 1 px separation and no gap: readable, but denser than the sections above it.
- At zoom 0.5 the world is drawn at half scale; the text is screen-space at 2x and stays crisp.
- What frames cannot show: the title theme's entry under the end of the epilogue and its level under the roll were not listened to; the skip's 0.8 s fade of the music is unjudged.
