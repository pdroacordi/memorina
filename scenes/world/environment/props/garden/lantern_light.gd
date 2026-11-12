class_name LanternLight
extends PointLight2D
## The lantern's flame light: its energy follows the lit frame its sprite shows, so it flickers on the memory clock with
## the flame, and fades with the memory at the lantern, so a forgotten lantern sheds no light
## (architecture/story-05-playable-flashbacks, "The lantern").

## The sprite whose frame the light follows.
@export var flame: Sprite2D
## Energy per sprite frame; a frame past the end gives the last.
@export var energies: PackedFloat32Array = PackedFloat32Array([0.0, 2.6, 3.0, 2.8])
## 0..1 scale on every energy: low while the day is still bright.
@export_range(0.0, 1.0) var strength: float = 1.0

var _field: MemoryField


func _ready() -> void:
	_field = MemoryField.find_in(self)

func _process(_delta: float) -> void:
	if flame == null or energies.is_empty():
		return
	var memory := 1.0 if _field == null else _field.sample(global_position)
	energy = energies[mini(flame.frame, energies.size() - 1)] * strength * memory
