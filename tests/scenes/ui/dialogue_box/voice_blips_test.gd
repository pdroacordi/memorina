class_name VoiceBlipsTest extends GdUnitTestSuite

## A blip sounds on a line's first letter and every third after, never on spaces or punctuation.


func test_letters_skip_spaces_and_punctuation() -> void:
	assert_int(VoiceBlips.letters("Oh, já!", 7)).is_equal(4)
	assert_int(VoiceBlips.letters("a1 b", 4)).is_equal(3)
	assert_int(VoiceBlips.letters("abc", 10)).is_equal(3)

func test_the_first_letter_blips() -> void:
	assert_bool(VoiceBlips.due("Hello", 0, 1, 3)).is_true()

func test_every_third_letter_blips_after_the_first() -> void:
	var text := "abcdefg"
	var blips: Array[int] = []
	for i: int in text.length():
		if VoiceBlips.due(text, i, i + 1, 3):
			blips.append(i + 1)
	assert_array(blips).contains_exactly([1, 4, 7])

func test_a_space_or_a_mark_never_blips() -> void:
	assert_bool(VoiceBlips.due("a, b", 1, 3, 1)).is_false()
	assert_bool(VoiceBlips.due("a, b", 3, 4, 1)).is_true()

func test_a_jump_over_several_letters_blips_once() -> void:
	assert_bool(VoiceBlips.due("abcdefgh", 1, 8, 3)).is_true()

func test_no_progress_or_no_spacing_is_silent() -> void:
	assert_bool(VoiceBlips.due("abc", 2, 2, 3)).is_false()
	assert_bool(VoiceBlips.due("abc", 0, 3, 0)).is_false()
