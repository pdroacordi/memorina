class_name CreditsLicenceTest extends GdUnitTestSuite

## The licence's hard-wrapped lines join into one row per paragraph, each copyright notice a row of its own.


func test_wrapped_lines_join_and_each_copyright_is_its_own_row() -> void:
	var text := "Copyright (c) A.\nCopyright (c) B.\n\nPermission is\ngranted.\n\nTHE SOFTWARE\r\nIS PROVIDED.\n"
	assert_array(CreditsLicence.paragraphs(text)).is_equal(PackedStringArray([
		"Copyright (c) A.", "Copyright (c) B.", "Permission is granted.", "THE SOFTWARE IS PROVIDED.",
	]))

func test_its_lines_are_the_engines_licence() -> void:
	var lines := CreditsLicence.new().lines()
	assert_str(lines[0]).starts_with("Copyright")
	assert_int(lines.size()).is_equal(CreditsLicence.paragraphs(Engine.get_license_text()).size())
	assert_int(lines.size()).is_greater_equal(4)
