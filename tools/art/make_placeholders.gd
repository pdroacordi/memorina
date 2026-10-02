extends SceneTree

## Creates missing art prompt sheets at their contracted dimensions.
##
##   "<godot>" --headless --path . -s res://tools/art/make_placeholders.gd

const FILL := Color(0.62, 0.36, 0.72)
const EDGE := Color(0.16, 0.1, 0.2)

func _init() -> void:
	for prompt: ArtPrompt in ArtPrompt.all():
		if FileAccess.file_exists(prompt.target):
			continue
		var sheet := Image.create(prompt.sheet_size().x, prompt.sheet_size().y, false, Image.FORMAT_RGBA8)
		for i: int in prompt.frames:
			_frame(sheet, Rect2i(Vector2i(i * prompt.frame_size.x, 0), prompt.frame_size), i)
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(prompt.target.get_base_dir()))
		sheet.save_png(ProjectSettings.globalize_path(prompt.target))
		print("Placeholder %s (%s)" % [prompt.target, prompt.sheet_size()])
	quit()

func _frame(sheet: Image, rect: Rect2i, index: int) -> void:
	sheet.fill_rect(rect, FILL)
	for x: int in range(rect.position.x, rect.end.x):
		sheet.set_pixel(x, rect.position.y, EDGE)
		sheet.set_pixel(x, rect.end.y - 1, EDGE)
	for y: int in range(rect.position.y, rect.end.y):
		sheet.set_pixel(rect.position.x, y, EDGE)
		sheet.set_pixel(rect.end.x - 1, y, EDGE)
	for pip: int in index + 1:
		var at := rect.position + Vector2i(2 + pip * 3, 2)
		if at.x + 1 < rect.end.x - 1 and at.y + 1 < rect.end.y - 1:
			sheet.fill_rect(Rect2i(at, Vector2i(2, 2)), EDGE)
