class_name SongArea extends Area2D

## Pulse collision area carrying the song that created it.
## Receivers monitor it so freeing a pulse emits area_exited for overlapping areas.

var song: Song
