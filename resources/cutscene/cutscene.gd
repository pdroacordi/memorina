class_name Cutscene
extends Resource
## A scene as data: steps played in order between two rest states (systems/cutscenes).

## Unique in the CutsceneCatalog; the SCENE_SEEN id recorded at its end or skip.
@export var id: StringName = &""
@export var steps: Array[CutsceneStep] = []
## Whether the pause menu offers "Skip scene" while it plays.
@export var skippable: bool = true
