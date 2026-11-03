extends "res://tools/playtest/scripts/guardian_fight_talk_driver.gd"
## The guardian fight talk driver plus audio_probe.gd (music levels and sync playtest, 2026-11-03).

func _initialize() -> void:
	root.add_child.call_deferred(load("res://tools/playtest/scripts/audio_probe.gd").new())
	super._initialize()
