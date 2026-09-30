class_name RootSpanFinderTest extends GdUnitTestSuite

## Roots join earth to earth: a bridge between two bank tops, a shaft between
## two walls, a pillar from floor to ceiling - and never from stone.

func _map(rows: Array[String]) -> RoomMap:
	var text := "[room]\norigin = 0, 0\n\n[grid]\n" + "\n".join(rows) + "\n"
	var result := RoomMapParser.parse(text, RoomLegend.load_default())
	assert(result.ok(), str(result.errors))
	return result.map

func _of(spans: Array[RootSpanFinder.Span], kind: RootSpanFinder.Kind) -> Array[RootSpanFinder.Span]:
	var found: Array[RootSpanFinder.Span] = []
	for span: RootSpanFinder.Span in spans:
		if span.kind == kind:
			found.append(span)
	return found

func _find(map: RoomMap) -> Array[RootSpanFinder.Span]:
	return RootSpanFinder.find(map, 8, 4, 2, 8)

func test_two_earth_banks_make_a_bridge_at_their_tops() -> void:
	var map := _map([
		"..........",
		"###....###",
		"###....###",
	] as Array[String])
	var bridges := _of(_find(map), RootSpanFinder.Kind.BRIDGE)
	assert_int(bridges.size()).is_equal(1)
	assert_vector(bridges[0].a).is_equal(Vector2i(2, 1))
	assert_vector(bridges[0].b).is_equal(Vector2i(7, 1))
	assert_int(bridges[0].gap()).is_equal(4)

func test_stone_never_roots() -> void:
	var map := _map([
		"..........",
		"###....SSS",
		"###....SSS",
	] as Array[String])
	assert_int(_of(_find(map), RootSpanFinder.Kind.BRIDGE).size()).is_equal(0)

func test_a_gap_too_wide_has_no_bridge() -> void:
	var map := _map([
		"................",
		"##...........###",
	] as Array[String])
	assert_int(_of(_find(map), RootSpanFinder.Kind.BRIDGE).size()).is_equal(0)

func test_a_bank_is_not_a_wall() -> void:
	# The right side rises above the left: its cell at the bank's row has
	# earth above, so it is a wall face, not a bank top.
	var map := _map([
		".......###",
		"###....###",
	] as Array[String])
	assert_int(_of(_find(map), RootSpanFinder.Kind.BRIDGE).size()).is_equal(0)

func test_facing_walls_make_a_shaft() -> void:
	var map := _map([
		"#..#",
		"#..#",
		"#..#",
		"####",
	] as Array[String])
	var shafts := _of(_find(map), RootSpanFinder.Kind.SHAFT)
	assert_int(shafts.size()).is_equal(1)
	assert_vector(shafts[0].rows).is_equal(Vector2i(0, 2))

func test_a_floor_under_a_ceiling_makes_pillars() -> void:
	var map := _map([
		"###",
		"...",
		"...",
		"###",
	] as Array[String])
	var pillars := _of(_find(map), RootSpanFinder.Kind.PILLAR)
	assert_int(pillars.size()).is_equal(3)
	assert_int(pillars[0].gap()).is_equal(2)
