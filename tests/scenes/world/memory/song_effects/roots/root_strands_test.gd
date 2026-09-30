class_name RootStrandsTest extends GdUnitTestSuite

## Two roots grow toward each other at the memory under each tip, meet, and
## break at the tips first when the pulse lets go of a face.

func test_they_grow_from_both_faces_and_meet() -> void:
	var strands := RootStrands.new(100.0)
	strands.advance(0.5, 100.0, 200.0, 1.0, 1.0, true, true)
	assert_bool(strands.is_joined()).is_true()
	assert_float(strands.a).is_equal_approx(50.0, 0.001)

func test_a_root_grows_at_the_memory_under_its_tip() -> void:
	var strands := RootStrands.new(100.0)
	strands.advance(0.25, 100.0, 200.0, 1.0, 0.0, true, true)
	assert_float(strands.a).is_equal_approx(25.0, 0.001)
	assert_float(strands.b).is_equal(0.0)

func test_they_never_pass_each_other() -> void:
	var strands := RootStrands.new(40.0)
	strands.advance(5.0, 100.0, 200.0, 1.0, 1.0, true, true)
	assert_float(strands.a + strands.b).is_less_equal(40.001)

func test_a_face_let_go_breaks_the_span_and_withers_back() -> void:
	var strands := RootStrands.new(100.0)
	strands.advance(1.0, 100.0, 200.0, 1.0, 1.0, true, true)
	strands.advance(0.1, 100.0, 200.0, 1.0, 1.0, false, true)
	assert_bool(strands.is_joined()).is_false()
	assert_float(strands.a).is_less(50.0)

func test_nothing_grows_where_nothing_holds() -> void:
	var strands := RootStrands.new(100.0)
	strands.advance(1.0, 100.0, 200.0, 1.0, 1.0, false, false)
	assert_bool(strands.is_bare()).is_true()
