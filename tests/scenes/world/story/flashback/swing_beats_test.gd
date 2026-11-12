class_name SwingBeatsTest extends GdUnitTestSuite

## Flashback 3's swing (systems/story): holding Up raises it a step every 0.5 s with colour up the rope, letting go lets
## it fall back, the top hangs it and swings it once, and a full recede left idle gives the talk up. A push swings the
## swing out and it dies down by itself once let go.

const SWAY := preload("res://scenes/world/story/flashback/swing/swing_sway.tscn")

var _root: Node2D
var _swing: FactStaging
var _beat: SwingRaiseBeat
var _held: Array[bool] = [false]
var _ends: PackedStringArray


func before_test() -> void:
	_held[0] = false
	_ends = PackedStringArray()
	_root = auto_free(Node2D.new()) as Node2D
	_swing = FactStaging.new()
	var fallen := FactStage.new()
	fallen.show = &"Fallen"
	_swing.stages = [fallen]
	for child_name: String in ["Fallen", "Rise1", "Rise2", "Rise3"]:
		var child := Node2D.new()
		child.name = child_name
		_swing.add_child(child)
	var raised := SWAY.instantiate() as SwingSway
	raised.name = "Raised"
	# As the present garden's: one swing, then still.
	raised.decay = 1.2
	_swing.add_child(raised)
	_root.add_child(_swing)
	var bloom := MemoryBloom.new()
	bloom.position = Vector2(100, 200)
	_root.add_child(bloom)
	_beat = SwingRaiseBeat.new()
	_beat.swing = _swing
	_beat.rising = [&"Rise1", &"Rise2", &"Rise3"]
	_beat.raised = &"Raised"
	_beat.raised_sway = raised
	_beat.bloom = bloom
	_beat.up_held = func() -> bool: return _held[0]
	_root.add_child(_beat)
	add_child(_root)
	_beat.finished.connect(func() -> void: _ends.append("finished"))
	_beat.abandoned.connect(func() -> void: _ends.append("abandoned"))

func _run(seconds: float) -> void:
	var left := seconds
	while left > 0.0:
		_beat._process(0.05)
		_swing.get_node("Raised")._process(0.05)
		left -= 0.05

func test_it_holds_ivo_to_up() -> void:
	assert_int(_beat.hold).is_equal(DialogueBeat.Hold.HELD_UP)

func test_holding_raises_the_swing_and_the_colour_step_by_step() -> void:
	_beat.start()
	_held[0] = true
	_run(0.55)
	assert_str(String(_swing.shown().name)).is_equal("Rise1")
	var source := _beat.bloom.source()
	assert_bool(source.visible).is_true()
	_run(0.5)
	assert_str(String(_swing.shown().name)).is_equal("Rise2")
	_run(0.5)
	assert_str(String(_swing.shown().name)).is_equal("Rise3")
	assert_array(Array(_ends)).is_empty()
	_run(0.5)
	assert_str(String(_swing.shown().name)).is_equal("Raised")
	assert_array(Array(_ends)).is_equal(["finished"])
	assert_bool(_beat.raised_sway.is_swinging()).is_true()
	_run(8.0)
	assert_bool(_beat.raised_sway.is_swinging()).is_false()

func test_letting_go_lets_it_fall_back() -> void:
	_beat.start()
	_held[0] = true
	_run(1.05)
	assert_str(String(_swing.shown().name)).is_equal("Rise2")
	_held[0] = false
	_run(0.5)
	assert_str(String(_swing.shown().name)).is_equal("Rise1")
	_run(0.5)
	assert_str(String(_swing.shown().name)).is_equal("Fallen")
	assert_array(Array(_ends)).is_empty()

func test_a_full_recede_left_idle_gives_the_talk_up() -> void:
	_beat.start()
	_held[0] = true
	_run(0.55)
	_held[0] = false
	_run(2.2)
	assert_array(Array(_ends)).is_equal(["abandoned"])
	assert_str(String(_swing.shown().name)).is_equal("Fallen")
	assert_bool(_beat.bloom.is_blooming()).is_false()
	assert_bool(_beat.is_running()).is_false()

func test_a_push_swings_it_out_east_and_it_stops_once_let_go() -> void:
	var sway := auto_free(SWAY.instantiate()) as SwingSway
	add_child(sway)
	sway.push()
	for i: int in 6:
		sway._process(0.05)
	# The seat hangs below the pivot: east is a negative (counter-clockwise) turn.
	assert_float(sway.rotation).is_less(0.0)
	var pushed := sway.amplitude()
	sway.push()
	assert_float(sway.amplitude()).is_greater(pushed)
	sway.push()
	sway.push()
	assert_float(sway.amplitude()).is_less_equal(sway.max_degrees)
	sway.let_go()
	for i: int in 200:
		sway._process(0.05)
	assert_bool(sway.is_swinging()).is_false()
	assert_float(sway.rotation).is_equal(0.0)

func test_a_pushed_swing_keeps_swinging_while_she_speaks() -> void:
	var sway := auto_free(SWAY.instantiate()) as SwingSway
	add_child(sway)
	sway.push()
	for i: int in 80:
		sway._process(0.05)
	assert_bool(sway.is_swinging()).is_true()
