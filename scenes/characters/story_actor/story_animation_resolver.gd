class_name StoryAnimationResolver
extends AnimationResolver
## Resolves a StoryActor's clip: its walk while walking, else the clip a gesture asked for, held on its settle clip once a
## one-shot ends. Each actor's subclass owns its clip names (systems/animation).

@onready var _actor: StoryActor = get_parent()


func resolve() -> StringName:
	if _actor.is_walking():
		return walk_clip()
	var asked := _actor.asked_clip()
	if asked == &"":
		return idle_clip()
	var settle := settle_of(asked)
	if settle != asked and (driver.current == settle or driver.finished(asked)):
		return settle
	return asked

## The clip a one-shot ends held on; a loop or a held clip is its own.
func settle_of(clip: StringName) -> StringName:
	return settles().get(clip, clip)

## Whether `clip` has played out to the clip it is held on.
func is_settled(clip: StringName) -> bool:
	var settle := settle_of(clip)
	return settle == clip or driver.current == settle

func has_clip(clip: StringName) -> bool:
	return clips().has(clip)

## Every clip this actor plays.
func clips() -> Array[StringName]:
	return []

## One-shot clip -> the clip it ends held on.
func settles() -> Dictionary[StringName, StringName]:
	return {}

func walk_clip() -> StringName:
	return &""

## What the actor shows after a walk and when nothing is asked.
func idle_clip() -> StringName:
	return &""
