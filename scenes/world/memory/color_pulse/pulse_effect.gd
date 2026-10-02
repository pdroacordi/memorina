class_name PulseEffect extends Node2D

## Base class for song effects mounted on their pulse; effects are freed with the pulse.

## The pulse carrying this effect. Set before the effect enters the tree.
var pulse: ColorPulse

func _init() -> void:
	# Effects use world time so their behavior pauses with gameplay, while the pulse may continue through lessons.
	process_mode = Node.PROCESS_MODE_PAUSABLE
