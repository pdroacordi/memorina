class_name CutsceneMusicTest extends GdUnitTestSuite

## A CutsceneMusic step hands its cue and fade to the context and never waits; the restoration scene plays its cue
## beside the mentor's melody (architecture/music-system).

const RESTORATION := preload("res://resources/cutscene/story/world_restoration.tres")


class Recording extends CutsceneContext:
	var asked: Array = []

	func music(cue: MusicCue, fade: float) -> void:
		asked.append([cue, fade])


func test_the_step_asks_and_does_not_wait() -> void:
	var context := Recording.new()
	var step := CutsceneMusic.new()
	step.cue = MusicCue.new()
	step.fade = 0.5
	var task := step.begin(context)
	assert_bool(task.tick(0.0)).is_true()
	assert_array(context.asked).has_size(1)
	assert_object(context.asked[0][0]).is_same(step.cue)
	assert_float(context.asked[0][1]).is_equal(0.5)

func test_the_restoration_plays_its_cue_beside_the_melody() -> void:
	var together: CutsceneTogether = null
	for step: CutsceneStep in RESTORATION.steps:
		if step is CutsceneTogether:
			for child: CutsceneStep in (step as CutsceneTogether).steps:
				if child is CutsceneMelody:
					together = step
	assert_object(together).is_not_null()
	var music: CutsceneMusic = null
	for child: CutsceneStep in together.steps:
		if child is CutsceneMusic:
			music = child
	assert_object(music).is_not_null()
	assert_bool(music.cue.loops).is_false()
