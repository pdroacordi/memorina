---
id: architecture/grd-06-final-battle
type: architecture
title: GRD-06 plan - the mentor's final battle as scene + GuardianStats + a GuardianFinale strategy child; a two-track call judged by a pure DualCallJudge; the revelation as an anomalous lucidity window; WORLD_RESTORED as the victory fact
status: accepted
tags: [grd-06, guardian, finale, mentor, revelation, dissonance, dual-call, shader, world-restored, plan]
related: [systems/guardians, architecture/guardian-fight-phase-machine, architecture/grd-04-autumn-and-summer-guardians, architecture/guardian-performance-and-talks, architecture/teaching-creatures, architecture/the-region-owns-its-forgetting, architecture/cutscenes-are-data-played-between-two-rest-states, systems/songs-and-the-memorina, systems/greyhush, systems/story, systems/cutscenes, systems/life-benches-death, systems/dialogue, gotchas/screen-texture-copy-scope, gotchas/canvas-layers-on-one-layer-index-stack-by-sibling-index-not-tree-order, gotchas/animationtree-reset-track-overwrites-script-writes, gotchas/physics-parent-before-children-one-frame-lag]
created: 2026-10-30
updated: 2026-10-30
source_files:
  - scenes/characters/guardians/guardian.gd
  - scenes/characters/guardians/guardian_fight.gd
  - scenes/characters/ivo/abilities/memorina_component.gd
  - scenes/characters/ivo/player.gd
  - scenes/world/world_freeze.gd
  - scenes/world/memory/greyhush.gdshader
  - scenes/world/rooms/region.gd
  - resources/save_facts/save_fact.gd
  - scenes/world/rooms/frost_edge/contents/lighthouse_top.room
  - scenes/world/rooms/frost_edge/contents/lighthouse_interior_contents.tscn
---

# GRD-06 plan: the final battle

**Status: proposed.** Design 02 section 5 (5.1-5.3), 01 sections 3-4 and 9.4, 04 section 3.3 (`lighthouse_top` is the arena, the hatch reads `all_guardians_restored`). Contract `systems/guardians`, unchanged except where stated.

## Context (what exists)

- The mentor exists only as story stills (`assets/sprites/world/story/mentor/`: `empty_hand`, `memorina_in_hand`, `stasis` 86x120, `raise` 5 f, `play` 6 f) in `lighthouse_interior_contents.tscn` under a `FactStaging` (Holding, then Stasis once `mentor_gift` is heard), speakers `mentor.tres` / `mentor_stasis.tres`, portraits `mentor.png` / `mentor_stasis.png`. `mentor_phrase.tres` is Freeze's first four notes. No guardian sheet.
- `lighthouse_top.room`: one screen, floor row 21, interior x 48..592, its only exit the hatch door (col 20). Doors already refuse Up while `Guardian.fight_at` holds (`player.gd:747`), so **no `FightWall` is needed**.
- `Enums.Guardian` has four members and `ALL_GUARDIANS_RESTORED` loops over all of them; `GuardianStats.id` feeds `meet_guardian` / `restore_guardian` / `is_guardian_restored`.
- Ivo's notes ring in real time (`MemorinaVoice`, ticks msec); `PhraseCall` runs on the scaled clock.

## Decision

### 1. Composition: a scene, a stats file and one strategy child

