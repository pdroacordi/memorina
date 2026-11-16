class_name SeatGate
extends Node
## The only writer of its seat's `open`: open while its gates hold under the save, picked at ready and on every progress
## change, never recorded (architecture/story-07-epilogue, "The stone's two seats").

@export var seat: Seat
@export var when: Array[SaveFact] = []
@export var unless: Array[SaveFact] = []


func _ready() -> void:
	assert(seat != null, "%s has no seat" % name)
	SaveSystem.progress_changed.connect(refresh)
	refresh()

func refresh() -> void:
	seat.open = SaveFact.gates_pass(when, unless, SaveSystem.player_data)
