class_name KeyGlyphTest extends GdUnitTestSuite

## The blank key names the event it shows, follows a rebinding, and names a pad button with no art.

const GLYPH := preload("res://scenes/ui/key_glyph/key_glyph.tscn")

var _glyph: KeyGlyph
var _glyph_set: Enums.GlyphSet


func before_test() -> void:
	_glyph_set = InputDevice.glyph_set
	InputDevice.glyph_set = Enums.GlyphSet.KEYBOARD_ARROWS
	_glyph = auto_free(GLYPH.instantiate()) as KeyGlyph
	add_child(_glyph)

func after_test() -> void:
	InputDevice.glyph_set = _glyph_set
	Settings.reset_bindings(KeyBindings.Device.KEYBOARD)

func test_the_label_names_the_shown_key() -> void:
	_glyph.show_action(&"jump")
	assert_str(_glyph.label_text()).is_equal(BindingNames.key_text(KEY_Z))

func test_a_rebinding_redraws_the_label() -> void:
	_glyph.show_action(&"jump")
	Settings.bind(KeyBindings.Device.KEYBOARD, &"jump", KEY_SPACE)
	assert_str(_glyph.label_text()).is_equal(BindingNames.key_text(KEY_SPACE))

## Back has no glyph art: its family's name goes on the blank key.
func test_a_pad_button_without_art_is_named() -> void:
	InputDevice.glyph_set = Enums.GlyphSet.XBOX
	_glyph.show_action(&"notebook")
	assert_str(_glyph.label_text()).is_equal(tr("PAD_XBOX_VIEW"))
	InputDevice.glyph_set = Enums.GlyphSet.PLAYSTATION
	_glyph.show_action(&"notebook")
	assert_str(_glyph.label_text()).is_equal(tr("PAD_PS_CREATE"))

func test_a_key_with_art_has_no_label() -> void:
	_glyph.show_action(&"note_up")
	assert_str(_glyph.label_text()).is_empty()
