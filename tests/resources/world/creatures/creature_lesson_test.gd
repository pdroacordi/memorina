class_name CreatureLessonTest extends GdUnitTestSuite

## A teacher's data: the phrase is its song's first half; reach edges count (systems/teaching-creatures).

const LESSONS := {
	"snail": [Enums.Note.LEFT, Enums.Note.RIGHT, Enums.Note.LEFT],
	"thrush": [Enums.Note.RIGHT, Enums.Note.RIGHT, Enums.Note.RIGHT],
	"kestrel": [Enums.Note.RIGHT, Enums.Note.RIGHT, Enums.Note.LEFT],
	"lizard": [Enums.Note.RIGHT, Enums.Note.DOWN, Enums.Note.UP],
}


func _lesson(name: String) -> CreatureLesson:
	return load("res://resources/world/creatures/%s_lesson.tres" % name) as CreatureLesson

func test_each_phrase_is_its_songs_first_three_notes() -> void:
	for name: String in LESSONS:
		var lesson := _lesson(name)
		assert_array(lesson.phrase()).override_failure_message(name).is_equal(LESSONS[name])
		assert_array(lesson.phrase()).is_equal(lesson.song.notes.slice(0, SongHalves.HALF_LENGTH))
		assert_array(Array(lesson.problems())).override_failure_message(name).is_empty()

func test_the_four_teach_the_four_halved_songs() -> void:
	var songs: Array[Enums.Song] = []
	for name: String in LESSONS:
		songs.append(_lesson(name).song.id)
	assert_array(songs).contains_exactly_in_any_order([Enums.Song.BELL_JAR, Enums.Song.RAIN, Enums.Song.GALE, Enums.Song.SOLSTICE])

func test_the_cadence_defaults() -> void:
	var lesson := _lesson("snail")
	assert_float(lesson.note_interval).is_equal(0.55)
	assert_float(lesson.retry_interval).is_equal(0.75)
	assert_float(lesson.repeat_after).is_equal(4.0)

func test_validate_rejects_a_missing_or_unhalved_song() -> void:
	var lesson := CreatureLesson.new()
	assert_array(Array(lesson.problems())).has_size(1)
	lesson.song = load("res://resources/songs/freeze.tres") as Song
	assert_array(Array(lesson.problems())).has_size(1)
	lesson.song = load("res://resources/songs/rain.tres") as Song
	assert_array(Array(lesson.problems())).is_empty()

func test_reach_edges_are_inclusive() -> void:
	var lesson := CreatureLesson.new()
	var feet := Vector2(100.0, 200.0)
	assert_bool(lesson.reaches(feet, feet + Vector2(-128.0, 0.0))).is_true()
	assert_bool(lesson.reaches(feet, feet + Vector2(128.0, 96.0))).is_true()
	assert_bool(lesson.reaches(feet, feet + Vector2(0.0, -96.0))).is_true()
	assert_bool(lesson.reaches(feet, feet + Vector2(128.5, 0.0))).is_false()
	assert_bool(lesson.reaches(feet, feet + Vector2(0.0, 96.5))).is_false()
