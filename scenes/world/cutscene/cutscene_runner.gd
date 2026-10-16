class_name CutsceneRunner
extends RefCounted
## Walks a Cutscene's step tree, a branch read when reached against the live save; `to_land()` hands a skip what is left
## up to the next talk (systems/cutscenes).

enum State { PENDING, RUNNING, DONE }
enum Shape { LEAF, SEQUENCE, TOGETHER }

## Leaf steps by id, in the order they were reached.
var _leaves: Array[CutsceneStep] = []
## Leaf id -> its Run.
var _runs: Dictionary[int, Run] = {}
var _root: Run
var _data: PlayerData


func _init(scene: Cutscene, data: PlayerData) -> void:
	_data = data
	_root = Run.new()
	_root.shape = Shape.SEQUENCE
	_root.items = scene.steps

## The leaf ids that begin now, in tree order; marked running.
func next() -> PackedInt32Array:
	var started := PackedInt32Array()
	_advance(_root, started, false)
	return started

## The leaf `id` is over.
func done(id: int) -> void:
	var run: Run = _runs.get(id, null)
	if run != null:
		run.state = State.DONE

func step(id: int) -> CutsceneStep:
	return _leaves[id]

func is_running(id: int) -> bool:
	var run: Run = _runs.get(id, null)
	return run != null and run.state == State.RUNNING

## Every leaf begun and not yet over, in the order begun.
func running() -> PackedInt32Array:
	var ids := PackedInt32Array()
	for id: int in _leaves.size():
		if is_running(id):
			ids.append(id)
	return ids

func is_finished() -> bool:
	return _root.state == State.DONE

## Ends every running leaf and every leaf up to the next talk, and returns them in order to be landed. A talk is left
## to begin from `next()`: a skip never chooses for the player.
func to_land() -> Array[CutsceneStep]:
	var landed: Array[CutsceneStep] = []
	while true:
		for id: int in running():
			landed.append(_leaves[id])
			done(id)
		var started := PackedInt32Array()
		_advance(_root, started, true)
		if started.is_empty():
			break
	return landed

func _advance(run: Run, started: PackedInt32Array, before_talk: bool) -> void:
	match run.shape:
		Shape.LEAF:
			if run.state != State.PENDING:
				return
			if before_talk and _leaves[run.id] is CutsceneTalk:
				return
			run.state = State.RUNNING
			started.append(run.id)
		Shape.SEQUENCE:
			while true:
				if run.live.is_empty():
					if run.index >= run.items.size():
						run.state = State.DONE
						return
					run.live.append(_make(run.items[run.index]))
					run.index += 1
				var child := run.live[0]
				_advance(child, started, before_talk)
				if child.state != State.DONE:
					return
				run.live.clear()
		Shape.TOGETHER:
			if run.state == State.PENDING:
				run.state = State.RUNNING
				for item: CutsceneStep in run.items:
					run.live.append(_make(item))
			var all_done := true
			for child: Run in run.live:
				_advance(child, started, before_talk)
				all_done = all_done and child.state == State.DONE
			if all_done:
				run.state = State.DONE

func _make(item: CutsceneStep) -> Run:
	var run := Run.new()
	if item is CutsceneSequence:
		run.shape = Shape.SEQUENCE
		run.items = (item as CutsceneSequence).steps
	elif item is CutsceneTogether:
		run.shape = Shape.TOGETHER
		run.items = (item as CutsceneTogether).steps
	elif item is CutsceneBranch:
		run.shape = Shape.SEQUENCE
		run.items = (item as CutsceneBranch).pick(_data)
	else:
		run.shape = Shape.LEAF
		run.id = _leaves.size()
		_leaves.append(item)
		_runs[run.id] = run
	return run


## One reached node of the tree.
class Run:
	var shape: Shape = Shape.LEAF
	var state: State = State.PENDING
	var items: Array[CutsceneStep] = []
	## SEQUENCE: the next item to make.
	var index: int = 0
	## The children running now: one for a sequence, all for a together.
	var live: Array[Run] = []
	## LEAF: its id in `_leaves`.
	var id: int = -1
