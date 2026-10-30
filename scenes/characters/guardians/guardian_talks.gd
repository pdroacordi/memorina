class_name GuardianTalks extends Node

## A guardian's words, kept out of Guardian: a bark beside its head from each lucid landing to its call's first note,
## and its talks on its Talkable (systems/guardians, "Talks"). Glue only: it reads no input and records nothing.

var _saying: bool = false
## BarkAnchor's x as authored (facing west); mirrored by facing, so a head ahead of the body keeps its balloon.
var _anchor_x: float = 0.0

@onready var _guardian: Guardian = get_parent()
@onready var _talkable: Talkable = $"../Talkable"
@onready var _anchor: Node2D = $"../BarkAnchor"


func _ready() -> void:
	var voice := _guardian.stats.voice
	assert(voice != null, "%s has no GuardianVoice." % _guardian.name)
	_talkable.talk = voice.talks
	_anchor_x = _anchor.position.x
	_guardian.lucid_landed.connect(_on_lucid_landed)
	_guardian.call_note_sung.connect(_close.unbind(1))
	_guardian.call_ended.connect(_close)

## Landed facing Ivo, it speaks on the side away from him.
func _on_lucid_landed(cycle: int, after_failure: bool) -> void:
	var balloon := BarkBalloon.find(get_tree())
	var key := _guardian.stats.voice.bark_for(cycle, after_failure)
	if balloon == null or key.is_empty():
		return
	_anchor.position.x = _anchor_x * -_guardian.facing
	balloon.say(_anchor, key, -_guardian.facing, _guardian)
	_saying = true

func _close() -> void:
	if not _saying or not is_inside_tree():
		return
	_saying = false
	var balloon := BarkBalloon.find(get_tree())
	if balloon != null and balloon.speaker() == _anchor:
		balloon.close()
