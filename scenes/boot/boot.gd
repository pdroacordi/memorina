extends Node
## The main scene: swaps itself for the game when SaveSystem began a session (debug builds), else for the title.

## Paths, loaded at swap time, so Boot holds neither scene while the other runs.
@export_file("*.tscn") var game_scene: String = ""
@export_file("*.tscn") var title_scene: String = ""


# Deferred: a node cannot leave its parent while the parent is still adding it.
func _ready() -> void:
	_swap.call_deferred(game_scene if SaveSystem.has_session() else title_scene)

func _swap(path: String) -> void:
	SceneSwap.replace(self, load(path) as PackedScene)