- `scenes/characters/guardians/mentor/mentor_guardian.tscn` (built from `frost_guardian.tscn`) + `resources/characters/guardians/mentor/mentor_stats.tres`, plus a child **`Finale`** (`GuardianFinale`, Node) and a second `PhraseCall` **`CallB`** (second voice, same `note_interval`, started in sync with `Call`).
- `GuardianStats.finale: FinaleStats` (new optional export). When set, `Guardian` resolves `$Finale` in `_ready` (asserted) and **delegates at five seams**, one call each, no dissonance logic in `guardian.gd`: (1) the call opened at the leap's landing; (2) `call_committed` / `call_mixed` / `call_answered`; (3) `_restore`; (4) the restored check in `_ready` and `meet_guardian` in `_on_player_entered` (the mentor has no `Enums.Guardian` id); (5) `is_teaching()` (true while the restoration scene plays, so the resolver plays `perform` / `perform_end` unchanged).
- Options weighed: a `MentorGuardian` subclass (the contract forbids it while a resource plus a component can describe the behaviour); finale branches inside `guardian.gd` (dissonance knowledge in every guardian); adding `MENTOR` to `Enums.Guardian` (breaks the hatch gate - the mentor would have to be restored to reach him - plus the notebook list, `restored_guardian_count`, the village 0.6 step). **Chosen: the strategy child** (Open/Closed: `Guardian` learns five seams, not the finale; Single Responsibility: `GuardianFinale` owns the finale stages, `GuardianFight` keeps phases and the clock).
- **Pure logic, `RefCounted`, tested:**
  - `FinaleFight` (`scenes/characters/guardians/finale/finale_fight.gd`): stage per window `WINTER` (while `cycles < winter_cycles`), `REVELATION` (the next window, exactly once), `DUAL` (every window after); the revelation's level and peak (`revelation_notes`, or `revelation_max_seconds` real); mixed counters and their consequences (`damage_for_mixed()`, `veil()`, `drain()`); the final chain index.
  - `DualCallJudge` (`scenes/characters/components/dual_call_judge.gd`, the `PhraseEcho` precedent): judges one answer against tracks A and B.
  - `GuardianFight` gets three generic, mentor-blind additions: `set_drain(scale)` (the window ticks `delta * scale`; the fraction keeps its total), `continue_window(call_length)` (stays in LUCIDITY and re-opens the window for the next phrase, no cycle), `dismiss()` (LUCIDITY to PRESSURE, hits 0, no aggression, no relapse). The fight still owns the one clock; HUDs only draw it.
