class_name SongReceiver extends Area2D

## Mounted on anything in the world that answers to one song. This is the
## whole interface between the musical track and the world: a new effect is a
## new scene that composes one of these, and no part of the song, pulse or
## instrument code changes to accommodate it.
##
## It watches rather than being watched, on purpose. When a pulse frees itself
## the engine emits area_exited on everyone it was overlapping, so "the light
## left me" needs no cooperation from the pulse - and a pulse that shrinks
## past this receiver reports the same way.

## `origin` is where the pulse was lit - the centre of its song area - so an
## effect can grow from the point the song was played (ice spreading out from
## the player, design 03 §6.4).
signal song_entered(song: Song, origin: Vector2)
signal song_left(song: Song)

## The one song this object answers to. Ignoring every other song is what lets
## the world stay legible: the environment says what it needs, not the UI.
@export var reacts_to: Enums.Song = Enums.Song.FREEZE

## Matching pulses overlapping this receiver right now. Two pulses of the same
## song can overlap it, and the first one leaving must not end an effect the
## second is still lighting.
var _lit_by: int = 0

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _on_area_entered(area: Area2D) -> void:
	var song := _matching_song(area)
	if song:
		_lit_by += 1
		song_entered.emit(song, area.global_position)

func _on_area_exited(area: Area2D) -> void:
	var song := _matching_song(area)
	if song:
		_lit_by = maxi(_lit_by - 1, 0)
		song_left.emit(song)

## Whether any pulse of this song still covers the receiver - asked on
## song_left, so an effect ends only when the LAST light has gone.
func is_lit() -> bool:
	return _lit_by > 0

func _matching_song(area: Area2D) -> Song:
	var song_area := area as SongArea
	if song_area == null or song_area.song == null:
		return null
	return song_area.song if song_area.song.id == reacts_to else null
