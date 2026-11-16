class_name SoundCueTest extends GdUnitTestSuite

## A world cue goes to SfxWorld, every other cue to Sfx.

func test_the_bus_follows_world() -> void:
	var cue := SoundCue.new()
	assert_str(String(cue.bus())).is_equal(String(AudioBuses.SFX))
	cue.world = true
	assert_str(String(cue.bus())).is_equal(String(AudioBuses.SFX_WORLD))
