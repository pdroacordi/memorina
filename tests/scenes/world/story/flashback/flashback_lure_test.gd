class_name FlashbackLureTest extends GdUnitTestSuite

## The lure calls while flashback 1 is due and its crossing unseen, again after its gap, and goes quiet (no call, no duck)
## once the crossing is seen, or once its room goes idle.

const F := preload("res://tests/resources/dialogue/dialogue_fixture.gd")

var _lure: FlashbackLure


func before_test() -> void:
	SaveSystem.begin("", true)
	SaveSystem.set_item_owned(Enums.PlayerItem.MEMORINA, true)
	_lure = auto_free(FlashbackLure.new()) as FlashbackLure
	_lure.process_mode = Node.PROCESS_MODE_PAUSABLE
	var due := F.fact(SaveFact.Kind.FLASHBACK_DUE, &"", 1)
	_lure.when = [due]
	_lure.unless = [F.fact(SaveFact.Kind.SCENE_SEEN, &"lure_crossing")]
	_lure.stream = _silent(0.1)
	_lure.gap = 0.2
	add_child(_lure)

func after_test() -> void:
	SaveSystem.begin("", true)

func _silent(seconds: float) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 8000
	var data := PackedByteArray()
	data.resize(int(8000 * seconds))
	wav.data = data
	return wav

func _voice() -> AudioStreamPlayer2D:
	return _lure.get_child(0) as AudioStreamPlayer2D

func test_it_calls_while_the_flashback_is_due() -> void:
	assert_bool(_lure.is_active()).is_true()
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_bool(_voice().playing).is_true()
	assert_str(_voice().bus).is_equal(String(AudioBuses.SFX))

func test_it_goes_quiet_once_the_crossing_is_seen() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	SaveSystem.mark_scene_seen(&"lure_crossing")
	assert_bool(_lure.is_active()).is_false()
	assert_bool(_voice().playing).is_false()
	assert_bool(_lure.is_ducking()).is_false()
	await await_millis(400)
	assert_bool(_voice().playing).is_false()

func test_it_is_quiet_without_the_memorina() -> void:
	SaveSystem.set_item_owned(Enums.PlayerItem.MEMORINA, false)
	assert_bool(_lure.is_active()).is_false()

## A door trip idles the room, never frees it: the lure closes its duck, muffle and voice at once
## (bugs/the-mill-lure-keeps-the-lullaby-playing-in-the-mill-house).
func test_an_idled_room_closes_what_the_lure_opened() -> void:
	var zone := Area2D.new()
	zone.collision_layer = 0
	zone.collision_mask = 256
	_lure.add_child(zone)
	_lure.zone = zone
	_lure.voice = _cue()
	# As if Ivo stood in the zone this frame; no physics step runs before the room idles.
	_lure._ask_voice(true)
	_lure._duck(true, -20.0)
	assert_bool(_lure.is_singing()).is_true()
	assert_bool(_lure.is_ducking()).is_true()
	_lure.process_mode = Node.PROCESS_MODE_DISABLED
	assert_bool(_lure.is_singing()).is_false()
	assert_bool(_lure.is_ducking()).is_false()
	assert_bool(_voice().playing).is_false()
	await await_millis(700)
	assert_float(Music.muffled()).is_equal(0.0)

func _cue() -> MusicCue:
	var cue := MusicCue.new()
	cue.id = &"lure_voice"
	cue.stream = _silent(2.0)
	cue.stems = [&"bed"]
	cue.fade_in = 0.0
	cue.fade_out = 0.0
	return cue
