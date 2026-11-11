class_name DissonanceFx extends Node

## The only writer of the dissonance shader globals (`dissonance_veil`, `dissonance_revelation`, 0..1), fed by
## Player.dissonance_changed; it shows the veil and its screen copy only while either is above zero
## (architecture/grd-06-final-battle).
## Globals outlive a death's scene swap, so it zeroes them on entering and leaving.

## The full-screen veil it shows and hides.
@export var veil_path: NodePath
## The BackBufferCopy the veil reads; hidden with it, since it copies the whole screen every frame it shows.
@export var copy_path: NodePath

@onready var _veil: CanvasItem = get_node_or_null(veil_path) as CanvasItem
@onready var _copy: CanvasItem = get_node_or_null(copy_path) as CanvasItem


func _ready() -> void:
	set_dissonance(0.0, 0.0)

func _exit_tree() -> void:
	RenderingServer.global_shader_parameter_set(&"dissonance_veil", 0.0)
	RenderingServer.global_shader_parameter_set(&"dissonance_revelation", 0.0)

func set_dissonance(veil: float, revelation: float) -> void:
	RenderingServer.global_shader_parameter_set(&"dissonance_veil", clampf(veil, 0.0, 1.0))
	RenderingServer.global_shader_parameter_set(&"dissonance_revelation", clampf(revelation, 0.0, 1.0))
	var shown := veil > 0.0 or revelation > 0.0
	if _veil != null:
		_veil.visible = shown
	if _copy != null:
		_copy.visible = shown