- `FinaleStats` (`resources/characters/guardians/finale_stats.gd`): `second_song: Song` (Q1), `winter_cycles` 1 (asserted >= 1: design 5.1 "pelo menos uma janela de lucidez normal"), `revelation_notes` 3, `revelation_max_seconds` 5.0, `freeze_frame_seconds` 0.3, `stabilise_seconds` 0.4 (real), `dual_revealed` 4, `mixed_damage: Array[int]` [0, 1, 1, 2] (by mixed inputs since the revelation, last repeats), `mixed_drain` 0.6 (drain = 1 + 0.6 x mixed in this window), `veil_per_mixed` 0.35, `final_phrases: Array[Song]` (Q2), `revealed_attacks: Array[GuardianAttack]` (the two winter moves plus the second-season move), `dissonance_color`, `restoration_scene: Cutscene`, `retry_revealed: bool` (Q3). Mentor `GuardianStats`: `song` = `freeze.tres` (the winter windows' call), `cycles_to_restore` = `winter_cycles + 1` (the final chain is the last cycle), `revealed_notes` 3 (the most corrupted: design 3 "fragmentada"), no recall (all three skills are already held), `attacks` = the two winter moves only.

### 2. The two-track call

- **Data:** two `Song`s, A = `stats.song` (winter), B = `finale.second_song`. Both are six notes; they must differ at index 0 (asserted, so the first note always commits).
- **Presentation:** `Call` and `CallB` sound note i together. `Player.open_call(..., second: Song = null, solvable := true)` installs `MemorinaComponent.call_second` beside `call_song` and emits a new `call_second_track(song, solvable)` after `call_opened` (existing signature untouched). `NoteSheet` draws track B as a second glyph row on the same staff in B's palette tint, offset half a slot when the pitches coincide; `GuardianCallHud` and `MemorinaHud` light both.
- **Judging** (`DualCallJudge.feed(note)`, `i` = notes in the current answer, `live` = tracks still equal to the answer, starting {A, B}):
  - the note is `live` track's note at i: append; when `live` narrows to one track, `COMMITTED(track)`; at six, `COMPLETE(track)`.
  - **mixed:** the note is the *other* track's note at i (only possible once committed): `MIXED`; the answer resets to empty, `live` back to {A, B}; the window stays open.
  - neither track's note at i: `WRONG`, the ordinary failure (`sequence_failed`, answer fails, relapse), same vocabulary as every call.
  - **unsolvable** (the revelation): every note after the first is `MIXED`, `COMPLETE` never comes.
- `MemorinaComponent` routes to the judge when `call_second != null` (as it routes to `_echo`) and emits `call_committed(song)`, `call_mixed(count)`, `call_answered(song)`; `Player` relays all three. A mixed note sounds with its partner (the committed track's note at i) on a second `MemorinaVoice` under Ivo: the clash is heard.
- **Consequences of mixed** (design 5.3): input 1 of a window is the mild warning (the clash, the sheet trembles, no damage, no veil); from input 2 the veil rises (`veil_per_mixed` x (m - 1)), damage `mixed_damage[n]` goes straight through `Health` (as a recall miss), and `GuardianFight.set_drain` speeds the window. **Choosing:** on `COMMITTED` the other row fades with each pure note; on `COMPLETE` of either track (decision: design says "uma trilha só", not which) the veil clears, the guardian pulses normally and the final chain begins in the same window (`continue_window`): each `final_phrases` entry called alone, fully revealed; a fault in the chain is an ordinary failure, and the next window is two-track again (5.3: dissonance is "o restante da luta"). The last phrase answered is `answer_succeeded()`: RESTORED.

### 3. The revelation window (no cutscene)

- It is a normal lucidity (hits, `lucid_enter`, leap, bark) whose call is two-track and **unsolvable**; no time bar (no window clock: "sem punição real"). The director, `StoryActor` and `CutsceneDirector` are not used: nothing is handed over, no actor enters, so the "same pose" return is free - both bodies stand where the landing left them.
- When the call ends: `WorldFreeze.slow()` (the recall's vocabulary; Ivo's notes still ring in real time). Each note raises the level by 1/`revelation_notes`; at the peak (or `revelation_max_seconds` real, ticked as `AbilityRecallComponent` does): shatter, `WorldFreeze.hit_stop(freeze_frame_seconds)` (new optional duration argument), `restore()` (the clock snaps to 1 when the stop ends), effects fall over `stabilise_seconds`, `Player.close_call(true)` (quiet), `GuardianFight.dismiss()`, `_ai.attacks = revealed_attacks`, unstage. `WorldFreeze` stays the only writer of `time_scale` / `paused`.
- **Effects and their owners** (all in game pixels, animated from `greyhush_time`, never `TIME` / `FRAGCOORD`; the freeze frame freezes them for free because `greyhush_time` advances by the scaled delta):
  - `DissonanceFx` (Node in `game.tscn`, INHERIT, added to the pause-mode map): the **only writer** of two new `[shader_globals]` `dissonance_revelation` and `dissonance_veil` (0..1), fed by `Player.dissonance_changed(veil, revelation)`; it zeroes both in `_ready` and `_exit_tree` (globals outlive a death's scene swap, like `Engine.time_scale` in `WorldFreeze`).
  - `dissonance.gdshaderinc` included by `greyhush.gdshader`: scanline interlace (rows of `band_px` game pixels slide by whole game pixels; alternate rows show the source colour unshaded, the "past" scenery) and the palette glitch (winter tint dithered into neutral pixels, Bayer threshold jittered per row). Rendering-only: `MemoryFieldMath` has no twin, as the wobble has none; `gh_influence` is untouched.
  - `DissonanceVeil`: a `BackBufferCopy` plus a ColorRect after `Foreground` in `CanvasLayer` (a same-layer reader needs the copy: `gotchas/screen-texture-copy-scope`), under every HUD: the unstable grey (luma plus per-art-pixel static re-rolled on `greyhush_time`, row jitter) by `dissonance_veil`, and the shatter cracks at the peak.
  - `HeroSilhouette` (Ivo child on the creature layer, as `RecallAura`, wired in `ivo.tscn` from Ivo's signals): owns Ivo's `Sprite2D.material` while active (`hero_silhouette.gdshader`, flat `dissonance_color`, art-pixel fray; asserts the sprite has no material; alpha 1, never the 253 unshielded mark) and a `PastSelf` Sprite2D (the original guardian) whose visibility it alternates with the silhouette, faster with the level, fused at the peak.

### 4. The second frequency

Not stated in the design (01 section 4: "por amor"; the object is open). **Q1.**

### 5. Victory, the seam to STORY-07 / UI-06, death

- **Save:** `PlayerData.world_restored: bool` (migrated false), `SaveSystem.restore_world()` emitting `world_restored`, `SaveFact.Kind.WORLD_RESTORED` (appended). Live data like a restored guardian (Q4 for keeping it). Every region derives 1.0 from it: `Region` lifts its own `RegionMemory` with `restore(lift_time)` if it is the live region, else `restore(0)` on build (`RegionMemory` still never reads `SaveSystem`); the village's 1.0 "no Retorno" (design 04) is the same derivation.
- **Flow:** the last phrase -> `_restore` -> `GuardianFinale.restored()`: `restore_world()`, then `CutsceneDirector.play(restoration_scene, host)` - `world_restoration.tres`, a data `Cutscene` in the lantern: bars, the camera pulls back, the mentor's `perform` (via `is_teaching`), the winter track (`CutsceneSound`), the lantern lamp (`CutsceneShow` of a `CutsceneVisual`), colour running out over the backdrop, a fade. Skippable (the fact is already written). A montage of other regions was rejected: it would need rooms of other regions resident.
- **Seam:** GRD-06 ends with SCENE_SEEN `world_restoration` and the lantern at rest (mentor RESTORED, talkable). STORY-07 arms its return from that fact; UI-06 opens after STORY-07's last scene. Neither is built here.
- **Staging:** the interior `Mentor` FactStaging gains a first-priority stage `when ALL_GUARDIANS_RESTORED -> Gone` (an empty child): he has climbed to the lantern; derived, so a death that rewinds the fourth guardian puts him back.
- **Death mid-fight:** the ordinary rule (`systems/life-benches-death`): rewind to the last bench (Frost Cliffs), mentor unrestored, a death mark in Frost Edge. Dissonance damage can kill. Whether the revelation replays is Q3.

### 6. The arena, art, songs, lines

- **Arena:** `lighthouse_top_contents.tscn`: the guardian at (448, 336), an `Arena` over x 48..592, `lucidity_leap_distance` 300, margin 96. `frost_edge.tscn`'s `Region` stays `has_guardian` false (no id); `smoke/scenes.txt` gets the mentor scene.
- **Art** (`tools/art/prompts/guardian_mentor_<clip>.md`, reference our own `story/mentor/empty_hand.png`; frames 128x96 at Sprite2D scale 2, body 43x60 art px = the story still's 86x120): the 14 GRD-07/08 strips (idle, walk, attack_1-3, hurt, lucid, lucid_enter, play_song, relapse, perform, perform_end, restored, leap 8 f) with GRD-04's timings, so the startup asserts hold; **proposal for the art review:** he has no flute (Ivo holds it), so `play_song` / `perform` are the empty raised hand of the stasis pose, fingering an absent pipe. Plus `past_self.png` (the original guardian, lucid and coloured, 4 f). Moves: attack_1 a slow frost sweep (close), attack_2 a heavy two-handed slam (tall box), attack_3 the second-season move, added at the revelation. Estimate: ~38 PixelLab calls (GRD-04 spent 35 on 14 strips) plus the past self; no new portrait (the mentor has none in the notebook's guardian list).
- **Audio:** the clash (two notes), the shatter; placeholders via `tools/audio/synth_story_placeholders.py`.
- **Songs:** `freeze.tres` (A, winter windows), `second_song` (Q1), `final_phrases` (Q2). None is learned: the mentor teaches nothing.
- **Lines to write and approve** (keys in `i18n/translations.csv`, `GuardianVoice` on `mentor_stats.tres`, plate `SPEAKER_MENTOR`): `BARK_MENTOR_LUCID_0` (the winter window, in the stutter `~word~` of 05), `BARK_MENTOR_DUAL` (the first two-track call), `BARK_MENTOR_RETRY`, `BARK_MENTOR_FINAL` (as the final chain begins); the revelation is wordless; talks after victory `mentor_first` (once) and `mentor_again`. The mentor's name is open (01 section 4; "revelado só no fragmento final") - if it is spoken, it belongs in `mentor_first`. No HUD caption (show, not tell). Every key passes `bark_text_fit_test` / `dialogue_text_fit_test`.

## Build order and tests

1. `GuardianFight` additions + tests; `DualCallJudge` + `dual_call_judge_test` (commit on the first distinguishing note, mixed only after commitment and resetting the answer, wrong is a failure, complete, unsolvable); `FinaleFight` + `finale_fight_test` (stages, revelation once, damage table, drain, veil, chain).
2. `WorldFreeze.hit_stop(seconds)` + test; `world_restored`, `WORLD_RESTORED`, migrate, `Region` derivation + `save_fact_test`, `player_data_test`, `region_test`.
3. `MemorinaComponent` / `Player` dual call, relays, `dissonance_changed`, `dissonance_hurt` + `player_dual_call_test`.
4. `FinaleStats`, `GuardianFinale`, the five `Guardian` seams + `guardian_finale_test` (bodies unmoved by the revelation, scale 1 after it, attacks swapped, no aggression; a pure track starts the chain; the last phrase writes the fact and plays the scene).
5. `DissonanceFx`, `dissonance.gdshaderinc`, `DissonanceVeil`, `HeroSilhouette` + `dissonance_fx_test` (globals zeroed on ready and exit); the verify-gates `TIME` / `FRAGCOORD` scan.
6. `NoteSheet` second row, both HUDs + a fit check for two rows.
7. Placeholder sheets, mentor scene, arena, interior stage, `world_restoration.tres`; `guardian_voice_test`, `combat_reach_test`, `guardian_performance_animation_test`, `guardian_leap_framing_test` extended to the mentor; smoke; then the drawn art; playtest (readability of two rows, the revelation's length, damage).
8. Docs: `systems/guardians` (finale section, the five seams), `systems/greyhush` (the two globals), `systems/songs-and-the-memorina` (pause map), `glossary.md` (dissonância `dissonance`, revelação `revelation`, Grande Provação `finale`; `crack` is taken).

## Consequences and risks

- Two glyph rows on one six-slot staff may not read; playtest before the art spend.
- The retry path is long (bench in Frost Cliffs, then the helix stair).
- `NoteSheet` and both HUDs gain a second-track mode that only one encounter uses.
- Shader globals persist across scene swaps; `DissonanceFx` must reset them or a death leaves the world interlaced.
- Ivo's sprite material is borrowed by `HeroSilhouette`; a future material on Ivo must share it through that owner.

## Open questions (user)

- **Q1 The second season.** (a) Spring: the village's season, and the gift beat already pulses `root.tres` under the wife's hum (**recommended**); (b) Summer: winter's opposite; (c) Autumn: the season that teaches letting go, held by the one who could not.
- **Q2 The final call.** (a) His whole winter: Freeze then Redoma, 12 notes on two sheets (**recommended**); (b) the four base songs, one per restored guardian, 24 notes; (c) Freeze three times, fewer notes revealed each time.
- **Q3 After a death, does the revelation play again?** (a) Once per save, kept through death like `notebook_read`: later attempts go two-track after the first winter window (**recommended**: design "único, não se repete"); (b) every attempt (nothing recorded).
- **Q4 Keeping the victory.** (a) Only benches, unchanged: walk down to the Frost Cliffs bench; (b) the victory writes the save at once, one documented exception; (c) the restoration scene ends with Ivo sitting on a lantern bench that exists once the world is restored, so only benches still save (**recommended**).

## User decisions on the open questions (2026-10-30)

- **Q1:** "Primavera (Recommended)": track B is spring (`root.tres`).
- **Q2:** "Uma canção que ainda irei criar, especial. Pode utilizar da sequencia de 12 notas sim": the final call is a special song the user will compose. Until then it is a placeholder `Song` resource of 12 notes (Freeze then Redoma's notes), marked as a placeholder in its file and in `systems/guardians`; swapping in the user's song is data only.
- **Q3:** "Uma vez por save (Recommended)": the revelation is recorded once per save and kept through death.
- **Q4:** "Exceção: salva na hora": the victory writes the save at once, the one documented exception to "only benches save" (`systems/life-benches-death` and the CLAUDE.md Systems row change in the same commit as the code).
