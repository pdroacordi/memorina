class_name AnimationDriver
extends Node
## Plays whatever animation state it is handed. Switches only when the state
## changes, so a clip already in progress is never restarted by repeated calls
## — except after request_replay(), for events that must restart the same clip
## (a second identical attack chained with no gap in between).

## The state most recently started.
var current: StringName = &""

var _replay_requested: bool = false

@onready var _animation_tree: AnimationTree = %AnimationTree
@onready var _playback: AnimationNodeStateMachinePlayback = _animation_tree.get("parameters/playback")
@onready var _animation_player: AnimationPlayer = _animation_tree.get_node(_animation_tree.anim_player)


func play(state: StringName) -> void:
	if state == current and not _replay_requested:
		return
	_replay_requested = false
	current = state
	_playback.start(state)

func request_replay() -> void:
	_replay_requested = true

## Whether the current clip has played to its end. Only meaningful for
## non-looping clips; a loop never finishes.
func is_finished() -> bool:
	return _playback.get_current_play_position() >= _playback.get_current_length() - 0.0001

## Whether `state` is the current clip and still mid-play — how a resolver
## keeps a one-shot on screen until it ends.
func holding(state: StringName) -> bool:
	return current == state and not is_finished()

## Whether `state` is the current clip and has played to its end.
func finished(state: StringName) -> bool:
	return current == state and is_finished()

## Resolves an intro-then-loop pair: `intro` once, then `loop`. Both express
## one logical state, so a resolver only asks while that state holds.
func sequence(intro: StringName, loop: StringName, skip_intro: bool = false) -> StringName:
	if current == loop:
		return loop
	if current == intro:
		return intro if not is_finished() else loop
	return loop if skip_intro else intro

## Length of the clip behind `state`, for checking gameplay durations that
## must stay in step with it.
func clip_length(state: StringName) -> float:
	var machine: AnimationNodeStateMachine = _animation_tree.tree_root
	var node: AnimationNodeAnimation = machine.get_node(state)
	return _animation_player.get_animation(node.animation).length
