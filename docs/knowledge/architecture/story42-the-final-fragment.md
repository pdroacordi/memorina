---
id: architecture/story42-the-final-fragment
type: architecture
title: "STORY-42 plan - Ermo's final fragment plays in place in the lantern, between the victory and the restoration scene, as a skippable cutscene of seven engraved panels on the existing EngravingView with a look of its own (two inks, a trembling mixed ink); GuardianFinale plays it and chains the restoration on its recorded end; live SCENE_SEEN final_fragment plus a lantern CutsceneTrigger replay a quit"
status: built
tags: [story-42, final-fragment, ermo, finale, cutscene, engraving, notebook, music, i18n, plan]
related: [architecture/story-04-bearer-fragments, architecture/grd-06-final-battle, architecture/story38-the-keeper-wakes, architecture/story-07-epilogue, architecture/cutscenes-are-data-played-between-two-rest-states, architecture/notebook-entries-are-derived-from-the-save, systems/bearer-fragments, systems/guardians, systems/cutscenes, systems/music, systems/notebook, systems/life-benches-death, systems/greyhush, systems/ending]
created: 2026-11-18
updated: 2026-11-18
source_files:
  - docs/design/drafts/fragmento_final.md
  - scenes/characters/guardians/finale/guardian_finale.gd
  - resources/characters/guardians/finale_stats.gd
  - resources/cutscene/story/world_restoration.tres
  - scenes/ui/engraving/
  - resources/cutscene/cutscene_engraving.gd
  - resources/cutscene/cutscene_engraving_clear.gd
  - scenes/world/rooms/frost_edge/contents/lighthouse_top_contents.tscn
  - scenes/ui/life_hud/life_hud.gd
  - tools/art/cut_engraving.py
---

# STORY-42: the final fragment, Ermo's story (plan)

