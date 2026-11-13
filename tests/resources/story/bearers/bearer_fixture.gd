extends RefCounted
## A fixture bearer fragment for the suites: data built in code, never in the shipped catalog.

const C := preload("res://tests/resources/cutscene/cutscene_fixture.gd")
const F := preload("res://tests/resources/story/flashbacks/flashback_fixture.gd")
const FREEZE := preload("res://resources/songs/freeze.tres")
const BASE := preload("res://assets/sprites/story/bearers/frost/frame_1_base.png")
## The EngravingView's default paper.
const PAPER := Color(0.758, 0.761, 0.771, 1.0)


## The FROST fragment: a call ending covered in `paper`, an engraving of four frames of `frame_seconds` each, a returning
## scene of one wait. Short frames make a fast fixture; 7.0 s make a sound one (validate's 25..35 s).
static func fragment(frame_seconds: float = 0.1, paper: Color = PAPER) -> BearerFragment:
	var made := BearerFragment.new()
	made.guardian = Enums.Guardian.FROST
	made.song = FREEZE
	var call_fade := CutsceneFade.new()
	call_fade.colour = paper
	call_fade.seconds = 0.1
	made.call = C.scene(&"bearer_frost_call", [C.wait(0.1), call_fade])
	made.call.skippable = false
	var steps: Array[CutsceneStep] = []
	for i: int in 4:
		steps.append(engraving_step(frame_seconds, i > 0))
	var clear := CutsceneEngravingClear.new()
	clear.seconds = 0.1
	steps.append(clear)
	var to_black := CutsceneFade.new()
	to_black.seconds = 0.1
	steps.append(to_black)
	made.engraving = C.scene(BearerSchedule.id(Enums.Guardian.FROST), steps)
	made.returning = C.scene(&"bearer_frost_returning", [C.wait(0.1)])
	made.returning.skippable = false
	made.music = F.music()
	made.music.stream = FREEZE.track
	made.music.loops = false
	made.stage_room = &"bearer_stage"
	made.arrival = Vector2(320, 288)
	made.arrival_facing = 1
	return made

static func engraving_step(seconds: float, dissolve: bool) -> CutsceneEngraving:
	var layer := EngravingLayer.new()
	layer.texture = BASE
	var frame := EngravingFrame.new()
	frame.layers = [layer]
	frame.captions = [&"BEARER_FROST_1"]
	frame.seconds = seconds
	frame.reveal_seconds = minf(seconds, 1.5)
	frame.dissolve_seconds = minf(seconds, 1.0)
	var step := CutsceneEngraving.new()
	step.frame = frame
	step.ink = FREEZE.palette
	step.dissolve = dissolve
	return step

static func catalog(fragments: Array[BearerFragment]) -> BearerFragmentCatalog:
	var made := BearerFragmentCatalog.new()
	made.fragments = fragments
	return made

## A cutscene catalog holding every scene of `fragments`.
static func cutscenes(fragments: Array[BearerFragment]) -> CutsceneCatalog:
	var made := CutsceneCatalog.new()
	for fragment: BearerFragment in fragments:
		made.scenes.append_array([fragment.call, fragment.engraving, fragment.returning])
	return made
