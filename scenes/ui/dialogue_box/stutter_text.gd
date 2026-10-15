class_name StutterText
extends RefCounted
## `~word~` in a line marks a word said with a brief stutter ("Yes, a brief stutter (Recommended)", user,
## 2026-10-15). Pure: the box shows the text without the marks and stutters at each marked word.

const MARK := "~"


## {"text": the line without marks, "starts": the character index of each marked word in that text}.
static func parse(line: String) -> Dictionary:
	var text := ""
	var starts := PackedInt32Array()
	var parts := line.split(MARK)
	for i: int in parts.size():
		# Odd parts sat between two marks.
		if i % 2 == 1 and i < parts.size() - 1 and not parts[i].is_empty():
			starts.append(text.length())
		text += parts[i]
	return {"text": text, "starts": starts}

static func strip(line: String) -> String:
	return parse(line)["text"]
