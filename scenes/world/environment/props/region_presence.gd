class_name RegionPresence
extends Node
## Shows its parent only while the region's memory baseline is at least `min_baseline`: villagers
## who leave as the village forgets (design 04 section 5, architecture/props-and-ambient-life).

## Region baseline (0..1) at and above which the parent is shown; 0 always shows it.
@export_range(0.0, 1.0) var min_baseline: float = 0.0

var _parent: CanvasItem


static func shown(level: float, threshold: float) -> bool:
	return level >= threshold

func _ready() -> void:
	_parent = get_parent() as CanvasItem
	assert(_parent != null, "RegionPresence must be the child of a CanvasItem.")
	var room := Room.of(self)
	if room == null:
		return
	var region := room.get_region()
	apply(region.current_baseline())
	region.memory_changed.connect(apply)

func apply(level: float) -> void:
	_parent.visible = shown(level, min_baseline)
