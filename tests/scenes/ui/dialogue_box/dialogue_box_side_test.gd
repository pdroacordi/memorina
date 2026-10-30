class_name DialogueBoxSideTest extends GdUnitTestSuite

## The box opens opposite the speakers: the top when they stand in the lower half, the bottom when they stand high
## ("Opposite the speakers (Recommended)", user, 2026-10-15); a face the top box would cover opens it at the bottom
## ("Caixa pela cabeça", user, 2026-10-30).


func test_speakers_low_on_screen_open_it_at_the_top() -> void:
	assert_int(DialogueBoxSide.opposite(PackedFloat32Array([260.0, 270.0]), 360.0)).is_equal(DialogueBoxSide.Side.TOP)

func test_speakers_high_on_screen_open_it_at_the_bottom() -> void:
	assert_int(DialogueBoxSide.opposite(PackedFloat32Array([90.0, 120.0]), 360.0)).is_equal(DialogueBoxSide.Side.BOTTOM)

## The midpoint decides: one speaker high and one low reads as their mean.
func test_the_midpoint_decides() -> void:
	assert_int(DialogueBoxSide.opposite(PackedFloat32Array([60.0, 280.0]), 360.0)).is_equal(DialogueBoxSide.Side.BOTTOM)
	assert_int(DialogueBoxSide.opposite(PackedFloat32Array([100.0, 300.0]), 360.0)).is_equal(DialogueBoxSide.Side.TOP)

func test_the_exact_middle_and_no_speaker_open_it_at_the_top() -> void:
	assert_int(DialogueBoxSide.opposite(PackedFloat32Array([180.0]), 360.0)).is_equal(DialogueBoxSide.Side.TOP)
	assert_int(DialogueBoxSide.opposite(PackedFloat32Array(), 360.0)).is_equal(DialogueBoxSide.Side.TOP)

func test_a_face_under_the_top_box_opens_it_at_the_bottom() -> void:
	var low := PackedFloat32Array([270.0, 280.0])
	assert_int(DialogueBoxSide.place(low, 360.0, 120.0, 176.0)).is_equal(DialogueBoxSide.Side.BOTTOM)

func test_a_face_below_the_top_box_or_no_face_follows_the_speakers() -> void:
	var low := PackedFloat32Array([270.0, 280.0])
	var high := PackedFloat32Array([90.0, 120.0])
	assert_int(DialogueBoxSide.place(low, 360.0, 190.0, 176.0)).is_equal(DialogueBoxSide.Side.TOP)
	assert_int(DialogueBoxSide.place(low, 360.0)).is_equal(DialogueBoxSide.Side.TOP)
	assert_int(DialogueBoxSide.place(high, 360.0)).is_equal(DialogueBoxSide.Side.BOTTOM)
