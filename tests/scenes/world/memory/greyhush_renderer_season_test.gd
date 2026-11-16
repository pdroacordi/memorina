class_name GreyhushRendererSeasonTest extends GdUnitTestSuite

## The renderer turns the region tint toward the next season by the year's turn and pushes the year's next season and
## turn as globals; without a year the tint and the season are the field's own.

const CATALOG := preload("res://resources/songs/song_catalog.tres")
const VILLAGE := "res://scenes/world/rooms/home_village.tscn"
const MASK := "res://scenes/world/memory/seasonal/season_mask.gdshader"

var _field: MemoryField


func before_test() -> void:
	SaveSystem.begin("", true)
	_field = auto_free(MemoryField.new()) as MemoryField
	_field.season = Enums.Season.SPRING
	_field.palette = CATALOG.palette_for(Enums.Season.SPRING)

func test_without_a_year_the_tint_and_season_are_the_fields() -> void:
	assert_float(GreyhushRenderer.turn_of(_field)).is_equal(0.0)
	assert_int(GreyhushRenderer.next_season_of(_field)).is_equal(Enums.Season.SPRING)
	assert_object(GreyhushRenderer.region_tint_of(_field, 0.0)).is_equal(_field.palette.tint)

func test_the_tint_lerps_toward_the_next_palette_by_the_turn() -> void:
	var village := auto_free((load(VILLAGE) as PackedScene).instantiate()) as Region
	add_child(village)
	_field.year = village.year
	_field.next_palette = CATALOG.palette_for(Enums.Season.SUMMER)
	village.year.advance(village.year.stats.season_seconds - village.year.stats.turn_seconds * 0.5)
	var turn := GreyhushRenderer.turn_of(_field)
	assert_float(turn).is_equal_approx(0.5, 0.0001)
	assert_int(GreyhushRenderer.next_season_of(_field)).is_equal(Enums.Season.SUMMER)
	var expected := _field.palette.tint.lerp(_field.next_palette.tint, 0.5)
	assert_object(GreyhushRenderer.region_tint_of(_field, turn)).is_equal(expected)

func test_the_globals_are_declared() -> void:
	for name: StringName in [&"greyhush_region_season_next", &"greyhush_season_turn"]:
		assert_bool(ProjectSettings.has_setting("shader_globals/" + String(name))).override_failure_message(String(name)).is_true()

## Headless runs render nothing, so the mask's turn is held to its source: game pixels, no clock, strict greater, and
## never over a pulse's swap.
func test_the_mask_turns_unswapped_pixels_on_world_anchored_cells() -> void:
	var source := FileAccess.get_file_as_string(MASK)
	assert_str(source).contains("global uniform int greyhush_region_season_next;")
	assert_str(source).contains("global uniform float greyhush_season_turn;")
	assert_str(source).contains("bool turned = !swapped && greyhush_season_turn > BAYER[gh_bayer_index(floor(px - turn_origin))];")
	assert_str(source).contains("vec2 px = UV * game_size;")
	assert_bool(source.contains("FRAGCOORD") or source.contains("TIME")).is_false()
