class_name GuardianAITimelineTest extends GdUnitTestSuite

## Golden timeline of every guardian's AI against a scripted Ivo: each telegraph, swing start and finish, by frame.
## Written against the AI before GRD-12 and kept unchanged by it (architecture/grd-12-guardian-fight-engine, step 0).

const GOLDEN := "res://tests/fixtures/guardians/guardian_ai_timeline.json"
const STATS: Array[String] = [
	"res://resources/characters/guardians/autumn_guardian/autumn_guardian_stats.tres",
	"res://resources/characters/guardians/bloom_guardian/bloom_guardian_stats.tres",
	"res://resources/characters/guardians/frost_guardian/frost_guardian_stats.tres",
	"res://resources/characters/guardians/summer_guardian/summer_guardian_stats.tres",
	"res://resources/characters/guardians/mentor/mentor_stats.tres",
]
const STEP := 1.0 / 60.0
const FRAMES := 1200
const SEED := 1234
## Walk speed of the simulated body, px/s.
const WALK_SPEED := 70.0
## The simulated arena's walls, px.
const ARENA_LOW := 100.0
const ARENA_HIGH := 1100.0
## Golem-sized body beside Ivo's, px.
const BODY_WIDTH := 48.0
const IVO_WIDTH := 22.0

var _body: Node2D
var _player: Node2D
var _ai: GuardianAI
var _frame: int = 0


func _make_ai() -> void:
	_body = auto_free(Node2D.new()) as Node2D
	var sight := EnemySight.new()
	sight.name = "EnemySight"
	var ray := RayCast2D.new()
	ray.name = "RayCast2D"
	sight.add_child(ray)
	_body.add_child(sight)
	_ai = GuardianAI.new()
	_body.add_child(_ai)
	add_child(_body)
	_player = auto_free(Node2D.new()) as Node2D
	add_child(_player)
	sight.player = _player

func test_every_guardian_keeps_its_golden_timeline() -> void:
	var golden: Variant = JSON.parse_string(FileAccess.get_file_as_string(GOLDEN))
	assert_object(golden).override_failure_message("no golden at %s" % GOLDEN).is_not_null()
	for path: String in STATS:
		var events := _timeline(load(path) as GuardianStats)
		var expected: Array = (golden as Dictionary).get(path.get_file(), [])
		assert_array(events).override_failure_message("%s diverged:\n%s" % [path.get_file(), JSON.stringify(events)]) \
				.is_equal(expected)

## Runs the AI for FRAMES against the scripted Ivo and returns "<kind><attack index>@<frame>" per event.
func _timeline(stats: GuardianStats) -> Array[String]:
	_make_ai()
	var attacks := stats.attacks
	_ai.attacks = attacks
	_ai.recall_after_attacks = stats.recall_after_attacks
	_ai.recent_strings = stats.recent_strings
	_ai.far_walks_in = stats.far_walks_in
	_ai.comfort_distance = stats.comfort_distance
	_ai.give_ground_distance = stats.give_ground_distance
	_ai.pace_time = stats.pace_time
	_ai.pace_speed = stats.pace_speed
	_ai.step_out_speed = stats.step_out_speed
	_ai.overhead_band = GuardianAI.overhead_band_for(BODY_WIDTH, IVO_WIDTH)
	_ai.active = true
	var events: Array[String] = []
	_frame = 0
	_ai.attack_telegraphed.connect(func(attack: GuardianAttack) -> void: events.append("T%d@%d" % [attacks.find(attack), _frame]))
	_ai.attack_started.connect(func(attack: GuardianAttack) -> void: events.append("S%d@%d" % [attacks.find(attack), _frame]))
	_ai.attack_finished.connect(func(attack: GuardianAttack) -> void: events.append("F%d@%d" % [attacks.find(attack), _frame]))
	_body.global_position = Vector2(600.0, 0.0)
	var facing := 1.0
	seed(SEED)
	while _frame < FRAMES:
		var t := _frame * STEP
		_player.global_position = _ivo_at(t, _body.global_position.x)
		match _frame:
			300, 570:
				_ai.provoke()
			420:
				_ai.request_recall()
			600:
				_ai.cooldown_scale = 0.8
			960:
				_ai.cancel_attack()
				_ai.active = false
			1020:
				_ai.active = true
		_ai.tick(STEP)
		var intent := _ai.facing_intent()
		if not is_zero_approx(intent):
			facing = signf(intent)
		var dx := _ai.direction * WALK_SPEED * STEP
		var attack := _ai.current_attack
		if attack != null and _ai.is_swinging() and attack.lunge_speed > 0.0 and _ai.swing_elapsed() >= attack.lunge_delay:
			dx = facing * attack.lunge_speed * STEP
		_body.position.x = clampf(_body.position.x + dx, ARENA_LOW, ARENA_HIGH)
		_frame += 1
	return events

## Ivo walks to and fro across the arena, jumps every 3 s, and pogoes on the guardian's head from 12 s to 15 s.
func _ivo_at(t: float, body_x: float) -> Vector2:
	if t >= 12.0 and t < 15.0:
		return Vector2(body_x + 4.0, -190.0 - 70.0 * absf(sin(t * PI / 0.5)))
	var x := 520.0 + 220.0 * sin(t * 0.7) + 70.0 * sin(t * 2.3)
	var hop := fmod(t, 3.0)
	var y := -144.0 * sin(PI * hop / 0.6) if hop < 0.6 else 0.0
	return Vector2(x, y)
