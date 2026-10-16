class_name CutsceneTogether
extends CutsceneStep
## Its steps all at once; it ends when the last of them ends. No talk inside one (CutsceneCatalog.validate).

@export var steps: Array[CutsceneStep] = []