**Status: PLAN, 2026-11-18.** Text approved: `docs/design/drafts/fragmento_final.md` ("Aprovar o texto (Recommended)"; "Depois da vitória (Recommended)"; "Ermo (Recommended)", user, 2026-11-18). Design 01 §4 (the name only in the fragment), §6 (its own look, inside the final confrontation), 02 §5.2-5.3 (the dissonance's unstable grey), `camada_pessoal` §3 (the bearer engraving).

## Context

When the final call closes, `GuardianFinale.restored()` writes `restore_world()` (committed at once) and plays `world_restoration` hosted by the guardian; a `CutsceneTrigger` in the lantern (`when` WORLD_RESTORED) replays it if its live SCENE_SEEN was lost. STORY-42 puts seven captioned engraved panels before that scene. Constraints: skippable; a quit at any point replays what was missed, in order; nothing new saves (only benches, plus the victory's commit); music only through `Music`; no `WorldFreeze` writer, no input reader; no `TIME`/`FRAGCOORD`.

## Options considered

1. **Where it plays.**
   - (a) On the bearer stage via `Game.travel` (STORY-04). Rejected: the stage exists because a bearer fragment starts anywhere, in a live room with creatures and hazards. After the victory the lantern holds nothing that hurts (contact box off in RESTORED, dissonance cleared), Ivo is blocked by the scene, and the restoration must play in the lantern hosted by the guardian. Two travels, a return point and a returning scene would buy nothing, and the travel back would re-arm the lantern's triggers in the middle of the sequence.
   - (b) **In place, in the lantern: a `Cutscene` whose panels are `CutsceneEngraving` steps on the existing `EngravingView`.** Chosen. It is also the design's "dentro do confronto final".
   - (c) Prepending the panels to `world_restoration.tres`. Rejected: one skip would cover 80 s, and there would be no "fragment seen" fact to replay or to make a notebook page from.
2. **Who orders fragment then restoration.**
   - (a) A global rule in `CutsceneDirector`: re-arm the room's triggers after every scene end. Rejected: it changes every room's behaviour, and the trigger's delay and start gates leave Ivo free under black between the two scenes.
   - (b) A new generic `CutsceneChain` node. Rejected for now: there is one use.
   - (c) **`GuardianFinale`, which already plays the victory's scene**, listening to `CutsceneDirector.scene_ended` the way `EpilogueDirector` chains the credits. Chosen. Both scenes stay on `FinaleStats`.
3. **The look.**
   - (a) A new view, shader and math. Rejected: it duplicates the pan, dither, caption and pause clock. Design 01 §6 forbids reusing the bearers' *look*, not their code, and the approved draft asks for "o mesmo formato... mas com estética própria: as duas cores dele".
   - (b) **`EngravingView` with two additive features**: a second key ink and a trembling mixed ink. Chosen. Every bearer frame draws as before.

## Decision

### Flow and seam

- `FinaleStats.final_fragment: Cutscene` (new). `restored()` plays it, or `restoration_scene` when it is null (old test fixtures).
- `GuardianFinale._ready` connects `CutsceneDirector.find(tree).scene_ended`. On the fragment's end with `ended_recorded()` (a skip records too) and `world_restoration` unseen, it plays `restoration_scene` on `_guardian`, deferred (as `EpilogueDirector._play_credits`). A dropped fragment plays nothing. If that play is refused, it clears the black through `director.fade` so Ivo never stays covered.
- `is_performing()` stays keyed to the restoration only.
- **The seam is black.** The fragment ends with `CutsceneFade` to black (0.8 s). The scene's end closes the bars and cuts the frame under the cover. `world_restoration.tres` is unchanged: its first fade (to black) is a no-op from black, then it places the pair and fades in on a lantern already in colour. The region's 6 s lift ran behind the paper.
- **The end branch**, read when reached: `unless seen_world_restoration` leaves the black for the restoration; otherwise (an old save that saw the restoration before STORY-42) `CutsceneEngravingClear(0, hide = true)` and `CutsceneFade` clear 1.2 s, so no cover is left without an owner.

### Source of truth and replay

- Seen is only the live `SCENE_SEEN final_fragment` (`resources/save_facts/seen_final_fragment.tres`). No new `SaveFact` kind and no death-proof field.
- The victory's commit runs before the fragment, so a quit or a rebuild mid-fragment or mid-restoration leaves `world_restored` true and both scenes unseen. The director's `_exit_tree` writes nothing.
- **The lantern's triggers, in order:** `MentorWakes` (already seen once the victory commits), **`FinalFragment`** (new; `when` WORLD_RESTORED, no zone), `WorldRestoration`. The director arms the first trigger whose scene is unseen:
  - both missed: the fragment plays, and `GuardianFinale` chains the restoration;
  - only the restoration missed: it plays alone;
  - neither missed: nothing plays.
- A death after the victory forgets both scenes until a bench commits them. They replay only if Ivo returns to the lantern (the same contract GRD-06 accepted for the restoration).

### The scene `resources/cutscene/story/final_fragment.tres` (id `final_fragment`, skippable, ~67 s)

1. Together: bars open 0.6 s; `CutsceneMusic`, an inline stream-less SCENE cue `final_fragment_silence` (fade 1.0 s, as `mentor_wakes_silence`); `CutsceneCamera [mentor, ivo]` offset (0, -56), zoom 2, 1.0 s (the restoration's frame).
2. Wait 1.2 s.
3. `CutsceneFade` to `EngravingView.paper`, 1.2 s.
4. Panel 1 (no dissolve, reveal 1.5 s) together with `CutsceneFade` clear 0.6 s (the bars darken from paper to black). Then panels 2-7, each dissolving 1.0 s over the one before.
5. `CutsceneEngravingClear` 1.5 s, the fade to black 0.8 s, the end branch.

| Panel | s | Caption turns | Inks | Moving ink layers | Sound |
|---|---|---|---|---|---|
| 1 Perennials | 9.0 | 2 | blue on the winter figure, pink on the spring blossoms; the other two grey | none | silence |
| 2 Lighthouse | 9.0 | 2 | blue | snow (blue, drift) | `ermo_phrase` alone, 1.5 s in |
| 3 Flower | 9.0 | 2 | blue, pink | none (held) | silence |
| 4 Crack | 7.0 | 1 | blue, pink, mixed | the crack (mixed), `tremble` 1 | `ermo_phrase` count 4 with `ermo_spring` 0.3 s behind, cut |
| 5 Roads | 9.0 | 2 | blue, pink, mixed trace | the trace (mixed, `hframes` loop along the threads) | silence |
| 6 Grey | 7.0 | 1 | none (the only inkless panel) | none | silence |
| 7 Flute | 10.5 | 3 (the name alone last, if Q1 = A) | blue on his hand | none (the pan crosses the hands) | silence |

### The look (additive, on `EngravingView`)

- `engraving.gdshader`. Key `#FF00FF` keeps the first ink. Key `#00FFFF` takes `ink_b_colour`. Key `#FFFF00` is the **mixed ink**: per art texel, `hash(texel, tremble_step)` picks ink A, ink B or `gh_print` of one of the four greys. This is the "cinza instável, tremendo, quase estática" (02 §5.3) as ink. With `tremble > 0`, the rows of ink-only layers shift in 2-art-px bands by up to `tremble` whole art px from `hash(band, tremble_step)`. Grey base layers never move. `tremble_step` comes from script; no `TIME` or `FRAGCOORD`. Bearer art holds only greys and `#FF00FF` (`cut_engraving.py`), so it draws as before.
- `EngravingFrame.caption_turns: bool` (default false). When true, the captions show one at a time in equal shares of the frame, each fading in 0.5 s and out 0.4 s. `tremble: float` (art px, default 0).
- `EngravingMath` (pure): `caption_turn(frame, dissolve, t)`, the per-turn `caption_alpha`, `tremble_step(frame, t)` (whole steps at `TREMBLE_HZ` 10 on the view's own pausable clock; constant 0 when `tremble` is 0).
- `EngravingInk` (Resource, `colour`): one source for the flower pink, `resources/story/engraving/flower_ink.tres`. `CutsceneEngraving.second_ink: EngravingInk` (null draws the one-ink bearer look); `ink` stays `winter_palette.tres` (the frost bearer's blue, one source). The shader's `ink_max_luma` darkens both inks.
- `CutsceneEngravingClear.hide: bool` → `context.hide_engraving()` → `EngravingView.hide_now()`.
- **The life notes.** `LifeHud` draws after `Fade`, so in place its notes would sit on the paper. `Cutscene.hud_hidden: bool` (default false; true on `final_fragment`). `game.tscn` wires `CutsceneDirector.scene_began` / `scene_ended` to `LifeHud.on_scene_began(scene)` / `on_scene_ended(scene)`, which fade the notes as `on_ending_began` does.

### Music

- No new piece and nothing from AIVA, so the `song-loop` is not triggered.
- His phrase: `resources/story/ermo_phrase.tres`, a `Melody` with the notes of `final_phrase_a.tres` (G E D C D E). The broken phrase: `ermo_spring.tres`, with `root.tres`'s notes (track B, `FinaleStats.second_song`). Both are played by `CutsceneMelody` on the Notes bus, with the four voices `world_restoration` gives Ermo's winter song (Ivo's flute samples at pitch 1, the lucid Ermo). That is a note step, not background music.
- `Music` holds only the stream-less SCENE request; `GuardianMusic._on_restored` has already released the fight cue over 0.5 s, and `world_restoration` asks `finale_restoration` after.
- A skip never plays a melody. The pause stops the melody and the view.

### Single writers (unchanged)

- `CutsceneDirector`: `SCENE_SEEN final_fragment`.
- `EngravingView`: every engraving pixel and the caption.
- `GuardianFinale`: its two `play` calls.
- `Music`: all music.

No `WorldFreeze` writer, no input reader, no router screen.

## i18n

- Captions are verbatim from the draft (pt_BR and en approved), split only at sentence breaks: `FINAL_FRAGMENT_<panel>_<turn>`, with 1_1, 1_2, 2_1, 2_2, 3_1, 3_2, 4_1, 5_1, 5_2, 6_1, 7_1, 7_2, 7_3. Panel 5 breaks after "lugar."/"place.". Panel 7 breaks after "mãos."/"hands." and before "Seu nome era Ermo."/"His name was Ermo.".
- Notebook (Q4): `NOTEBOOK_LORE_FINAL_FRAGMENT_TITLE`, `_BODY`.
- No other text: no title card, no prompt. The skip is the existing `PAUSE_SKIP_SCENE`.
- Glossary at build: "fragmento final" → `final_fragment` (the revelation keeps `REVELATION`; line 32 is reworded); "Perenes" → the Perennials (content only); drop "the mentor stays unnamed" (line 152) or keep it per Q5.

## Tests

- **Pure:** `engraving_math_test`:
  - a frame's turns, their alpha windows and the active turn;
  - bearer frames unchanged;
  - `tremble_step` is 0 for a still frame, steps at 10 Hz, gives the same value at the same `t`, and stops under a hold.
- **Resource:** `final_fragment_test`:
  - id, skippable, in `cutscene_catalog.tres`, no talk;
  - 7 engraving steps in panel order; the first reveals and the rest dissolve;
  - every inked panel uses `winter_palette` and `flower_ink`; only panel 4 has `tremble`; panel 6 has no ink;
  - every caption key is `FINAL_FRAGMENT_<n>_<t>` in order; `EngravingMath.fits` holds for every frame;
  - the melodies' notes equal `final_phrase_a` and `root`;
  - the stream-less music; the last fade is to black and the end branch reads `seen_world_restoration`;
  - length 55..75 s.
- **Scene:**
  - `guardian_finale_test`:
    - the last phrase writes `world_restored` and plays the fragment, not the restoration;
    - a recorded or skipped end plays the restoration on the next frame; a drop plays nothing;
    - a restoration already seen is not replayed, and the cover clears;
    - a refused play clears the black;
    - `is_performing` is false during the fragment and true during the restoration;
    - leaving the tree writes nothing.
  - `final_fragment_rooms_test`:
    - the lantern's trigger order;
    - with `world_restored` and nothing seen, `FinalFragment` arms; with only the fragment seen, `WorldRestoration` arms;
    - a committed-then-reloaded save (the quit case) arms the fragment;
    - the whole fragment runs in the real lantern contents and ends recorded (nothing hurts).
  - `engraving_view_test`: key B takes the second ink; the mixed key takes all three; `hide_engraving`; a hold stops the tremble.
  - `cutscene_steps_test`: `second_ink`, `hide`.
  - `cutscene_director_test`: `hud_hidden` signals.
  - `life_hud_test`: fade and return.
  - `cutscene_rooms_test`: the ids resolve, automatic because the trigger starts it.
- **Fit:** extend `engraving_caption_fit_test` to the `FINAL_FRAGMENT_*` keys and the shipped frames' turns, each turn at most 2 lines in every locale. `notebook_text_fit_test` and `notebook_catalog_test` cover the page.
- **Gates:** the verify-gates shader scan.
- **Playtests:**
  - `story42_final_fragment.json` (the `guardian_bot_mentor` win, watched);
  - `story42_final_fragment_skip.json` (`"clock": "real"`);
  - `story42_fragment_fallback.json` (seed `world_restored`, `"scenes_seen": ["mentor_wakes"]`, enter by the hatch: the fragment, then the restoration);
  - a pt_BR run.

## Art

- One contract, `tools/art/prompts/story_final_fragment.md`, in the shape of `story_bearer_frost.md`. Generator: Codex image mode; our own art only, never pack art. References: the approved bearer boards (`tools/art/sources/story/bearers/*/board_codex.png`) for the line, our mentor stills (`assets/sprites/world/story/mentor/stasis.png`, `at_lamp.png`), the `past_self` strip and the lantern lamp prop.
- Seven canvases of 384x176 art px, in two boards (panels 1-4, then 5-7 cut with `count=3`). Each holds the four `GREYS` plus the three keys, with at most 2 ink-only moving layers per panel (the table above).
- `cut_engraving.py` gains `--ink2` (→ `#00FFFF`), `--mixed` (a third drawn hue → `#FFFF00`) and `--background`. The pink sits within 0.12 hue of the magenta board, so these boards use a green ground.
- The panel-5 trace is a scripted `hframes` loop.
- Files go to `assets/sprites/story/final_fragment/panel_<n>_<layer>.png`.
- The notebook drawing (Q4) is a 72x40 cell cut from panel 7 by the `tube` subcommand.
- Placeholders until approval: paper, key outlines and the panel number.
- Credit in `CREDITS.md`. The board is approved before the cut ("Art approved before it ships", roadmap).

## Build order (one commit each, verify-gates each)

1. `EngravingMath` turns and tremble, with tests.
2. Shader keys and tremble; `EngravingFrame`/`EngravingInk`/`CutsceneEngraving.second_ink`/`CutsceneEngravingClear.hide`; view and context; tests.
3. `Cutscene.hud_hidden` and the `LifeHud` wiring; tests.
4. `FinaleStats.final_fragment`, the `GuardianFinale` play and chain; `guardian_finale_test`.
5. Placeholders, `final_fragment.tres`, the melodies, the ink, the fact, the catalog, `Triggers/FinalFragment`; resource and rooms tests; playtest on placeholders.
6. Caption keys and the fit test.
7. The notebook page (after Q4).
8. The art: contract → boards → cut → swap; playtests.
9. Docs:
   - `systems/guardians` ("The final battle");
   - `systems/bearer-fragments` (the reuse line, the second ink);
   - `systems/cutscenes`, `systems/notebook`, `systems/music`;
   - the glossary.

## Consequences

- `EngravingView` serves two looks. A third key or effect must keep the bearer art drawing as before.
- `GuardianFinale` now orders two scenes, so the restoration is no longer the victory's first frame. Victory to control is about 85 s, with two separate skips.
- A death or quit after the victory and before a bench forgets the fragment (and its page, Q4) until the lantern is visited again.

## SOLID

- **Open/Closed:** keys, tremble and turns are data defaulting to the bearer behaviour; no branch names a fragment.
- **Single responsibility:** `EngravingView` draws, `EngravingMath` decides, `GuardianFinale` orders the victory, the director records.
- **Dependency inversion:** scenes reach the view only through `CutsceneContext`.

## Prior art and traps

- Built on: `story-04-bearer-fragments`, `grd-06-final-battle`, `story-07-epilogue` (the scene chain), `story38-the-keeper-wakes` (the stream-less silence, the trigger order), `cutscenes-are-data-played-between-two-rest-states`.
- Traps avoided: a recorded end never clears a fade (`story-04` corrections, the end branch); `gotchas/a-node-idled-or-swapped-out-keeps-what-it-opened-in-an-autoload` (the music is owned by the scene); `bugs/a-cutscene-trigger-in-a-first-visited-room-never-arms` (the trigger is read from `room.contents()`).

## User decisions (2026-11-18)

- After the build: the notebook line and the turn splits of panels 1 and 3 (…havia os Perenes. / Cada um…; …esperasse alguém. / Segurou o frio, e segurou a flor.): "tá aprovado, ficou bom".

- Q1 captions: "Em partes (Recommended)".
- Q2 English name: the user asked "oq vc acha que fica melhor? greyhush ou forgettingrey?"; answered "the Greyhush" (matches the glossary and code; "hush" is the silence that stops the song). Caption 6 EN: "They called it the Greyhush."
- Q4 notebook: "Sim, depois de visto (Recommended)".
- Q6 music: "Trilha nova no AIVA": an underscore made through the `song-loop` skill, the user approving at each gate; the fragment is built on silence first and the cue is added when the piece is approved. His phrase and the broken phrase stay as note steps.
- Not asked, taken as recommended: Q3 the bearers' paper; Q5 his talks keep the plate "Mentor"; Q7 the handover through black.

## Open questions (user)

1. **Caption display.** The approved captions run 63-155 characters, and the bar holds 2 lines (about 65 characters each). (A, recommended) Show each caption in turns at its sentence breaks, words unchanged, with "Seu nome era Ermo." alone last. (B) A 3-line caption band for this fragment only: thicker bars and a shorter picture.
2. **The English name of cinzesquecimento.** Caption 6 says "the grey-forgetting"; the glossary and the code say "the Greyhush". No English string uses either yet.
3. **Paper.** (A, recommended) The bearers' forgotten-print paper: the grey is his doing, and the two inks and the tremble carry the difference. (B) A paper of its own.
4. **Notebook page.** (A, recommended) A Memories page after the bearers: the flute from panel 7, the title "Ermo", and one line of Ivo's for approval (draft: "Ele segurou o inverno pra uma flor esperar. Eu conheço essa mão." / "He held the winter so a flower could wait. I know that hand."), present on live `SCENE_SEEN final_fragment`. (B) Present on `WORLD_RESTORED`, so it survives a death or quit, even one before the name was shown. (C) No page.
5. **His name plate.** After the fragment, do `mentor_first`/`mentor_again` read "Ermo" or stay "Mentor"? (Recommended: stay "Mentor"; 01 §4 says the name is spoken only in the fragment.)
6. **Music.** (A, recommended) No new piece: his phrase alone on panel 2, both phrases cut on panel 4, silence otherwise. (B) An underscore through the `song-loop` (AIVA, approval at each gate).
7. **The seam.** (A, recommended) Through black; the restoration scene is unchanged. (B) The paper dissolves straight into the coloured lantern; the restoration's opening is edited.
