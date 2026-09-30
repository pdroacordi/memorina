class_name MapGuideTest extends GdUnitTestSuite

## docs/maps/README.md cannot drift from the code: its legend table, entity
## params and reach numbers are generated, and this fails whenever the
## committed guide is not what the generator would write. The fix is always
## the same: run tools/maps/gen_map_docs.tscn and commit the guide.

func test_the_map_guide_matches_the_code() -> void:
	var readme := FileAccess.get_file_as_string(MapGuide.README)
	var rendered := MapGuide.render(readme, RoomLegend.load_default())
	assert_bool(rendered == readme) \
		.override_failure_message("docs/maps/README.md is stale: run \"<godot>\" --headless --path . res://tools/maps/gen_map_docs.tscn") \
		.is_true()
