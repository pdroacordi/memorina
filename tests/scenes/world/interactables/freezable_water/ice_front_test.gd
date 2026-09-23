class_name IceFrontTest extends GdUnitTestSuite

## FREEZE's ice (design 03 §6.3-6.4): it grows only over living water, hardens
## before it looks solid, carries weight conservatively, and thaws on its own
## clock - from the origin by default, so it melts behind the player.

const COLUMNS := 48
const WIDTH := 2
const FRAME := 1.0 / 60.0
const ORIGIN := 24

func _profile(thaw_delay: float = 1.5) -> IceProfile:
	var profile := IceProfile.new()
	profile.grow_speed = 160.0
	profile.crystallise_time = 0.35
	profile.harden_at = 0.35
	profile.solid_at = 0.8
	profile.thaw_delay = thaw_delay
	profile.thaw_speed = 48.0
	profile.melt_time = 0.5
	profile.segment_width = 8
	return profile

func _ice(profile: IceProfile = null) -> IceFront:
	return IceFront.new(COLUMNS, WIDTH, profile if profile else _profile())

func _rates(value: float) -> PackedFloat32Array:
	var rates := PackedFloat32Array()
	rates.resize(COLUMNS)
	rates.fill(value)
	return rates

func _run(ice: IceFront, rates: PackedFloat32Array, seconds: float) -> void:
	for frame in roundi(seconds / FRAME):
		ice.advance(FRAME, rates)

func _reached(ice: IceFront) -> int:
	var count := 0
	for i in COLUMNS:
		if ice.solidity(i) > 0.0:
			count += 1
	return count

func test_nothing_happens_before_the_song() -> void:
	var ice := _ice()
	_run(ice, _rates(1.0), 1.0)
	assert_bool(ice.is_active()).is_false()
	assert_int(_reached(ice)).is_equal(0)

func test_it_grows_symmetrically_from_the_origin() -> void:
	var ice := _ice()
	ice.freeze_from(ORIGIN)
	_run(ice, _rates(1.0), 0.1)
	for k in range(1, 12):
		assert_float(ice.solidity(ORIGIN - k)).is_equal(ice.solidity(ORIGIN + k))
	assert_float(ice.solidity(ORIGIN)).is_greater(ice.solidity(ORIGIN + 6))

func test_it_grows_slower_over_grey_water() -> void:
	var alive := _ice(_profile(100.0))
	var grey := _ice(_profile(100.0))
	alive.freeze_from(ORIGIN)
	grey.freeze_from(ORIGIN)
	_run(alive, _rates(1.0), 0.15)
	_run(grey, _rates(0.25), 0.15)
	assert_int(_reached(grey)).is_less(_reached(alive))
	assert_int(_reached(grey)).is_greater(1)

## Ice needs moving water: a front stops dead at a column nothing remembers,
## and carries on once a pulse wakes it.
func test_a_front_stops_at_dead_water_and_resumes_when_it_wakes() -> void:
	var ice := _ice(_profile(100.0))
	var rates := _rates(1.0)
	rates[30] = 0.0
	ice.freeze_from(ORIGIN)
	_run(ice, rates, 2.0)
	for i in range(30, COLUMNS):
		assert_float(ice.solidity(i)).is_equal(0.0)
	assert_bool(ice.is_solid(29)).is_true()
	_run(ice, _rates(1.0), 1.0)
	assert_bool(ice.is_solid(COLUMNS - 1)).is_true()

func test_the_surface_is_held_before_the_ice_looks_solid() -> void:
	var ice := _ice()
	ice.freeze_from(ORIGIN)
	_run(ice, _rates(1.0), 0.15)
	assert_float(ice.hold(ORIGIN)).is_equal(1.0)
	assert_float(ice.solidity(ORIGIN)).is_less(1.0)
	assert_bool(ice.is_solid(ORIGIN)).is_false()

## The design's default: the ice melts BEHIND the player, from where the song
## was played, while the far bank still holds.
func test_thaw_from_the_origin_leaves_the_far_bank_standing() -> void:
	var ice := _ice()
	ice.freeze_from(ORIGIN)
	_run(ice, _rates(1.0), 2.1)
	assert_float(ice.solidity(ORIGIN)).is_equal(0.0)
	assert_bool(ice.is_solid(COLUMNS - 1)).is_true()
	assert_bool(ice.is_solid(0)).is_true()

