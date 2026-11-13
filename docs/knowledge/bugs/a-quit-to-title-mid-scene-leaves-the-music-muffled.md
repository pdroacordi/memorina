---
id: bugs/a-quit-to-title-mid-scene-leaves-the-music-muffled
type: bug
title: Quitting to the title during a scene with a CutsceneMuffle leaves the Music bus low-passed for the rest of the session
status: resolved
severity: medium
tags: [music, muffle, cutscene, quit, autoload, story-05, flashback]
related: [systems/music, systems/cutscenes, architecture/story-05-playable-flashbacks, gotchas/a-node-idled-or-swapped-out-keeps-what-it-opened-in-an-autoload]
created: 2026-11-13
updated: 2026-11-13
source_files:
  - scenes/world/cutscene/cutscene_director.gd
  - scenes/world/cutscene/world_cutscene_context.gd
  - globals/music/music.gd
  - globals/music/music_mix.gd
---

## Summary

`Music.muffle(&"cutscene", amount)` is opened by a scene's `CutsceneMuffle` step and closed only by
`WorldCutsceneContext.restore()`. When the world is swapped out mid-scene, `restore()` never runs, so the low-pass stays
on the `Music` autoload's bus through the title screen and the next session.

## Symptom

Pause during `flashback_2_crossing` (muffle 0.9 at its third step), `flashback_4_crossing`, or flashback 1's leaving scene
(`flashback_1`, muffle 0.85), then choose Quit to title. The title theme, and every piece in the game started from it,
plays low-passed (`MusicMix.cutoff_hz()`: about 590 Hz at 0.9). It lasts until some later scene runs a muffle step and
ends normally. Restarting the executable is the only other way out.

## Root cause

- `scenes/world/cutscene/world_cutscene_context.gd:156-161` opens and closes the named muffle `MUFFLE_ID` and remembers
  it in `_muffled`. `restore()` (`:236-237`) is the only place that closes it.
- `scenes/world/cutscene/cutscene_director.gd:60-64` `_exit_tree()` drops `_context` without calling `restore()`. A death
  or hurt drops the scene through `interrupt()` → `_end(false)` → `restore()`. Quit to title is the one path that does
  not: `Game.quit_to_title` → `SceneSwap.replace`.
- `Music` is an autoload and `MusicMix._muffles` is keyed by name, not owned by a node. Music requests are released when
  their owner leaves the tree; muffles are not. A later scene clears the name only if that scene muffled too
  (`_muffled` is per context).

## Fix

Fixed 2026-11-13 (the `fix(story)` commit of STORY-05's review). Ducks and muffles are owned: `Music.duck(id, db, owner)` and
`Music.muffle(id, amount, owner)`, closed by `MusicMix.prune()` once the owner is freed, leaves the tree or is disabled
(`MusicMix.holds`, by instance id, since a freed node cannot be passed to a typed argument). `WorldCutsceneContext` opens
its muffle owned by the director, so a quit closes it. Tests: `cutscene_director_test`
`test_a_muffle_closes_when_the_director_is_freed_mid_scene`, `music_logic_test`
`test_an_owned_duck_and_muffle_close_with_their_owner`.

The options weighed:
- Preferred: tie a muffle to an owner node, the same way `Music.request` is tied. For example
  `Music.muffle(id, amount, owner)`, with Music dropping the muffle when the owner exits the tree. This also covers
  `FlashbackLure` and any future muffle user.
- Minimal: in `CutsceneDirector._exit_tree()`, call a context method that closes what lives in autoloads (the muffle)
  before dropping `_context`.

Add a test: play a scene with a `CutsceneMuffle`, free the director, and assert `Music.muffled()` returns to 0.

## Prevention

Anything a world node opens in an autoload by name (ducks, muffles, holds) must close when the node leaves the tree, not
only when its own flow ends. Check the quit-to-title path whenever a scene step writes into an autoload.
