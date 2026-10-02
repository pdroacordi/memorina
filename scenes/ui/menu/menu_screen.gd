class_name MenuScreen
extends Control
## A screen that Screens opens and closes; Screens decides when, the screen decides what it shows.


## Shows the screen and focuses its first entry.
func open() -> void:
	show()

func close() -> void:
	hide()

## Closes an inner panel (a confirmation) instead of the screen; true when it did.
func step_back() -> bool:
	return false
