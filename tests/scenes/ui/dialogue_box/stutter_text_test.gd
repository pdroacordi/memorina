class_name StutterTextTest extends GdUnitTestSuite

## `~word~` marks a stuttered word: the text loses its marks and each marked word's start is kept.


func test_marks_are_stripped_and_their_starts_kept() -> void:
	var parsed := StutterText.parse("You came the ~long~ way.")
	assert_str(parsed["text"]).is_equal("You came the long way.")
	assert_array(Array(parsed["starts"])).is_equal([13])

func test_two_marked_words() -> void:
	var parsed := StutterText.parse("Yours ~too~. Maybe. If ~you~—")
	assert_str(parsed["text"]).is_equal("Yours too. Maybe. If you—")
	assert_array(Array(parsed["starts"])).is_equal([6, 21])

func test_a_line_without_marks_is_unchanged() -> void:
	var parsed := StutterText.parse("Bread. The round one.")
	assert_str(parsed["text"]).is_equal("Bread. The round one.")
	assert_array(Array(parsed["starts"])).is_empty()

func test_an_unclosed_mark_is_dropped_without_a_stutter() -> void:
	var parsed := StutterText.parse("A ~loose end")
	assert_str(parsed["text"]).is_equal("A loose end")
	assert_array(Array(parsed["starts"])).is_empty()
	assert_str(StutterText.strip("~a~")).is_equal("a")
