class_name BootPolicy
extends RefCounted
## Which session SaveSystem begins at boot; see docs/knowledge/architecture/save-slots-and-the-boot-swap.md.

## MEMORY never touches user://. NONE begins nothing, so Boot shows the title.
enum Session { MEMORY, SLOT_1, SLOT_1_FRESH, NONE }

const NEW_GAME_ARG := "--new-game"
const TITLE_ARG := "--title"
## The playtest runner's scene, as Godot is launched with it.
const RUNNER_SCENE_FILE := "playtest_runner.tscn"


## `args` are the engine arguments (the scene path among them); `user_args` are the ones after `--`.
static func decide(headless: bool, debug: bool, args: PackedStringArray, user_args: PackedStringArray) -> Session:
	if headless or _runs_the_runner(args):
		return Session.MEMORY
	if not debug or TITLE_ARG in user_args:
		return Session.NONE
	return Session.SLOT_1_FRESH if NEW_GAME_ARG in user_args else Session.SLOT_1

static func _runs_the_runner(args: PackedStringArray) -> bool:
	for arg: String in args:
		if arg.get_file() == RUNNER_SCENE_FILE:
			return true
	return false
