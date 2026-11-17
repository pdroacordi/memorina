class_name VoiceBlips
extends RefCounted
## When a typed line sounds a voice blip: on its first letter and every `every`-th after, never on a space or punctuation
## (SND-05).


## Letters (alphanumeric characters) among the first `upto` characters of `text`.
static func letters(text: String, upto: int) -> int:
	var count := 0
	for i: int in mini(upto, text.length()):
		if _is_letter(text.unicode_at(i)):
			count += 1
	return count

## True when typing from `from` to `to` characters reaches letter 1, 1 + every, 1 + 2 every...
static func due(text: String, from: int, to: int, every: int) -> bool:
	if every <= 0 or to <= from:
		return false
	return _blips(letters(text, to), every) > _blips(letters(text, from), every)

static func _blips(count: int, every: int) -> int:
	return (count + every - 1) / every

static func _is_letter(code: int) -> bool:
	var c := char(code)
	return c.to_upper() != c.to_lower() or c.is_valid_int()
