---
id: bugs/the-pause-menus-intent-line-draws-over-an-engraving-caption
type: bug
title: The pause menu's intent line draws over an engraving caption in the bottom bar
status: active
severity: low
tags: [pause-menu, notices, engraving, final-fragment, bearer-fragments, ui, story-42]
related: [playtests/2026-11-18-story42-final-fragment, systems/screens, systems/notices, systems/bearer-fragments, architecture/story42-the-final-fragment]
created: 2026-11-18
updated: 2026-11-18
source_files:
  - scenes/ui/pause_menu/pause_menu.gd
  - scenes/ui/engraving/engraving_view.gd
---

## Summary

If the pause menu is opened during an engraving scene (the final fragment, or any bearer fragment) and a caption is
showing, the menu's intent line ("Para casa.") draws in the bottom bar on top of the caption. Both texts are cream on
the black bar, so the result is garbled. This happens every time the player opens the menu to reach "Pular cena".

## Symptom

STORY-42 playtest, `skip` run (pt_BR, trigger path), pause opened at t 30 on panel 3, turn 2. The screenshot
`docs/knowledge/playtests/screenshots/2026-11-18-story42-final-fragment/skip_menu_intent_over_caption.png` shows
"Segurou o frio, e segurou a flor." (dimmed by the menu's backdrop) with "Para casa." over its middle, about 8 game px
lower. The same overlap appears with "Pular cena" focused.

## Root cause (from reading, not traced)

`pause_menu.gd` `_show_intent` puts the intent line `INTENT_GAP` (6 art px) under the panel, and the panel is taller
when "Skip scene" is offered (`pause_menu.gd:128`, "whose height follows Skip scene"). With five buttons, that puts
the line inside the letterbox's bottom bar. The menu offers "Skip scene" only while a scene plays, and in an engraving
scene the bar holds `EngravingView`'s caption, which stays drawn under the pause.

## Fix direction

Either hide the intent line while a scene plays (the menu already knows, because it offers "Skip scene"), or hide the
engraving caption while the tree is held. Hiding the intent is the smaller change. The intent's purpose (where am I
going) also says little in the middle of a cutscene.

## Repro

Seed `world_restored` with `scenes_seen: ["mentor_wakes"]`, spawn at the lantern hatch (12048, -1254) so
`FinalFragment` plays, and press Escape during any caption turn.