func test_thaw_from_the_edges_melts_the_banks_first() -> void:
	var profile := _profile()
	profile.thaw_origin = IceProfile.ThawOrigin.FROM_EDGES
	var ice := _ice(profile)
	ice.freeze_from(ORIGIN)
	_run(ice, _rates(1.0), 2.1)
	assert_float(ice.solidity(0)).is_equal(0.0)
	assert_float(ice.solidity(COLUMNS - 1)).is_equal(0.0)
	assert_bool(ice.is_solid(ORIGIN)).is_true()

## Once made, the ice keeps its own clock: a pulse contracting off it does not
## turn it into a permanent bridge.
func test_the_thaw_ignores_memory() -> void:
	var ice := _ice()
	ice.freeze_from(ORIGIN)
	_run(ice, _rates(1.0), 1.0)
	assert_bool(ice.is_solid(ORIGIN)).is_true()
	_run(ice, _rates(0.0), 1.1)
	assert_float(ice.solidity(ORIGIN)).is_equal(0.0)

func test_it_melts_away_completely() -> void:
	var ice := _ice()
	ice.freeze_from(ORIGIN)
	_run(ice, _rates(1.0), 5.0)
	assert_int(_reached(ice)).is_equal(0)
	assert_bool(ice.is_active()).is_false()

## A segment carries weight only while every column in it is solid, so the
## collider never reaches past the ice you can see.
func test_segments_are_conservative() -> void:
	var ice := _ice()
	ice.freeze_from(ORIGIN)
	for step in 40:
		_run(ice, _rates(1.0), 0.05)
		var segments := ice.solid_segments()
		for s in segments.size():
			if segments[s] == 1:
				for i in range(s * 4, mini(s * 4 + 4, COLUMNS)):
					assert_bool(ice.is_solid(i)).is_true()

func test_a_segment_with_one_soft_column_does_not_carry() -> void:
	var ice := _ice(_profile(100.0))
	var rates := _rates(1.0)
	rates[10] = 0.0
	ice.freeze_from(ORIGIN)
	_run(ice, rates, 1.0)
	assert_int(ice.solid_segments()[2]).is_equal(0)
	assert_int(ice.solid_segments()[4]).is_equal(1)

func test_refreezing_while_thawing_starts_over_and_keeps_the_ice() -> void:
	var ice := _ice()
	ice.freeze_from(ORIGIN)
	_run(ice, _rates(1.0), 2.1)
	assert_float(ice.solidity(ORIGIN)).is_equal(0.0)
	var far_bank := ice.solidity(COLUMNS - 1)
	ice.freeze_from(ORIGIN)
	_run(ice, _rates(1.0), 0.4)
	assert_bool(ice.is_solid(ORIGIN)).is_true()
	assert_float(ice.solidity(COLUMNS - 1)).is_greater_equal(far_bank)

func test_a_song_from_the_bank_freezes_from_the_nearest_edge() -> void:
	var ice := _ice()
	ice.freeze_from(-15)
	_run(ice, _rates(1.0), 0.1)
	assert_float(ice.solidity(0)).is_greater(ice.solidity(10))

## Every dead column stops the front, whichever index it sits on and however
## long the frame (docs/knowledge/bugs/ice-front-leaps-dead-columns.md).
func test_no_dead_column_is_ever_leapt() -> void:
	for frame_time: float in [1.0 / 60.0, 1.0 / 30.0, 0.1]:
		for dead in range(ORIGIN + 1, COLUMNS):
			var ice := _ice(_profile(100.0))
			var rates := _rates(1.0)
			rates[dead] = 0.0
			ice.freeze_from(ORIGIN)
			for step in roundi(2.0 / frame_time):
				ice.advance(frame_time, rates)
			for i in range(dead, COLUMNS):
				assert_float(ice.solidity(i)).is_equal(0.0)

func test_each_side_grows_at_its_own_memory() -> void:
	var ice := _ice(_profile(100.0))
	var rates := _rates(1.0)
	for i in ORIGIN:
		rates[i] = 0.25
	ice.freeze_from(ORIGIN)
	_run(ice, rates, 0.12)
	var left := 0
	var right := 0
	for k in range(1, ORIGIN):
		if ice.solidity(ORIGIN - k) > 0.0:
			left += 1
		if ice.solidity(ORIGIN + k) > 0.0:
			right += 1
	assert_int(left).is_less(right)
