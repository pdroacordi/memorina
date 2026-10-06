class_name MenuScreen
extends Control
## A screen that Screens opens and closes; Screens decides when, the screen decides what it shows.


## Asked before the screen opens; false keeps it shut and leaves the press to the world.
func can_open() -> bool:
	return true

## Shows the screen and focuses its first entry.
func open() -> void:
	show()

func close() -> void:
	hide()

## Closes an inner panel (a confirmation) or starts the screen's own closing animation instead of closing it; true when it did.
func step_back() -> bool:
	return false
