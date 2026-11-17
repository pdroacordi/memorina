class_name SongPerformanceTest extends GdUnitTestSuite

## A performance plays at its authored volume plus the song's trim, and stop() restores the authored volume.

var _performance: SongPerformance
var _player: AudioStreamPlayer


func before_test() -> void:
	_performance = auto_free(SongPerformance.new()) as SongPerformance
	_player = AudioStreamPlayer.new()
	_player.name = "AudioStreamPlayer"
	_player.volume_db = -3.0
	_performance.add_child(_player)
	add_child(_performance)

func test_a_trim_sits_over_the_authored_volume_until_stop() -> void:
	_performance.play(_tone(), PackedFloat32Array(), 0.0, 0.0, -6.0)
	assert_float(_player.volume_db).is_equal(-9.0)
	_performance.stop()
	assert_float(_player.volume_db).is_equal(-3.0)
	_performance.play(_tone(), PackedFloat32Array())
	assert_float(_player.volume_db).is_equal(-3.0)
	_performance.stop()

func _tone() -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 8000
	var data := PackedByteArray()
	data.resize(8000)
	wav.data = data
	return wav
