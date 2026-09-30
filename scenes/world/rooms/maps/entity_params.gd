class_name EntityParams extends RefCounted

## Applies a room map entity's JSON params to the node it placed
## (docs/maps/README.md, "Entity params"). A param is a property of the
## entity's root, by name, converted to that property's type:
##   numbers, booleans, strings, StringNames, enums (by their int)
##   Vector2 / Vector2i from [x, y]
##   Color from "#rrggbb" or "#rrggbbaa"
##   NodePath from another entity's `id` - it resolves among the room's
##     entities, so {"target_path": "gate_a"} points at the entity whose id is
##     "gate_a". A path that already starts with "." or "/" is kept as written.
## `id` itself is not a property: it names the node, which is what makes it a
## link target.

const ID := "id"

## Problems with `params` for `node`, as messages; empty when all apply.
static func check(node: Node, params: Dictionary) -> PackedStringArray:
	var problems := PackedStringArray()
	var types := _property_types(node)
	for key: String in params:
		if key == ID:
			continue
		if not types.has(key):
			problems.append("'%s' has no param '%s'" % [node.name, key])
			continue
		if _convert(params[key], types[key]) == null:
			problems.append("'%s'.%s: cannot use %s as %s" % [node.name, key, JSON.stringify(params[key]), type_string(types[key])])
	return problems

## Sets every param on `node`. Call check() first; a param that does not
## apply is skipped here rather than half-applied.
static func apply(node: Node, params: Dictionary) -> void:
	var types := _property_types(node)
	if params.has(ID):
		node.name = str(params[ID])
	for key: String in params:
		if key == ID or not types.has(key):
			continue
		var value: Variant = _convert(params[key], types[key])
		if value != null:
			node.set(key, value)

## The names a map may set, with their types: the root's own properties that
## are stored or shown in the editor (exports, and the engine's own such as
## position), which is exactly what the map guide lists.
static func _property_types(node: Node) -> Dictionary:
	var types := {}
	for property: Dictionary in node.get_property_list():
		if property.usage & (PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR):
			types[property.name] = property.type
	return types

static func _convert(value: Variant, type: int) -> Variant:
	match type:
		TYPE_BOOL:
			return value if value is bool else null
		TYPE_INT:
			return int(value) if (value is float or value is int) and is_equal_approx(float(value), roundf(float(value))) else null
		TYPE_FLOAT:
			return float(value) if value is float or value is int else null
		TYPE_STRING:
			return value if value is String else null
		TYPE_STRING_NAME:
			return StringName(value) if value is String else null
		TYPE_NODE_PATH:
			if not value is String:
				return null
			var text: String = value
			return NodePath(text) if text.begins_with(".") or text.begins_with("/") else NodePath("../" + text)
		TYPE_VECTOR2, TYPE_VECTOR2I:
			if not (value is Array and value.size() == 2 and (value[0] is float or value[0] is int) and (value[1] is float or value[1] is int)):
				return null
			return Vector2(value[0], value[1]) if type == TYPE_VECTOR2 else Vector2i(int(value[0]), int(value[1]))
		TYPE_COLOR:
			return Color.html(value) if value is String and Color.html_is_valid(value) else null
	return null
