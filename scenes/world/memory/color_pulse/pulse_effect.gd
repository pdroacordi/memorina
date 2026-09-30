class_name PulseEffect extends Node2D

## What a song does by itself, riding the pulse that carries it: Song.pulse_effect
## is a scene whose root extends this, and ColorPulse mounts it at the pulse's
## centre with `pulse` set. Receivers in the world answer a song; an effect is
## the song - the gale's field, the bell jar's shell, the burned shadow.
##
## It is freed with its pulse, so an effect never outlives the colour that
## made it; anything that must linger (roots withering, water draining) is
## the world's, not the effect's.

## The pulse carrying this effect. Set before the effect enters the tree.
var pulse: ColorPulse

func _init() -> void:
	# The pulse runs through pauses (a lesson freezes time, not memory), but
	# what a song DOES is world time: a gale must not blow under a pause menu.
	process_mode = Node.PROCESS_MODE_PAUSABLE
