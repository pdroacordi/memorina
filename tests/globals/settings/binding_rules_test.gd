class_name BindingRulesTest extends GdUnitTestSuite

## The share table per device, the reserved inputs, and assign: assign, swap when exactly one action conflicts and the
## result is legal, else refuse.

const PAD := KeyBindings.Device.PAD
const KEYS := KeyBindings.Device.KEYBOARD

var _pad: KeyBindings
var _keys: KeyBindings


func before_test() -> void:
	_pad = KeyBindings.from_input_map(PAD)
	_keys = KeyBindings.from_input_map(KEYS)

func test_the_defaults_are_valid() -> void:
	assert_bool(BindingRules.valid(_pad)).is_true()
	assert_bool(BindingRules.valid(_keys)).is_true()

## One action per group stands for it; each row is [a, b, keyboard, pad].
func test_the_share_table() -> void:
	var rows: Array = [
		[&"jump", &"attack", false, false],
		[&"jump", &"note_up", false, true],
		[&"jump", &"draw_memorina", false, false],
		[&"jump", &"map", false, false],
		[&"jump", &"ui_accept", true, true],
		[&"jump", &"ui_cancel", false, false],
		[&"attack", &"ui_cancel", false, false],
		[&"roll", &"ui_cancel", true, true],
		[&"note_up", &"note_down", false, false],
		[&"note_up", &"draw_memorina", false, false],
		[&"note_up", &"notebook", false, false],
		[&"note_up", &"ui_accept", false, true],
		[&"note_up", &"ui_cancel", false, true],
		[&"draw_memorina", &"map", false, false],
		[&"draw_memorina", &"ui_accept", true, true],
		[&"draw_memorina", &"ui_cancel", true, true],
		[&"map", &"notebook", false, false],
		[&"map", &"ui_accept", false, false],
		[&"notebook", &"ui_cancel", false, false],
	]
	for row: Array in rows:
		var pair := "%s / %s" % [row[0], row[1]]
		assert_bool(BindingRules.may_share(KEYS, row[0], row[1])).override_failure_message("keyboard " + pair).is_equal(row[2])
		assert_bool(BindingRules.may_share(PAD, row[0], row[1])).override_failure_message("pad " + pair).is_equal(row[3])
		assert_bool(BindingRules.may_share(PAD, row[1], row[0])).override_failure_message("pad reversed " + pair).is_equal(row[3])

func test_reserved_codes_are_refused() -> void:
	for code: int in [KEY_ESCAPE, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_F8, KEY_F9, KEY_F10]:
		assert_int(BindingRules.assign(_keys, &"jump", code).outcome).override_failure_message(str(code)) \
				.is_equal(BindingRules.Outcome.REFUSED_RESERVED)
	for button: int in [JOY_BUTTON_START, JOY_BUTTON_GUIDE, JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_MISC1,
			JOY_BUTTON_PADDLE1]:
		assert_int(BindingRules.assign(_pad, &"jump", button).outcome).override_failure_message(str(button)) \
				.is_equal(BindingRules.Outcome.REFUSED_RESERVED)

func test_pad_jump_to_y_is_assigned_beside_note_up() -> void:
	var result := BindingRules.assign(_pad, &"jump", JOY_BUTTON_Y)
	assert_int(result.outcome).is_equal(BindingRules.Outcome.ASSIGNED)
	assert_int(result.bindings.code(&"jump")).is_equal(JOY_BUTTON_Y)
	assert_int(result.bindings.code(&"note_up")).is_equal(JOY_BUTTON_Y)
	assert_int(_pad.code(&"jump")).override_failure_message("the table passed in is unchanged").is_equal(JOY_BUTTON_A)

func test_pad_jump_to_x_swaps_with_attack() -> void:
	var result := BindingRules.assign(_pad, &"jump", JOY_BUTTON_X)
	assert_int(result.outcome).is_equal(BindingRules.Outcome.SWAPPED)
	assert_str(String(result.other)).is_equal("attack")
	assert_int(result.bindings.code(&"attack")).is_equal(JOY_BUTTON_A)

