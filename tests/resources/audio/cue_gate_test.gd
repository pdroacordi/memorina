class_name CueGateTest extends GdUnitTestSuite

## A cue with a cooldown is refused until that many clock seconds pass since its last start; cues gate apart.

var _now: Array[float] = [0.0]
var _gate: CueGate


func before_test() -> void:
	_now[0] = 0.0
	_gate = CueGate.new(func() -> float: return _now[0])

func _cue(cooldown: float) -> SoundCue:
	var cue := SoundCue.new()
	cue.cooldown = cooldown
	return cue

func test_a_cue_without_a_cooldown_always_starts() -> void:
	var cue := _cue(0.0)
	assert_bool(_gate.try_start(cue)).is_true()
	assert_bool(_gate.try_start(cue)).is_true()

func test_a_cue_is_refused_inside_its_cooldown_and_starts_after_it() -> void:
	var cue := _cue(0.1)
	assert_bool(_gate.try_start(cue)).is_true()
	_now[0] = 0.05
	assert_bool(_gate.try_start(cue)).is_false()
	_now[0] = 0.1
	assert_bool(_gate.try_start(cue)).is_true()

func test_a_refused_start_does_not_extend_the_cooldown() -> void:
	var cue := _cue(0.1)
	_gate.try_start(cue)
	_now[0] = 0.09
	_gate.try_start(cue)
	_now[0] = 0.12
	assert_bool(_gate.try_start(cue)).is_true()

func test_two_cues_gate_apart() -> void:
	var first := _cue(1.0)
	var second := _cue(1.0)
	assert_bool(_gate.try_start(first)).is_true()
	assert_bool(_gate.try_start(second)).is_true()
	assert_bool(_gate.try_start(first)).is_false()

func test_the_default_clock_is_real_seconds() -> void:
	var gate := CueGate.new()
	var cue := _cue(60.0)
	assert_bool(gate.try_start(cue)).is_true()
	assert_bool(gate.try_start(cue)).is_false()
	assert_float(CueGate.real_seconds()).is_greater(0.0)
