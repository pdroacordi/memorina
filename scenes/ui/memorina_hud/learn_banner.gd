class_name LearnBanner extends Control

## "You learned how to play" and, beneath it, the piece's title. Shown for a
## lesson, hidden when the performance ends or the instrument is put away.
## The title's outline is the Label's own (`outline_size`), not a second font:
## two fonts at two sizes never line up glyph for glyph.
##
## Both Labels are given the translation KEY, not tr()'s result: a Label
## auto-translates its own text and re-resolves it when the locale changes,
## while a tr() baked in at _ready() would freeze whatever locale booted.

const LEARNED_KEY := "MEMORINA_LEARNED"

@onready var _message: Label = $Message
@onready var _title: Label = $Title

func _ready() -> void:
	_message.text = LEARNED_KEY
	hide()

func show_for(song: Song) -> void:
	_title.text = song.title_key
	show()

func dismiss() -> void:
	hide()
