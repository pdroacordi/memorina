class_name IvoSoundsTest extends GdUnitTestSuite

## Ivo's sounds: a killing hit plays death, not hurt; a voice keeps sounding, and a new one starts, while Game holds
## him DISABLED for a fade; a tree pause starts none; a soft landing is levelled by speed; the floor and shallow
## water name the surface; every door look has its open and close, and every take its cue (systems/sound-effects).

const IVO := preload("res://scenes/characters/ivo/ivo.tscn")
const SOUNDS := preload("res://resources/audio/sfx/ivo/ivo_sounds.tres")
## Top of the test floor.
const FLOOR_Y := 30.0

var _holder: Node2D
var _ivo: Player
var _sounds: IvoSounds
var _played: Array[SoundCue] = []
var _landings: int = 0


func before_test() -> void:
	_played.clear()
	_landings = 0
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
	_ivo = IVO.instantiate() as Player
	_ivo.position = Vector2(0, -60)
	_ivo.landed.connect(func(_at: Vector2, _speed: float) -> void: _landings += 1)
	_holder.add_child(_ivo)
	_sounds = _ivo.get_node("IvoSounds") as IvoSounds
	_sounds.emitter().cue_played.connect(func(cue: SoundCue) -> void: _played.append(cue))

func _land() -> void:
	for i: int in 120:
		await get_tree().physics_frame
		if _ivo.is_on_floor() and _ivo.is_still():
			return
	fail("Ivo never landed on the test floor")

# Wall-clock seconds, the mixer's clock (gotchas/an-audio-player-that-cannot-process-still-starts-a-voice).
func _real(seconds: float) -> void:
	var end := Time.get_ticks_usec() + int(seconds * 1_000_000.0)
	while Time.get_ticks_usec() < end:
		await get_tree().process_frame

func test_it_is_explicitly_pausable() -> void:
	assert_int(_sounds.process_mode).is_equal(Node.PROCESS_MODE_PAUSABLE)

func test_a_killing_hit_plays_death_not_hurt() -> void:
	await _land()
	_ivo.hurtbox.hit_received.emit(_ivo.health.max_hp * 10, Vector2.ZERO, null)
	assert_bool(_ivo.is_dead()).is_true()
	assert_array(_played).contains([SOUNDS.death])
	assert_array(_played).not_contains([SOUNDS.hurt])

func test_a_wound_plays_hurt() -> void:
	await _land()
	_ivo.hurtbox.hit_received.emit(1, Vector2.ZERO, null)
	assert_bool(_ivo.is_dead()).is_false()
	assert_array(_played).contains([SOUNDS.hurt])
	assert_array(_played).not_contains([SOUNDS.death])

## A door fade: Game sets Ivo DISABLED; the creak he started keeps sounding and a new voice still starts.
func test_a_voice_survives_ivo_disabled() -> void:
	await _land()
	_sounds.on_jumped(_ivo.global_position)
	var player := _sounds.emitter().player_of(SOUNDS.jump) as AudioStreamPlayer
	_ivo.process_mode = Node.PROCESS_MODE_DISABLED
	_sounds.on_sat_down(null)
	await _real(0.2)
	assert_bool(player.playing).is_true()
	assert_float(player.get_playback_position()).is_greater(0.1)
	assert_array(_played).contains([SOUNDS.rest])
	_ivo.process_mode = Node.PROCESS_MODE_INHERIT

## A freeze or a hold pauses the tree: nothing new starts.
func test_a_tree_pause_blocks_a_start() -> void:
	await _land()
	var freeze := WorldFreeze.new()
	add_child(freeze)
	freeze.freeze()
	_sounds.on_jumped(_ivo.global_position)
	freeze.thaw()
	remove_child(freeze)
	freeze.free()
	assert_array(_played).not_contains([SOUNDS.jump])

func test_a_slow_landing_is_silent() -> void:
	await _land()
	_played.clear()
	_sounds.on_landed(_ivo.global_position, SOUNDS.soft_land_min_speed - 1.0)
	assert_array(_played).is_empty()

