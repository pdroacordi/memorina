class_name IvoMusicYieldTest extends GdUnitTestSuite

## SND-04: the region's music sinks while Ivo has the Memorina out or the guitar in his hands, and comes back when he
## stops; a fight's music never yields.

const IVO := preload("res://scenes/characters/ivo/ivo.tscn")

var _holder: Node2D
var _ivo: Player


func before_test() -> void:
	SaveSystem.begin("", true)
	SaveSystem.set_item_owned(Enums.PlayerItem.MEMORINA, true)
	_holder = auto_free(Node2D.new()) as Node2D
	add_child(_holder)
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 2
	floor_body.position = Vector2(0, 40.0)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(4000, 20)
	shape.shape = rect
	floor_body.add_child(shape)
	_holder.add_child(floor_body)
	_ivo = IVO.instantiate() as Player
	_ivo.position = Vector2(0, -60)
	_holder.add_child(_ivo)

func after_test() -> void:
	var left := Music.playing()
	while left != null:
		Music.release(left, 0.0)
		left = Music.playing()
	Music.unduck(IvoMusicYield.DUCK)
	SaveSystem.begin("", true)

func _cue() -> MusicCue:
	var wav := AudioStreamWAV.new()
	wav.mix_rate = 8000
	var data := PackedByteArray()
	data.resize(16000)
	wav.data = data
	var cue := MusicCue.new()
	cue.id = &"test"
	cue.stream = wav
	cue.fade_in = 0.0
	cue.fade_out = 0.0
	return cue

func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame

func _duck() -> float:
	return Music._mix.duck_target()

func _draw() -> void:
	(_ivo.get_node("PlayerInput") as PlayerInput).draw_memorina_pressed.emit()

func test_only_a_region_theme_yields() -> void:
	var holder: Node = auto_free(Node.new())
	assert_bool(IvoMusicYield.yields(null)).is_false()
	assert_bool(IvoMusicYield.yields(MusicRequest.new(_cue(), MusicRequest.Layer.REGION, holder))).is_true()
	for layer: MusicRequest.Layer in [MusicRequest.Layer.FIGHT, MusicRequest.Layer.SCENE, MusicRequest.Layer.MENU]:
		assert_bool(IvoMusicYield.yields(MusicRequest.new(_cue(), layer, holder))).is_false()

func test_the_memorina_drawn_sinks_the_region_music_and_sheathed_brings_it_back() -> void:
	Music.request(_cue(), MusicRequest.Layer.REGION, _holder)
	await _frames(30)
	assert_float(_duck()).is_equal(0.0)
	_draw()
	await _frames(3)
	assert_bool(_ivo.is_memorina_drawn()).is_true()
	assert_float(_duck()).is_equal(IvoMusicYield.YIELD_DB)
	_draw()
	await _frames(3)
	assert_bool(_ivo.is_memorina_drawn()).is_false()
	assert_float(_duck()).is_equal(0.0)

func test_the_guitar_sinks_the_region_music_until_the_talk_ends() -> void:
	Music.request(_cue(), MusicRequest.Layer.REGION, _holder)
	await _frames(30)
	_ivo.pause_talk(DialogueBeat.Hold.NOTES, DialogueBeat.Pose.GUITAR)
	await _frames(3)
	assert_float(_duck()).is_equal(IvoMusicYield.YIELD_DB)
	_ivo.end_talk()
	await _frames(3)
	assert_float(_duck()).is_equal(0.0)

func test_a_fight_never_yields() -> void:
	Music.request(_cue(), MusicRequest.Layer.FIGHT, _holder)
	await _frames(30)
	_draw()
	await _frames(3)
	assert_bool(_ivo.is_memorina_drawn()).is_true()
	assert_float(_duck()).is_equal(0.0)