func test_pad_map_to_a_is_refused_used_by_jump() -> void:
	var result := BindingRules.assign(_pad, &"map", JOY_BUTTON_A)
	assert_int(result.outcome).is_equal(BindingRules.Outcome.REFUSED_TAKEN)
	assert_str(String(result.other)).is_equal("jump")
	assert_object(result.bindings).is_same(_pad)

## B is ui_cancel: jump may not take it (its zoom would beat back in the map); roll may.
func test_pad_jump_to_b_is_refused_while_roll_to_b_is_assigned() -> void:
	assert_int(BindingRules.assign(_pad, &"jump", JOY_BUTTON_B).outcome).is_equal(BindingRules.Outcome.REFUSED_TAKEN)
	var moved := BindingRules.assign(_pad, &"roll", JOY_BUTTON_LEFT_STICK)
	assert_int(moved.outcome).is_equal(BindingRules.Outcome.ASSIGNED)
	assert_int(BindingRules.assign(moved.bindings, &"roll", JOY_BUTTON_B).outcome).is_equal(BindingRules.Outcome.ASSIGNED)

func test_pad_note_up_to_a_swaps_with_note_down() -> void:
	var result := BindingRules.assign(_pad, &"note_up", JOY_BUTTON_A)
	assert_int(result.outcome).is_equal(BindingRules.Outcome.SWAPPED)
	assert_str(String(result.other)).is_equal("note_down")
	assert_int(result.bindings.code(&"note_down")).is_equal(JOY_BUTTON_Y)

func test_keyboard_note_up_to_z_is_refused() -> void:
	assert_int(BindingRules.assign(_keys, &"note_up", KEY_Z).outcome).is_equal(BindingRules.Outcome.REFUSED_TAKEN)

## Swapping jump onto W would leave note_up on Z, which ui_accept holds: refused. From Q the swap is legal.
func test_keyboard_jump_to_w_swaps_with_note_up_only_when_the_result_is_valid() -> void:
	var refused := BindingRules.assign(_keys, &"jump", KEY_W)
	assert_int(refused.outcome).is_equal(BindingRules.Outcome.REFUSED_TAKEN)
	assert_str(String(refused.other)).is_equal("note_up")
	var on_q := BindingRules.assign(_keys, &"jump", KEY_Q).bindings
	var swapped := BindingRules.assign(on_q, &"jump", KEY_W)
	assert_int(swapped.outcome).is_equal(BindingRules.Outcome.SWAPPED)
	assert_int(swapped.bindings.code(&"note_up")).is_equal(KEY_Q)

func test_keyboard_attack_to_z_swaps_with_jump() -> void:
	var result := BindingRules.assign(_keys, &"attack", KEY_Z)
	assert_int(result.outcome).is_equal(BindingRules.Outcome.SWAPPED)
	assert_int(result.bindings.code(&"jump")).is_equal(KEY_X)

func test_keyboard_jump_to_space_shares_ui_accept() -> void:
	assert_int(BindingRules.assign(_keys, &"jump", KEY_SPACE).outcome).is_equal(BindingRules.Outcome.ASSIGNED)

func test_the_own_code_is_unchanged() -> void:
	assert_int(BindingRules.assign(_keys, &"jump", KEY_Z).outcome).is_equal(BindingRules.Outcome.UNCHANGED)
	assert_int(BindingRules.assign(_pad, &"roll", JOY_BUTTON_B).outcome).is_equal(BindingRules.Outcome.UNCHANGED)

func test_a_table_with_a_conflict_or_a_reserved_code_is_invalid() -> void:
	var clash := _keys.copy()
	clash.codes[&"map"] = KEY_E
	assert_bool(BindingRules.valid(clash)).is_false()
	var reserved := _keys.copy()
	reserved.codes[&"map"] = KEY_ESCAPE
	assert_bool(BindingRules.valid(reserved)).is_false()

func test_a_keyboard_code_that_is_no_key_is_refused() -> void:
	assert_int(BindingRules.assign(_keys, &"jump", KEY_NONE).outcome).is_equal(BindingRules.Outcome.REFUSED_RESERVED)
	assert_int(BindingRules.assign(_keys, &"jump", -3).outcome).is_equal(BindingRules.Outcome.REFUSED_RESERVED)
