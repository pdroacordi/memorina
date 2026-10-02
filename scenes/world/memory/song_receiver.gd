class_name SongReceiver extends Area2D

## Receives one song's pulses and emits signals when they enter or leave.

## Pulse origin lets effects grow from where the song was played (design 03 section 6.4).
signal song_entered(song: Song, origin: Vector2)
signal song_left(song: Song)

## Song this receiver answers to.
@export var reacts_to: Enums.Song = Enums.Song.FREEZE

## Track overlapping pulses so one leaving does not end an effect while another remains.
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
