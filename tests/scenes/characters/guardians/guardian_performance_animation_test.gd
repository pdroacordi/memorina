class_name GuardianPerformanceAnimationTest extends GdUnitTestSuite

## The guardian's performance clips, each at its moment: lucid_enter as the window opens, play_song while the call
## sings, relapse after a failure and after a good answer, perform through the lesson with the tree ALWAYS only then,
## and perform_end settling on restored (systems/guardians, "Performance clips"; systems/animation).

const IVO := preload("res://scenes/characters/ivo/ivo.tscn")
const BLOOM := preload("res://scenes/characters/guardians/bloom_guardian/bloom_guardian.tscn")
const FROST := preload("res://scenes/characters/guardians/frost_guardian/frost_guardian.tscn")
const SUMMER := preload("res://scenes/characters/guardians/summer_guardian/summer_guardian.tscn")
const AUTUMN := preload("res://scenes/characters/guardians/autumn_guardian/autumn_guardian.tscn")

const FLOOR_Y := 30.0
## Physics frames that bound each wait.
const WAIT_FRAMES := 400

var _holder: Node2D
var _guardian: Guardian
var _ivo: Player
var _driver: AnimationDriver
## Distinct clips in the order the driver played them.
var _seen: Array[StringName] = []


func before_test() -> void:
	SaveSystem.begin("", true)
	SaveSystem.set_item_owned(Enums.PlayerItem.MEMORINA, true)
	_seen.clear()
	_holder = auto_free(Node2D.new()) as Node2D
	add_child(_holder)
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 2
	floor_body.position = Vector2(0, FLOOR_Y + 10.0)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(4000, 20)
	shape.shape = rect
	floor_body.add_child(shape)
	_holder.add_child(floor_body)

func after_test() -> void:
	SaveSystem.begin("", true)

func test_every_guardian_fits_its_one_shots_in_their_moments() -> void:
	for scene: PackedScene in [BLOOM, FROST, SUMMER, AUTUMN]:
		var guardian := scene.instantiate() as Guardian
		guardian.position = Vector2(0, FLOOR_Y)
		_holder.add_child(guardian)
		var driver := guardian.get_node(^"AnimationDriver") as AnimationDriver
		var before_crouch := guardian.lucidity_delay - driver.clip_length(GuardianAnimationResolver.LEAP_CROUCH)
		assert_float(driver.clip_length(GuardianAnimationResolver.LUCID_ENTER)).override_failure_message(guardian.name).is_less_equal(before_crouch)
		var shortest := guardian.stats.relapse_time * GuardianFight.FAILED_RELAPSE_SCALE
		assert_float(driver.clip_length(GuardianAnimationResolver.RELAPSE)).override_failure_message(guardian.name).is_less_equal(shortest)
		guardian.queue_free()

