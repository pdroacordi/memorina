class_name SfxEmitterTest extends GdUnitTestSuite

## An emitter makes one player per cue with the cue's bus and voices, gates cooldowns across emitters,
## stops on an idled owner, keeps a paused voice and starts nothing it cannot process (systems/sound-effects).

const RATE := 22050

var _host: Node2D


func before_test() -> void:
	_host = Node2D.new()
	add_child(_host)

func after_test() -> void:
	_host.free()

func _tone(seconds: float) -> AudioStreamWAV:
	var frames := int(RATE * seconds)
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i: int in frames:
		data.encode_s16(i * 2, int(sin(TAU * 440.0 * i / RATE) * 8000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.data = data
	return wav

# Wall-clock seconds, the mixer's clock: gdUnit's await_millis stops with the tree, and a 1 s
# game timer ended after 0.77 wall s in the runner (gotchas/an-audio-player-that-cannot-process-still-starts-a-voice).
func _real(seconds: float) -> void:
	var end := Time.get_ticks_usec() + int(seconds * 1_000_000.0)
	while Time.get_ticks_usec() < end:
		await get_tree().process_frame

func _cue(voices: int = 1, cooldown: float = 0.0, world: bool = false) -> SoundCue:
	var cue := SoundCue.new()
	cue.stream = _tone(2.0)
	cue.max_voices = voices
	cue.cooldown = cooldown
	cue.world = world
	cue.volume_db = -6.0
	return cue

func _emitter(positional: bool = false) -> SfxEmitter:
	var emitter := SfxEmitter.new()
	emitter.positional = positional
	_host.add_child(emitter)
	return emitter

func test_it_joins_its_group() -> void:
	assert_bool(_emitter().is_in_group(SfxEmitter.GROUP)).is_true()

func test_a_player_is_made_on_first_play_with_the_cues_bus_and_voices() -> void:
	var emitter := _emitter()
	var cue := _cue(3)
	assert_object(emitter.player_of(cue)).is_null()
	assert_bool(emitter.play(cue, -2.0)).is_true()
	var player := emitter.player_of(cue) as AudioStreamPlayer
	assert_object(player).is_not_null()
	assert_str(String(player.bus)).is_equal(String(AudioBuses.SFX))
	assert_int(player.max_polyphony).is_equal(3)
	assert_float(player.volume_db).is_equal(-8.0)
	assert_bool(player.playing).is_true()

func test_a_cue_keeps_its_one_player() -> void:
	var emitter := _emitter()
	var cue := _cue(2)
	emitter.play(cue)
	var player := emitter.player_of(cue)
	emitter.play(cue)
	assert_object(emitter.player_of(cue)).is_same(player)
	assert_int(emitter.get_child_count()).is_equal(1)

func test_a_world_cue_goes_to_sfx_world() -> void:
	var emitter := _emitter()
	var cue := _cue(1, 0.0, true)
	emitter.play(cue)
	assert_str(String((emitter.player_of(cue) as AudioStreamPlayer).bus)).is_equal(String(AudioBuses.SFX_WORLD))

func test_a_positional_emitter_plays_in_2d_with_the_world_distances() -> void:
	var emitter := _emitter(true)
	emitter.global_position = Vector2(100, 50)
	var cue := _cue(2, 0.0, true)
	assert_bool(emitter.play_at(cue, Vector2(400, 300))).is_true()
	var player := emitter.player_of(cue) as AudioStreamPlayer2D
	assert_object(player).is_not_null()
	assert_float(player.max_distance).is_equal(800.0)
	assert_float(player.attenuation).is_equal(1.0)
	assert_float(player.panning_strength).is_equal_approx(0.6, 0.0001)
	assert_int(player.max_polyphony).is_equal(2)
	assert_str(String(player.bus)).is_equal(String(AudioBuses.SFX_WORLD))
	assert_vector(player.global_position).is_equal(Vector2(400, 300))
	emitter.play(cue)
	assert_vector(player.global_position).is_equal(Vector2(100, 50))

func test_cue_played_is_emitted_per_voice() -> void:
	var emitter := _emitter()
	var cue := _cue()
	var heard: Array[SoundCue] = []
	emitter.cue_played.connect(func(played: SoundCue) -> void: heard.append(played))
	emitter.play(cue)
	emitter.play_at(cue, Vector2.ZERO)
	assert_array(heard).is_equal([cue, cue])

func test_a_cooldown_is_shared_across_emitters() -> void:
	var first := _emitter()
	var second := _emitter()
	var cue := _cue(1, 5.0)
	assert_bool(first.play(cue)).is_true()
	assert_bool(second.play(cue)).is_false()
	assert_object(second.player_of(cue)).is_null()

func test_nothing_plays_without_a_cue_or_a_stream() -> void:
	var emitter := _emitter()
	assert_bool(emitter.play(null)).is_false()
	assert_bool(emitter.play(SoundCue.new())).is_false()
	assert_int(emitter.get_child_count()).is_equal(0)

func test_the_voice_sounds() -> void:
	var emitter := _emitter()
	var cue := _cue()
	emitter.play(cue)
	await _real(0.3)
	assert_float((emitter.player_of(cue) as AudioStreamPlayer).get_playback_position()).is_greater(0.1)

func test_an_idled_owner_stops_every_voice_and_starts_none() -> void:
	var emitter := _emitter()
	var cue := _cue()
	var other := _cue()
	emitter.play(cue)
	emitter.play(other)
	_host.process_mode = Node.PROCESS_MODE_DISABLED
	assert_bool((emitter.player_of(cue) as AudioStreamPlayer).playing).is_false()
	assert_bool((emitter.player_of(other) as AudioStreamPlayer).playing).is_false()
	assert_bool(emitter.play(cue)).is_false()
	_host.process_mode = Node.PROCESS_MODE_INHERIT
	await _real(0.1)
	assert_bool((emitter.player_of(cue) as AudioStreamPlayer).playing).is_false()

func test_a_positional_emitter_under_an_idled_owner_starts_nothing_late() -> void:
	var emitter := _emitter(true)
	var cue := _cue()
	_host.process_mode = Node.PROCESS_MODE_DISABLED
	assert_bool(emitter.play(cue)).is_false()
	_host.process_mode = Node.PROCESS_MODE_INHERIT
	await _real(0.1)
	assert_object(emitter.player_of(cue)).is_null()

## A freeze or a hold pauses a voice where it is and starts none; the voice resumes with the world.
func test_a_paused_tree_keeps_the_voice_and_starts_none() -> void:
	var freeze := WorldFreeze.new()
	add_child(freeze)
	var emitter := _emitter()
	var cue := _cue()
	var late := _cue()
	emitter.play(cue)
	await _real(0.2)
	var player := emitter.player_of(cue) as AudioStreamPlayer
	freeze.freeze()
	assert_bool(emitter.play(late)).is_false()
	await _real(0.05)
	var held := player.get_playback_position()
	await _real(0.3)
	assert_bool(player.stream_paused).is_true()
	assert_float(player.get_playback_position()).is_equal_approx(held, 0.03)
	freeze.thaw()
	remove_child(freeze)
	freeze.free()
	await _real(0.3)
	assert_bool(player.playing).is_true()
	assert_float(player.get_playback_position()).is_greater(held + 0.15)

## IvoSounds' case: an explicit PAUSABLE emitter under a DISABLED owner still plays.
func test_an_explicit_pausable_emitter_plays_under_a_disabled_owner() -> void:
	var emitter := _emitter()
	emitter.process_mode = Node.PROCESS_MODE_PAUSABLE
	_host.process_mode = Node.PROCESS_MODE_DISABLED
	var cue := _cue()
	assert_bool(emitter.play(cue)).is_true()
	await _real(0.3)
	assert_float((emitter.player_of(cue) as AudioStreamPlayer).get_playback_position()).is_greater(0.1)

func test_a_player_takes_the_cues_pitch() -> void:
	var emitter := _emitter()
	var cue := _cue()
	cue.pitch_scale = 1.25
	emitter.play(cue)
	assert_float((emitter.player_of(cue) as AudioStreamPlayer).pitch_scale).is_equal(1.25)
