class_name BindingRules
extends RefCounted
## Which actions may share an input, and what a new binding does to a table; pure (systems/settings, the share table).

enum Outcome { ASSIGNED, SWAPPED, UNCHANGED, REFUSED_RESERVED, REFUSED_TAKEN }
enum Group { MOVE, NOTE, DRAW, TOGGLE, ACCEPT, CANCEL }

const GROUPS: Dictionary[StringName, Group] = {
	&"jump": Group.MOVE, &"attack": Group.MOVE, &"roll": Group.MOVE,
	&"note_up": Group.NOTE, &"note_down": Group.NOTE, &"note_left": Group.NOTE, &"note_right": Group.NOTE,
	&"draw_memorina": Group.DRAW,
	&"map": Group.TOGGLE, &"notebook": Group.TOGGLE,
	KeyBindings.ACCEPT: Group.ACCEPT,
	KeyBindings.CANCEL: Group.CANCEL,
}


## What `assign` did: the outcome, the action it swapped with or was refused by, and the table after it.
class Assignment:
	var outcome: Outcome
	## The swapped or blocking action; empty otherwise.
	var other: StringName = &""
	var bindings: KeyBindings

	func _init(result: Outcome, table: KeyBindings, with_action: StringName = &"") -> void:
		outcome = result
		bindings = table
		other = with_action

	func changed() -> bool:
		return outcome == Outcome.ASSIGNED or outcome == Outcome.SWAPPED


## Whether actions `a` and `b` may hold the same input on `device`; see the share table in systems/settings.
static func may_share(device: KeyBindings.Device, a: StringName, b: StringName) -> bool:
	if a == b or not GROUPS.has(a) or not GROUPS.has(b):
		return false
	var first := GROUPS[a]
	var second := GROUPS[b]
	if first > second:
		var swap := first
		first = second
		second = swap
		var name_swap := a
		a = b
		b = name_swap
	var pad := device == KeyBindings.Device.PAD
	match [first, second]:
		[Group.MOVE, Group.NOTE]:
			return pad
		[Group.MOVE, Group.ACCEPT]:
			return true
		[Group.MOVE, Group.CANCEL]:
			# The zooms follow jump and attack, and MenuInput emits a zoom before back.
			return a == &"roll"
		[Group.NOTE, Group.ACCEPT], [Group.NOTE, Group.CANCEL]:
			return pad
		[Group.DRAW, Group.ACCEPT], [Group.DRAW, Group.CANCEL]:
			return true
	return false

## Whether `code` may never be bound on `bindings`' device; a keyboard code that names no key counts.
static func reserved(bindings: KeyBindings, code: int) -> bool:
	if bindings.reserved.has(code):
		return true
	if bindings.device == KeyBindings.Device.PAD:
		return not KeyBindings.PAD_BUTTONS.has(code)
	return code <= KEY_NONE or OS.get_keycode_string(code as Key).is_empty()

## Whether every code is allowed and every pair of actions holding one code may share it.
static func valid(bindings: KeyBindings) -> bool:
	for action: StringName in bindings.codes:
		var code := bindings.codes[action]
		if reserved(bindings, code):
			return false
		if not _conflicts(bindings, action, code).is_empty():
			return false
	return true

## Binds `action` to `code` (assign, swap or refuse, in that order of preference); `bindings` itself is not changed.
static func assign(bindings: KeyBindings, action: StringName, code: int) -> Assignment:
	if reserved(bindings, code):
		return Assignment.new(Outcome.REFUSED_RESERVED, bindings)
	if bindings.code(action) == code:
		return Assignment.new(Outcome.UNCHANGED, bindings)
	var conflicts := _conflicts(bindings, action, code)
	var next := bindings.copy()
	next.codes[action] = code
	if conflicts.is_empty():
		return Assignment.new(Outcome.ASSIGNED, next)
	var other := conflicts[0]
	if conflicts.size() == 1 and GROUPS[other] != Group.ACCEPT and GROUPS[other] != Group.CANCEL:
		var old := bindings.code(action)
		if old != KeyBindings.NONE:
			next.codes[other] = old
			if valid(next):
				return Assignment.new(Outcome.SWAPPED, next, other)
	return Assignment.new(Outcome.REFUSED_TAKEN, bindings, other)

## The holders of `code`, rebindable then fixed, that may not share it with `action`.
static func _conflicts(bindings: KeyBindings, action: StringName, code: int) -> Array[StringName]:
	var found: Array[StringName] = []
	var holders := bindings.holders(code)
	holders.append_array(bindings.fixed_holders(code))
	for holder: StringName in holders:
		if holder != action and not may_share(bindings.device, action, holder):
			found.append(holder)
	return found