func test_the_bloom_plays_each_clip_through_a_fight_and_its_lesson() -> void:
	await _enter(BLOOM)
	var tree := _guardian.get_node(^"AnimationTree") as AnimationTree
	var cycles := _guardian.stats.cycles_to_restore
	# A failed answer, then every good one; the last restores.
	var answers: Array[bool] = [false]
	for i: int in cycles:
		answers.append(true)
	for answer: bool in answers:
		_seen.clear()
		await _open_window()
		assert_array(_seen).override_failure_message("window: %s" % [_seen]).is_equal([GuardianAnimationResolver.LUCID_ENTER, GuardianAnimationResolver.LUCID,
				GuardianAnimationResolver.LEAP_CROUCH, GuardianAnimationResolver.LEAP_RISE, GuardianAnimationResolver.LEAP_FALL, GuardianAnimationResolver.LEAP_LAND, GuardianAnimationResolver.LUCID])
		await _until(func() -> bool: return _guardian.is_sounding())
		await _frames(2)
		assert_str(_driver.current).is_equal(GuardianAnimationResolver.PLAY_SONG)
		assert_int(tree.process_mode).is_equal(Node.PROCESS_MODE_INHERIT)
		_seen.clear()
		if not answer:
			_guardian.call(&"_on_player_sequence_failed")
		else:
			_guardian.call(&"_on_call_answered", _guardian.stats.song)
		if _guardian.phase() == GuardianFight.Phase.RESTORED:
			break
		await _until(func() -> bool: return _guardian.phase() == GuardianFight.Phase.PRESSURE)
		assert_array(_seen.slice(0, 2)).override_failure_message("after %s: %s" % [answer, _seen]).is_equal([GuardianAnimationResolver.RELAPSE, GuardianAnimationResolver.IDLE])
	assert_int(_guardian.phase()).is_equal(GuardianFight.Phase.RESTORED)
	# The lesson's lead-in: perform, chosen before the freeze.
	await _frames(2)
	assert_bool(_guardian.is_teaching()).is_true()
	assert_str(_driver.current).is_equal(GuardianAnimationResolver.PERFORM)
	assert_int(tree.process_mode).is_equal(Node.PROCESS_MODE_INHERIT)
	var started := [false]
	_ivo.performance_started.connect(func() -> void: started[0] = true)
	await _until(func() -> bool: return started[0])
	assert_int(tree.process_mode).override_failure_message("the tree must run through the lesson's freeze").is_equal(Node.PROCESS_MODE_ALWAYS)
	assert_str(_driver.current).is_equal(GuardianAnimationResolver.PERFORM)
	# The lesson ends (here cut short): the tree goes back to the pause, perform_end plays, then restored.
	_seen.clear()
	# The stage (the camera's pair) holds until perform_end has played (bugs/perform-end-plays-after-the-camera-has-left-the-guardian).
	var unstaged_on: Array[StringName] = []
	_ivo.call_unstaged.connect(func() -> void:
		unstaged_on.append(&"finished" if _driver.finished(GuardianAnimationResolver.PERFORM_END) else _driver.current))
	_ivo.call(&"_on_memorina_sheathed")
	assert_int(tree.process_mode).is_equal(Node.PROCESS_MODE_INHERIT)
	assert_array(unstaged_on).is_empty()
	await _until(func() -> bool: return _driver.current == GuardianAnimationResolver.RESTORED)
	assert_array(_seen).is_equal([GuardianAnimationResolver.PERFORM_END, GuardianAnimationResolver.RESTORED])
	assert_array(unstaged_on).is_equal([&"finished"])

## Spawns the guardian and Ivo and starts the fight.
func _enter(scene: PackedScene) -> void:
	_guardian = scene.instantiate() as Guardian
	_guardian.position = Vector2(0, FLOOR_Y)
	# Less lead-in so the test does not wait out the bark, still longer than the landing clip.
	_guardian.stats = _guardian.stats.duplicate() as GuardianStats
	_guardian.stats.call_lead_in = 0.6
	_holder.add_child(_guardian)
	_ivo = IVO.instantiate() as Player
	_ivo.position = Vector2(60.0, FLOOR_Y - 30.0)
	_holder.add_child(_ivo)
	_driver = _guardian.get_node(^"AnimationDriver") as AnimationDriver
	await _frames(10)
	_guardian.call(&"_on_player_entered")
	(_guardian.get(&"_fight") as GuardianFight).set_recall_pending(false)

## Hits until the window opens, then waits for the landing's clip to settle.
func _open_window() -> void:
	var fight := _guardian.get(&"_fight") as GuardianFight
	while _guardian.phase() == GuardianFight.Phase.PRESSURE:
		_guardian.call(&"_on_hit_received", 1, Vector2.ZERO, _ivo)
	assert_int(fight.phase()).is_equal(GuardianFight.Phase.LUCIDITY)
	await _until(func() -> bool: return _driver.current == GuardianAnimationResolver.LUCID and _seen.has(GuardianAnimationResolver.LEAP_LAND))

func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame
		_record()

func _until(condition: Callable) -> void:
	for i: int in WAIT_FRAMES:
		if condition.call():
			return
		await get_tree().physics_frame
		_record()
	assert_bool(condition.call()).override_failure_message("timed out; seen %s" % [_seen]).is_true()

func _record() -> void:
	if _seen.is_empty() or _seen.back() != _driver.current:
		_seen.append(_driver.current)
