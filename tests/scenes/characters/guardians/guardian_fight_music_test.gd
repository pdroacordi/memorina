class_name GuardianFightMusicTest extends GdUnitTestSuite

## Every guardian fights to its own cue (stems `bed`, `lead`) through a GuardianMusic child, and calls in its own flute.

const GUARDIANS: Array[String] = ["frost", "bloom", "summer", "autumn"]


func test_every_guardian_has_a_fight_cue_with_bed_and_lead() -> void:
	for g: String in GUARDIANS:
		var stats := load("res://resources/characters/guardians/%s_guardian/%s_guardian_stats.tres" % [g, g]) as GuardianStats
		assert_object(stats.music).is_not_null()
		assert_array(Array(stats.music.validate())).is_empty()
		assert_array(stats.music.stems).is_equal([&"bed", &"lead"])

func test_every_guardian_scene_has_a_guardian_music_child() -> void:
	for g: String in GUARDIANS:
		var scene := load("res://scenes/characters/guardians/%s_guardian/%s_guardian.tscn" % [g, g]) as PackedScene
		var guardian: Node = auto_free(scene.instantiate())
		assert_object(guardian.get_node_or_null(^"GuardianMusic")).is_instanceof(GuardianMusic)

func test_every_guardian_calls_in_its_own_flute_at_written_pitch() -> void:
	for g: String in GUARDIANS:
		var scene := load("res://scenes/characters/guardians/%s_guardian/%s_guardian.tscn" % [g, g]) as PackedScene
		var guardian: Node = auto_free(scene.instantiate())
		var voice := guardian.get_node(^"Call/Voice") as MemorinaVoice
		for stream: AudioStream in voice.note_streams:
			assert_str(stream.resource_path).starts_with("res://assets/audios/sfx/guardian_calls/call_%s_" % g)
		var player := voice.get_node(^"AudioStreamPlayer") as AudioStreamPlayer
		assert_float(player.pitch_scale).is_equal(1.0)
