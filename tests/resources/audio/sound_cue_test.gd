class_name SoundCueTest extends GdUnitTestSuite

## A world cue goes to SfxWorld, every other cue to Sfx; a cue's length is its longest variant at its pitch; the
## length rules of architecture/sound-effects-system hold for every cue in resources/audio/sfx.

const SFX_DIR := "res://resources/audio/sfx"
const IVO := preload("res://scenes/characters/ivo/ivo.tscn")
const SOUNDS := preload("res://resources/audio/sfx/ivo/ivo_sounds.tres")
## Seconds; a world one-shot is at most this long.
const WORLD_ONE_SHOT := 1.0
## Seconds of slack for a file cut to exactly the limit.
const SLACK := 0.005


func test_the_bus_follows_world() -> void:
	var cue := SoundCue.new()
	assert_str(String(cue.bus())).is_equal(String(AudioBuses.SFX))
	cue.world = true
	assert_str(String(cue.bus())).is_equal(String(AudioBuses.SFX_WORLD))

func test_length_is_the_longest_variant_at_its_pitch() -> void:
	var randomizer := AudioStreamRandomizer.new()
	randomizer.add_stream(-1, _tone(0.2))
	randomizer.add_stream(-1, _tone(0.5))
	var cue := SoundCue.new()
	cue.stream = randomizer
	assert_float(cue.length()).is_equal_approx(0.5, 0.001)
	cue.pitch_scale = 0.5
	assert_float(cue.length()).is_equal_approx(1.0, 0.001)
	cue.stream = _tone(0.3)
	assert_float(cue.length()).is_equal_approx(0.6, 0.001)
	cue.stream = null
	assert_float(cue.length()).is_equal(0.0)

func test_a_world_cue_is_a_one_shot_of_at_most_a_second() -> void:
	var cues := _cues(SFX_DIR)
	assert_bool(cues.is_empty()).is_false()
	for path: String in cues:
		var cue := load(path) as SoundCue
		if cue.world:
			assert_float(cue.length()).override_failure_message("%s lasts %.3f s" % [path, cue.length()]) \
					.is_less_equal(WORLD_ONE_SHOT + SLACK)

## The lesson's freeze pauses Ivo's emitter, so the songbook ends inside the lead-in.
func test_the_songbook_ends_inside_the_lesson_lead_in() -> void:
	var ivo := IVO.instantiate() as Player
	var lead_in := ivo.lesson_lead_in
	ivo.free()
	var songbook := SOUNDS.taken[Player.Taken.SONGBOOK]
	assert_object(songbook).is_not_null()
	assert_float(songbook.length()).is_less_equal(lead_in)

func _cues(dir: String) -> PackedStringArray:
	var found := PackedStringArray()
	for sub: String in DirAccess.get_directories_at(dir):
		found.append_array(_cues(dir.path_join(sub)))
	for file: String in DirAccess.get_files_at(dir):
		if file.ends_with(".tres") and load(dir.path_join(file)) is SoundCue:
			found.append(dir.path_join(file))
	return found

func _tone(seconds: float) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 8000
	var data := PackedByteArray()
	data.resize(int(seconds * 8000.0))
	wav.data = data
	return wav
