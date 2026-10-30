class_name DualCallJudgeTest extends GdUnitTestSuite

## The first note that tells the tracks apart commits; the other track's note after that is mixed and resets the answer;
## a note on neither is the ordinary failure; the revelation never completes (architecture/grd-06-final-battle).

const N := Enums.Note

## A and B differ at the first note and agree at the third.
var _a: Array[Enums.Note] = [N.UP, N.DOWN, N.LEFT, N.RIGHT, N.UP, N.DOWN]
var _b: Array[Enums.Note] = [N.LEFT, N.RIGHT, N.LEFT, N.DOWN, N.DOWN, N.UP]


func test_the_first_note_commits_and_a_pure_track_completes() -> void:
	var judge := DualCallJudge.new(_a, _b)
	assert_int(judge.feed(N.LEFT)).is_equal(DualCallJudge.Result.COMMITTED)
	assert_int(judge.track()).is_equal(DualCallJudge.TRACK_B)
	for note: Enums.Note in _b.slice(1, 5):
		assert_int(judge.feed(note)).is_equal(DualCallJudge.Result.NOTE)
	assert_int(judge.feed(N.UP)).is_equal(DualCallJudge.Result.COMPLETE)

func test_the_other_tracks_note_is_mixed_and_resets_the_answer() -> void:
	var judge := DualCallJudge.new(_a, _b)
	judge.feed(N.UP)
	assert_int(judge.feed(N.RIGHT)).is_equal(DualCallJudge.Result.MIXED)
	assert_int(judge.count()).is_equal(0)
	assert_int(judge.track()).is_equal(DualCallJudge.NONE)
	assert_int(judge.feed(N.LEFT)).is_equal(DualCallJudge.Result.COMMITTED)

func test_a_note_on_neither_track_is_wrong() -> void:
	var judge := DualCallJudge.new(_a, _b)
	assert_int(judge.feed(N.RIGHT)).is_equal(DualCallJudge.Result.WRONG)
	judge.feed(N.UP)
	assert_int(judge.feed(N.UP)).is_equal(DualCallJudge.Result.WRONG)

func test_the_revelation_mixes_every_note_after_the_first() -> void:
	var judge := DualCallJudge.new(_a, _b, false)
	assert_int(judge.feed(N.UP)).is_equal(DualCallJudge.Result.COMMITTED)
	assert_int(judge.feed(N.DOWN)).is_equal(DualCallJudge.Result.MIXED)
	for i: int in 8:
		assert_int(judge.feed(_a[i % _a.size()])).is_not_equal(DualCallJudge.Result.COMPLETE)
