class_name CutsceneTrigger
extends Node
## Starts a cutscene when Ivo is in its room, after `delay`, once Player.can_begin_scene() holds (systems/cutscenes).
## Armed by Game.room_changed through the CutsceneDirector, like the region title; lives in a contents scene.

const GROUP := &"cutscene_triggers"

@export var cutscene: Cutscene
@export var when: Array[SaveFact] = []
@export var unless: Array[SaveFact] = []
## Scaled seconds after the room is entered.
@export var delay: float = 0.0
## A seen scene plays again.
@export var repeat: bool = false
## The room opens on this scene in black (the new game's start): it plays as soon as its contents are in the world,
## without waiting for Ivo's gates, and its first step owns the fade.
@export var from_black: bool = false


func _enter_tree() -> void:
	add_to_group(GROUP)

## Whether it would play under `data`.
func wants(data: PlayerData) -> bool:
	if cutscene == null or (not repeat and data.scenes_seen.has(cutscene.id)):
		return false
	return SaveFact.gates_pass(when, unless, data)
