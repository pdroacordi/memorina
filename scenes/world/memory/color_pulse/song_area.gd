class_name SongArea extends Area2D

## The reach of a pulse, as a physics shape, carrying which song lit it.
##
## Monitorable but NOT monitoring: the receivers do the watching. That way a
## pulse freeing itself makes the engine emit area_exited on everyone it was
## touching, and the pulse needs no bookkeeping about who it was covering.

var song: Song
