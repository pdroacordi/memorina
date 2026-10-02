class_name ArtPrompt extends RefCounted

## One parsed art prompt contract (tools/art/prompts/README.md).

const DIR := "res://tools/art/prompts"
const STYLE := "res://tools/art/prompts/style.md"
const IGNORED := ["README.md", "style.md"]

var id := ""
## Prompt operation: `generate` or `animate`.
var command := "generate"
## Output PNG path under `res://assets/`.
var target := ""
var frame_size := Vector2i(32, 32)
var frames := 1
var view := "side"
var direction := "west"
var no_background := true
var outline := ""
var shading := ""
var detail := ""
## Animation action description.
var action := ""
## Reference asset path for animation or generation.
var reference := ""
## Art source identifier.
var source := "pixellab"
var description := ""
var negative := ""

static func all() -> Array[ArtPrompt]:
	var prompts: Array[ArtPrompt] = []
	for file: String in DirAccess.get_files_at(DIR):
		if file.get_extension() == "md" and not file in IGNORED:
			prompts.append(parse(FileAccess.get_file_as_string(DIR.path_join(file)), file.get_basename()))
	return prompts

static func find(prompt_id: String) -> ArtPrompt:
	var path := DIR.path_join(prompt_id + ".md")
	return parse(FileAccess.get_file_as_string(path), prompt_id) if FileAccess.file_exists(path) else null

static func parse(text: String, file_id: String) -> ArtPrompt:
	var prompt := ArtPrompt.new()
	var body := PackedStringArray()
	var fences := 0
	for line: String in text.replace("\r", "").split("\n"):
		if line.strip_edges() == "---" and fences < 2:
			fences += 1
			continue
		if fences == 1:
			var at := line.find(":")
			if at > 0:
				prompt._set_field(line.substr(0, at).strip_edges(), line.substr(at + 1).strip_edges())
		elif line.begins_with("Negative:"):
			prompt.negative = line.trim_prefix("Negative:").strip_edges()
		else:
			body.append(line)
	prompt.description = " ".join(body).strip_edges()
	if prompt.id.is_empty():
		prompt.id = file_id
	return prompt

## Returns validation errors for this prompt entry.
func problems(file_id: String) -> PackedStringArray:
	var found := PackedStringArray()
	if id != file_id:
		found.append("%s: id '%s' does not match its file name" % [file_id, id])
	if not target.begins_with("res://assets/") or target.get_extension() != "png":
		found.append("%s: target must be a .png under res://assets/" % file_id)
	if frame_size.x <= 0 or frame_size.y <= 0 or frames <= 0:
		found.append("%s: frame size and frame count must be positive" % file_id)
	if not command in ["generate", "animate"]:
		found.append("%s: command must be generate or animate" % file_id)
	if command == "animate" and (action.is_empty() or reference.is_empty()):
		found.append("%s: animate needs an action and a reference" % file_id)
	if source in ["pixellab", "codex"] and description.is_empty():
		found.append("%s: a generated asset's prompt needs a description" % file_id)
	return found

## Returns the sheet size with frames arranged side by side.
func sheet_size() -> Vector2i:
	return Vector2i(frame_size.x * frames, frame_size.y)

func _set_field(key: String, value: String) -> void:
	match key:
		"id": id = value
		"command": command = value
		"target": target = value
		"size":
			var parts := value.split("x")
			if parts.size() == 2:
				frame_size = Vector2i(parts[0].to_int(), parts[1].to_int())
		"frames": frames = value.to_int()
		"view": view = value
		"direction": direction = value
		"no_background": no_background = value == "true"
		"outline": outline = value
		"shading": shading = value
		"detail": detail = value
		"action": action = value
		"reference": reference = value
		"source": source = value
		_: push_warning("art prompt '%s': unknown field '%s'" % [id, key])
