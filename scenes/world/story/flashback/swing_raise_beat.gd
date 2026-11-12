class_name SwingRaiseBeat
extends DialogueBeat
## Ivo raises the fallen swing by holding Up (flashback 3, systems/story): HoldRise decides each step, this node stands in
## the swing's rise and grows `bloom` up the rope; at the top the swing hangs and swings once, and the talk goes on.
## Given up, the swing falls back, the colour goes and the talk ends unheard.

@export var swing: FactStaging
## The staging's children for steps 1..steps - 1, lowest first.
@export var rising: Array[StringName] = []
## The staging's child shown at the top.
@export var raised: StringName = &""
## Swung once at the top.
@export var raised_sway: SwingSway
## Grown from its node (the rope's foot) up the rope.
@export var bloom: MemoryBloom
## Px from the bloom's node up to the branch.
@export var rope_height: float = 104.0
## Px wide.
@export var bloom_width: float = 48.0
## Scaled seconds held per step.
@export var step_seconds: float = 0.5
@export var steps: int = 4
## Scaled seconds at the bottom, not holding, before the talk ends unheard.
@export var idle_seconds: float = 1.5
## Scaled seconds a step of colour takes.
@export var bloom_seconds: float = 0.3

## Whether Up is held; empty at start asks the world's Player (`Player.up_held`).
var up_held: Callable

var _rise: HoldRise
var _level: int = 0
var _running: bool = false


func _init() -> void:
	hold = Hold.HELD_UP

func _process(delta: float) -> void:
	if not _running:
		return
	_rise.tick(delta, up_held.is_valid() and up_held.call())
	if _rise.level() != _level:
		_step_to(_rise.level())
	if _rise.is_finished():
		_running = false
		swing.stand_in(raised)
		if raised_sway != null:
			raised_sway.push()
		finish()
	elif _rise.is_abandoned():
		_running = false
		_step_to(0)
		bloom.reset()
		abandon()

func start() -> void:
	if not up_held.is_valid():
		var director := CutsceneDirector.find(get_tree())
		if director != null and director.ivo != null:
			up_held = director.ivo.up_held
	_rise = HoldRise.new(step_seconds, steps, idle_seconds)
	_level = 0
	_running = true
	super()

func is_running() -> bool:
	return _running

## Steps reached, 0..steps.
func level() -> int:
	return _level

func _step_to(level: int) -> void:
	_level = level
	if level <= 0:
		swing.release(swing.shown().name if swing.shown() != null else &"")
	elif level - 1 < rising.size():
		swing.stand_in(rising[level - 1])
	var height := rope_height * float(level) / float(steps)
	var foot := bloom.global_position
	bloom.bloom_to(MemoryFieldMath.Shape.RECT, Vector2(bloom_width, height), 0.0, foot + Vector2(0.0, -height * 0.5),
			1.0 if level > 0 else 0.0, 0.3, bloom_seconds)
