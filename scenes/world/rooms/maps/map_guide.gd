class_name MapGuide extends RefCounted

## Writes the parts of docs/maps/README.md that must never drift from the
## code: the legend table, every placeable entity's params, and the jump
## numbers a designer sizes gaps with. Each lives between
##   <!-- generated:NAME -->  ...  <!-- /generated:NAME -->
## markers; everything outside them is prose, written by hand.
##
## tools/maps/gen_map_docs.tscn rewrites the file; map_guide_test.gd fails
## whenever the committed guide differs from what this would write, so a new
## legend character, a new entity param or a retuned jump cannot land without
## the guide.

const README := "res://docs/maps/README.md"
const IVO_SCENE := "res://scenes/characters/ivo/ivo.tscn"
const CELL := 32.0

const KIND_NAMES := {
	RoomLegendEntry.Kind.GROUND: "ground",
	RoomLegendEntry.Kind.PLATFORM: "ledge",
	RoomLegendEntry.Kind.WATER: "water",
	RoomLegendEntry.Kind.ENTITY: "entity",
}

## `readme` with every generated section replaced by its current text.
static func render(readme: String, legend: RoomLegend) -> String:
	var sections := {
		"legend": legend_section(legend),
		"entities": entities_section(legend),
		"reach": reach_section(),
	}
	for name: String in sections:
		var open := "<!-- generated:%s -->" % name
		var close := "<!-- /generated:%s -->" % name
		var start := readme.find(open)
		var end := readme.find(close)
		assert(start >= 0 and end > start, "%s is missing its %s ... %s markers" % [README, open, close])
		readme = readme.substr(0, start + open.length()) + "\n" + sections[name] + readme.substr(end)
	return readme

static func legend_section(legend: RoomLegend) -> String:
	var lines := PackedStringArray([
		"| Character | Section | Kind | Material | What it is |",
		"|---|---|---|---|---|",
		"| `%s` | any grid | empty | - | Nothing: air in `[grid]`, no water in `[water]`. |" % RoomLegend.EMPTY,
	])
	for entry: RoomLegendEntry in legend.entries:
		var section := "`[water]`" if entry.kind == RoomLegendEntry.Kind.WATER else "`[grid]`"
		var material := "-"
		if entry.kind in [RoomLegendEntry.Kind.GROUND, RoomLegendEntry.Kind.PLATFORM]:
			material = Enums.Ground.keys()[entry.ground].to_lower()
		lines.append("| `%s` | %s | %s | %s | %s |" % [entry.symbol, section, KIND_NAMES[entry.kind], material, entry.description.replace("\n", " ")])
	return "\n".join(lines) + "\n"

static func entities_section(legend: RoomLegend) -> String:
	var lines := PackedStringArray()
	for entry: RoomLegendEntry in legend.entries:
		if entry.kind != RoomLegendEntry.Kind.ENTITY:
			continue
		var node := entry.scene.instantiate()
		lines.append("#### `%s` - %s" % [entry.symbol, node.name])
		lines.append("")
		lines.append("Scene `%s`, anchored at its cell's %s. %s" % [entry.scene.resource_path, "bottom centre (standing on the cell below)" if entry.anchor == RoomLegendEntry.Anchor.FEET else "centre", entry.description.replace("\n", " ")])
		lines.append("")
		lines.append("| Param | Type | Default |")
		lines.append("|---|---|---|")
		lines.append("| `id` | String | none - names the node so other entities can link to it |")
		for property: Dictionary in node.get_property_list():
			var usage: int = property.usage
			if usage & PROPERTY_USAGE_SCRIPT_VARIABLE == 0 or usage & PROPERTY_USAGE_EDITOR == 0:
				continue
			lines.append("| `%s` | %s | `%s` |" % [property.name, _type_name(property), var_to_str(node.get(property.name)).replace("\n", " ")])
		lines.append("")
		node.free()
	return "\n".join(lines)

## Ivo's reach from his real tuning (JumpReach), in pixels and in 32 px cells.
static func reach_section() -> String:
	var reach := ivo_reach()
	var rows := [
		["Jump height (holding jump)", reach.peak()],
		["Double-jump height (both jumps)", reach.peak(true)],
		["Widest gap, running jump, same height", reach.gap()],
		["Widest gap, running double jump, same height", reach.gap(true)],
		["Widest gap onto a ledge one cell higher", reach.reach_at(CELL)],
		["Widest gap onto a ledge one cell higher, double jump", reach.reach_at(CELL, true)],
	]
	var lines := PackedStringArray([
		"| Move | Pixels | Cells |",
		"|---|---|---|",
	])
	for row: Array in rows:
		lines.append("| %s | %d | %.1f |" % [row[0], floori(row[1]), row[1] / CELL])
	lines.append("")
	lines.append("Computed by `JumpReach` from `ivo_jump_stats.tres`, `ivo_locomotion_stats.tres`, the double jump's `height` and Ivo's collision radius. A gap wider than these is a song's job - that is what makes a song useful.")
	return "\n".join(lines) + "\n"

static func ivo_reach() -> JumpReach:
	var ivo := (load(IVO_SCENE) as PackedScene).instantiate()
	var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity") * ivo.gravity_scale
	var reach := JumpReach.new(
		gravity,
		ivo.get_node("Jump").stats,
		ivo.get_node("Locomotion").stats,
		ivo.get_node("DoubleJump").height,
		(ivo.get_node("CollisionShape2D").shape as CapsuleShape2D).radius)
	ivo.free()
	return reach

static func _type_name(property: Dictionary) -> String:
	if property.hint == PROPERTY_HINT_ENUM:
		return "enum (%s)" % property.hint_string
	if property.type == TYPE_OBJECT:
		return property.hint_string if not property.hint_string.is_empty() else "Object"
	return type_string(property.type)