func test_a_soft_landing_plays_the_floors_land_levelled_by_speed() -> void:
	await _land()
	var land := SOUNDS.surface(Enums.Surface.STONE).land
	_sounds.on_landed(_ivo.global_position, 500.0)
	assert_array(_played).contains([land])
	var expected := land.volume_db + ImpactLevel.db(500.0, SOUNDS.soft_land_min_speed, SOUNDS.soft_land_full_speed)
	assert_float((_sounds.emitter().player_of(land) as AudioStreamPlayer).volume_db).is_equal_approx(expected, 0.001)

func test_falling_onto_the_floor_is_one_landing() -> void:
	await _land()
	assert_int(_landings).is_equal(1)

## A plain body under the feet with no step_surface sounds as STONE.
func test_a_plain_floor_body_is_stone() -> void:
	await _land()
	assert_int(_ivo.floor_surface()).is_equal(Enums.Surface.STONE)

func test_shallow_water_wins_over_the_floor_until_he_leaves_it() -> void:
	await _land()
	_ivo.enter_wading()
	assert_int(_ivo.floor_surface()).is_equal(Enums.Surface.SHALLOW_WATER)
	_ivo.exit_wading()
	assert_int(_ivo.floor_surface()).is_equal(Enums.Surface.STONE)

func test_every_surface_has_its_sounds() -> void:
	for surface: int in Enums.Surface.values():
		if surface == Enums.Surface.NONE:
			continue
		var sounds := SOUNDS.surface(surface)
		assert_object(sounds).override_failure_message("%s has no sounds" % Enums.Surface.keys()[surface]).is_not_null()
		assert_object(sounds.step).is_not_null()
		assert_object(sounds.land).is_not_null()

## The run clip's contacts reach the floor's step cue through the real AnimationTree.
func test_a_run_sounds_steps_on_its_floor() -> void:
	await _land()
	var controller := ScriptedController.new()
	_ivo.add_child(controller)
	_ivo.drive(controller)
	controller.walk_to(_ivo.global_position.x + 600.0, 1.0)
	for i: int in 60:
		await get_tree().physics_frame
	var step := SOUNDS.surface(Enums.Surface.STONE).step
	assert_str(String(_ivo.animation_state())).is_equal(String(PlayerAnimationResolver.RUN))
	# One second of a 0.67 s loop with two contacts, plus the start: 2 to 4 steps, never one per frame.
	assert_int(_played.count(step)).is_between(2, 4)

## A new Door look must be given a sound or an explicit silence (null) on both the way in and the way out.
func test_every_door_look_has_an_open_and_a_close_entry() -> void:
	for table: Dictionary in [SOUNDS.door_open, SOUNDS.door_close]:
		assert_array(table.keys()).contains_exactly_in_any_order(Door.LOOKS.keys())
		for look: String in table:
			assert_bool(table[look] == null).override_failure_message("%s is half silent" % look) \
					.is_equal(SOUNDS.door_open[look] == null)

func test_a_door_plays_its_looks_open_and_close() -> void:
	await _land()
	_played.clear()
	var door := auto_free(Door.new()) as Door
	door.look = "door"
	_ivo.door_entered.emit(door)
	_ivo.arrived_through.emit(door)
	assert_array(_played).contains_exactly([SOUNDS.door_open["door"], SOUNDS.door_close["door"]])

func test_a_silent_look_plays_nothing() -> void:
	await _land()
	_played.clear()
	var door := auto_free(Door.new()) as Door
	door.look = "passage"
	_ivo.door_entered.emit(door)
	_ivo.arrived_through.emit(door)
	assert_array(_played).is_empty()

func test_a_knock_plays_the_knock() -> void:
	await _land()
	_played.clear()
	_ivo.door_knocked.emit(auto_free(Door.new()) as Door)
	assert_array(_played).contains_exactly([SOUNDS.door_knock])

func test_everything_taken_has_its_cue() -> void:
	await _land()
	for what: int in Player.Taken.values():
		var cue := SOUNDS.taken.get(what) as SoundCue
		assert_object(cue).override_failure_message("%s has no cue" % Player.Taken.keys()[what]).is_not_null()
		assert_bool(cue.world).is_true()
		_ivo.took.emit(what)
		assert_array(_played).contains([cue])
