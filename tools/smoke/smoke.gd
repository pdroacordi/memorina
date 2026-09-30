extends Node

## Opens every scene listed in scenes.txt for a few seconds of frames and
## exits 1 if anything logged an error (a script error, a failed load, a
## broken connection) - the cheap check to run after each phase, before the
## slower playtests. A custom Logger counts the errors, so no output needs
## scraping. Warnings reach the same Logger callback (error_type WARNING) and
## are listed but do not fail the run:
##   "<godot>" --headless --path . res://tools/smoke/smoke.tscn

const LIST := "res://tools/smoke/scenes.txt"
const FRAMES := 120

class ErrorCounter extends Logger:
	var errors := PackedStringArray()
	var warnings := PackedStringArray()
	var _lock := Mutex.new()

	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		var entry := "%s:%d (%s) %s %s" % [file, line, function, code, rationale]
		_lock.lock()
		if error_type == Logger.ERROR_TYPE_WARNING:
			warnings.append(entry)
		else:
			errors.append(entry)
		_lock.unlock()

	func _log_message(_message: String, _error: bool) -> void:
		pass

func _ready() -> void:
	var counter := ErrorCounter.new()
	OS.add_logger(counter)
	var scenes := PackedStringArray()
	for line: String in FileAccess.get_file_as_string(LIST).split("\n"):
		var path := line.strip_edges()
		if not path.is_empty() and not path.begins_with("#"):
			scenes.append(path)
	for path: String in scenes:
		var before := counter.errors.size()
		var packed := load(path) as PackedScene
		if packed == null:
			counter.errors.append("%s: could not be loaded" % path)
			continue
		var node := packed.instantiate()
		add_child(node)
		for i: int in FRAMES:
			await get_tree().process_frame
		node.queue_free()
		await get_tree().process_frame
		print("%s %s" % ["ok  " if counter.errors.size() == before else "FAIL", path])
	OS.remove_logger(counter)
	for warning: String in counter.warnings:
		print("  warning: " + warning)
	for error: String in counter.errors:
		print("  " + error)
	print("smoke: %d scene(s), %d error(s), %d warning(s)" % [scenes.size(), counter.errors.size(), counter.warnings.size()])
	get_tree().quit(1 if not counter.errors.is_empty() else 0)
