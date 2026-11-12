extends RefCounted
## A fixture flashback for the suites: data built in code, never in the shipped catalog.

const C := preload("res://tests/resources/cutscene/cutscene_fixture.gd")
## Seconds of each fixture scene.
const SCENE_SECONDS := 0.1


## A looping 2 s silent cue that starts and stops at once.
static func music() -> MusicCue:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 8000
	var data := PackedByteArray()
	data.resize(16000)
	wav.data = data
	var cue := MusicCue.new()
	cue.id = &"fixture_visit"
	cue.stream = wav
	cue.stems = [&"bed"]
	cue.fade_in = 0.0
	cue.fade_out = 0.0
	return cue

## Flashback `number`: four short scenes, the visit's music, an arrival 100 px into the past room facing east.
static func flashback(number: int = 1) -> Flashback:
	var made := Flashback.new()
	made.number = number
	made.crossing = C.scene(StringName("fixture_crossing_%d" % number), [C.wait(SCENE_SECONDS)])
	made.opening = C.scene(StringName("fixture_opening_%d" % number), [C.wait(SCENE_SECONDS)])
	made.leaving = C.scene(FlashbackSchedule.id(number), [C.wait(SCENE_SECONDS)])
	made.returning = C.scene(StringName("fixture_returning_%d" % number), [C.wait(SCENE_SECONDS)])
	made.music = music()
	made.entry_fade = 0.5
	made.bars_thin = 12.0
	made.past_room = &"fixture_past"
	made.arrival = Vector2(100, 288)
	made.arrival_facing = 1
	return made

static func catalog(flashbacks: Array[Flashback]) -> FlashbackCatalog:
	var made := FlashbackCatalog.new()
	made.flashbacks = flashbacks
	return made

## A cutscene catalog holding every scene of `flashbacks`.
static func cutscenes(flashbacks: Array[Flashback]) -> CutsceneCatalog:
	var made := CutsceneCatalog.new()
	for flashback: Flashback in flashbacks:
		made.scenes.append_array([flashback.crossing, flashback.opening, flashback.leaving, flashback.returning])
	return made
