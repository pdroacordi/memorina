class_name PlayerAnimator
extends AnimationTree
## Reacts to Player's discrete signals to force an immediate animation state
## switch, bypassing the state machine's transition graph (which only ever
## advances forward and has no edge back into an already-visited state).

# _position is unused, but must stay in the signature: ivo.tscn connects
# Player's double_jumped(position: Vector2) signal directly to this method, and
# trimming the parameter would silently break that editor connection.
func play_air_spin(_position: Vector2) -> void:
	var playback: AnimationNodeStateMachinePlayback = get("parameters/playback")
	playback.start(&"air_spin")
