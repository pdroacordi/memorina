class_name GuardianBodyContactTest extends GdUnitTestSuite

## A body a no-contact move carried onto Ivo spares him until he is out of it or the grace runs out, and a recovery
## skid stops short of him (bugs/the-frost-charge-skids-onto-ivo-harmlessly-and-its-body-hurts-the-instant-its-recovery-ends).

const STEP := 1.0 / 60.0

var _contact: GuardianBodyContact


func before_test() -> void:
	_contact = GuardianBodyContact.new()

func test_nothing_is_held_until_a_no_contact_move_ends() -> void:
	_contact.tick(STEP, true)
	assert_bool(_contact.holds()).is_false()

func test_it_holds_while_ivo_stays_inside_until_the_grace_runs_out() -> void:
	_contact.begin()
	var held := 0.0
	while _contact.holds() and held < 2.0:
		_contact.tick(STEP, true)
		held += STEP
	assert_float(held).is_equal_approx(GuardianBodyContact.GRACE, STEP)

func test_it_ends_the_moment_ivo_is_out_of_the_body() -> void:
	_contact.begin()
	_contact.tick(STEP, true)
	assert_bool(_contact.holds()).is_true()
	_contact.tick(STEP, false)
	assert_bool(_contact.holds()).is_false()
	# Walking back in is touching the body again.
	_contact.tick(STEP, true)
	assert_bool(_contact.holds()).is_false()

func test_a_skid_stops_short_of_ivo_ahead_only() -> void:
	var bodies := 45.0
	assert_bool(GuardianBodyContact.skid_stops(48.0, 400.0, bodies)).is_true()
	assert_bool(GuardianBodyContact.skid_stops(-48.0, -400.0, bodies)).is_true()
	assert_bool(GuardianBodyContact.skid_stops(48.0, -400.0, bodies)).override_failure_message("skidding away").is_false()
	assert_bool(GuardianBodyContact.skid_stops(120.0, 400.0, bodies)).override_failure_message("still far").is_false()
	assert_bool(GuardianBodyContact.skid_stops(48.0, 0.0, bodies)).is_false()

func test_a_new_string_clears_the_hold() -> void:
	_contact.begin()
	_contact.clear()
	_contact.tick(STEP, true)
	assert_bool(_contact.holds()).is_false()
