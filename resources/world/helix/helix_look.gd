@tool
class_name HelixLook extends Resource

## The colours and dimensions a HelixView draws a turning tower in, sampled from its approved board
## (tools/art/prompts/helix_look_bell_tower.md). Read only by the view.

## The wall's stone tones, and its mortar, highlight and shadow lines.
@export var stone := PackedColorArray([Color("#766954"), Color("#80725d"), Color("#8f7f67")])
@export var mortar := Color("#554b42")
@export var stone_light := Color("#99886c")
@export var stone_shadow := Color("#5d5448")
## Px of one wall course, and the narrowest and widest block along the wall.
@export var course_height := 24.0
@export var block_min := 40.0
@export var block_max := 64.0
## Timber of the posts and beams: two tones and a line.
@export var timber := PackedColorArray([Color("#714f38"), Color("#4e3f35")])
@export var timber_line := Color("#2c211c")
## A tread's top (lit, shaded), its nosing line, the riser, the soffit and the stringer cut across the front.
@export var tread := PackedColorArray([Color("#946340"), Color("#805538")])
@export var nosing := Color("#9b673f")
@export var riser := PackedColorArray([Color("#553d2c"), Color("#453125")])
@export var soffit := PackedColorArray([Color("#3d3028"), Color("#34271f")])
@export var stringer := PackedColorArray([Color("#805538"), Color("#6b482f"), Color("#312724")])
## Px a step is thick, top to soffit.
@export var step_depth := 20.0
## Px of the stringer band across the front, below the tread sections in Ivo's plane.
@export var band_depth := 28.0
## The gallery's planks (face, shade) and their joint line, and px of its edge seen across the shell.
@export var gallery := PackedColorArray([Color("#805538"), Color("#6b482f")])
@export var gallery_line := Color("#312724")
@export var gallery_depth := 18.0
## A slit's glass (light, dark) and frame.
@export var glass := PackedColorArray([Color("#a7d5f8"), Color("#677581")])
@export var slit_frame := Color("#27252a")
## Slits as (tower angle, px above the base of the slit's bottom), and their size in px.
@export var slits := PackedVector2Array([Vector2(3.1, 150), Vector2(5.2, 410), Vector2(1.0, 650), Vector2(3.1, 880), Vector2(5.2, 1130), Vector2(1.0, 1240)])
@export var slit_size := Vector2(16, 56)
## Posts as tower angles, and their width in px.
@export var posts := PackedFloat32Array([1.9, 4.4])
@export var post_width := 12.0
## The floor's top: two tones and a line.
@export var floor_tones := PackedColorArray([Color("#9c8c73"), Color("#b09e7b")])
@export var floor_line := Color("#6e685e")
## Beams as px above the base of their bottom edge, and their height in px.
@export var beams := PackedFloat32Array([1360.0])
@export var beam_height := 16.0
## The bell, drawn at its axis-depth size, and the px above the base its top hangs from.
@export var bell: Texture2D
@export var bell_height := 1408.0
