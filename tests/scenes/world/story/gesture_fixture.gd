extends RefCounted
## A FactStaging with a picked child `Rest` and a 3-frame gesture strip `Gesture`, and a LineGesture `wave` on it.

const FRAME_SECONDS := 0.05


## Adds the staging, then the gesture, under `parent`; returns [staging, gesture].
static func build(parent: Node, holds: bool = false) -> Array:
	var staging := FactStaging.new()
	staging.name = "Staging"
	var rest_stage := FactStage.new()
	rest_stage.show = &"Rest"
	rest_stage.fade_seconds = 0.0
	staging.stages = [rest_stage]
	var rest := Node2D.new()
	rest.name = "Rest"
	staging.add_child(rest)
	staging.add_child(_strip("Gesture"))
	staging.add_child(_strip("Other"))
	parent.add_child(staging)
	var gesture := LineGesture.new()
	gesture.gesture = &"wave"
	gesture.child = &"Gesture"
	gesture.holds = holds
	gesture.staging = NodePath("../Staging")
	parent.add_child(gesture)
	return [staging, gesture]

static func _strip(strip_name: String) -> StagedStrip:
	var frames := SpriteFrames.new()
	frames.add_animation(&"wave")
	frames.set_animation_loop(&"wave", false)
	frames.set_animation_speed(&"wave", 1.0 / FRAME_SECONDS)
	var image := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	for i: int in 3:
		frames.add_frame(&"wave", ImageTexture.create_from_image(image))
	var strip := StagedStrip.new()
	strip.name = strip_name
	strip.sprite_frames = frames
	strip.intro = &"wave"
	return strip
