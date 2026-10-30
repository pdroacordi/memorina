class_name GuardianTalksTest extends GdUnitTestSuite

## A guardian's bark: one per cure step, the retry after a failure, shown as the leap lands and closed at the call's
## first note or when the call ends; nothing is recorded (systems/guardians, "Talks").

const IVO := preload("res://scenes/characters/ivo/ivo.tscn")
const BLOOM := preload("res://scenes/characters/guardians/bloom_guardian/bloom_guardian.tscn")
const FROST := preload("res://scenes/characters/guardians/frost_guardian/frost_guardian.tscn")
const BALLOON := preload("res://scenes/ui/bark_balloon/bark_balloon.tscn")

const FLOOR_Y := 30.0
## Physics frames for the delay, the flight and the landing.
const LEAP_FRAMES := 300

var _holder: Node2D
var _balloon: BarkBalloon


func before_test() -> void:
	SaveSystem.begin("", true)
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
	_balloon = BALLOON.instantiate() as BarkBalloon
	_holder.add_child(_balloon)

func after_test() -> void:
	SaveSystem.begin("", true)

func _guardian(scene: PackedScene) -> Guardian:
	var guardian := scene.instantiate() as Guardian
	guardian.position = Vector2(0, FLOOR_Y)
	_holder.add_child(guardian)
	return guardian

func _said(key: String) -> String:
	return StutterText.strip(tr(key))

## The saved fields, as text, to compare before and after.
func _save_snapshot() -> String:
	var data := SaveSystem.player_data
	var text := ""
	for property: Dictionary in data.get_property_list():
		if int(property.usage) & PROPERTY_USAGE_STORAGE:
			text += "%s=%s\n" % [property.name, var_to_str(data.get(property.name))]
	return text

func test_its_talkable_holds_its_voices_talks() -> void:
	var guardian := _guardian(BLOOM)
	await get_tree().process_frame
	assert_object((guardian.get_node(^"Talkable") as Talkable).talk).is_same(guardian.stats.voice.talks)

func test_a_bark_per_cure_step_and_the_retry_closing_at_the_first_note_or_the_end() -> void:
	var guardian := _guardian(FROST)
	await get_tree().process_frame
	var anchor := guardian.get_node(^"BarkAnchor") as Node2D
	var voice := guardian.stats.voice
	var before := _save_snapshot()
	for cycle: int in voice.lucid_barks.size():
		guardian.lucid_landed.emit(cycle, false)
		assert_bool(_balloon.visible).is_true()
		assert_object(_balloon.speaker()).is_same(anchor)
		assert_str(_balloon.text_label().text).is_equal(_said(voice.lucid_barks[cycle]))
		guardian.call_note_sung.emit(0)
		assert_bool(_balloon.visible).override_failure_message("open after the first note").is_false()
	guardian.lucid_landed.emit(1, true)
	assert_str(_balloon.text_label().text).is_equal(_said(voice.retry_bark))
	guardian.call_ended.emit()
	assert_bool(_balloon.visible).override_failure_message("open after the call ended").is_false()
	assert_str(_save_snapshot()).is_equal(before)

func test_the_fight_says_it_as_the_leap_lands_and_closes_it_at_the_first_note() -> void:
	var guardian := await _land(BLOOM)
	assert_bool(_balloon.visible).override_failure_message("no bark at the landing").is_true()
	assert_str(_balloon.text_label().text).is_equal(_said(guardian.stats.voice.lucid_barks[0]))
	var frames := ceili(guardian.stats.call_lead_in * Engine.physics_ticks_per_second) + 30
	for i: int in frames:
		await get_tree().physics_frame
		if guardian.is_sounding():
			break
		assert_bool(_balloon.visible).override_failure_message("closed before the call sang").is_true()
	assert_bool(guardian.is_sounding()).is_true()
	await get_tree().process_frame
	assert_bool(_balloon.visible).override_failure_message("open while the call sings").is_false()
	guardian.call(&"_abandon_call")
	await get_tree().physics_frame

func test_an_abandoned_call_closes_it() -> void:
	var guardian := await _land(FROST)
	assert_bool(_balloon.visible).is_true()
	guardian.call(&"_abandon_call")
	assert_bool(_balloon.visible).is_false()
	await get_tree().physics_frame

## Opens a lucid window and waits for the leap to land.
func _land(scene: PackedScene) -> Guardian:
	var guardian := _guardian(scene)
	var ivo := IVO.instantiate() as Player
	ivo.position = Vector2(60.0, FLOOR_Y - 30.0)
	_holder.add_child(ivo)
	for i: int in 10:
		await get_tree().physics_frame
	guardian.call(&"_on_player_entered")
	(guardian.get(&"_fight") as GuardianFight).set_recall_pending(false)
	var landed := [false]
	guardian.lucid_landed.connect(func(_c: int, _f: bool) -> void: landed[0] = true)
	for i: int in guardian.stats.hits_to_open:
		guardian.call(&"_on_hit_received", 1, Vector2.ZERO, ivo)
	for i: int in LEAP_FRAMES:
		await get_tree().physics_frame
		if landed[0]:
			break
	assert_bool(landed[0]).override_failure_message("%s never landed" % guardian.name).is_true()
	return guardian
