class_name CutsceneSequence
extends CutsceneStep
## Its steps one after another; a shared sub-sequence can live in its own .tres.

@export var steps: Array[CutsceneStep] = []
