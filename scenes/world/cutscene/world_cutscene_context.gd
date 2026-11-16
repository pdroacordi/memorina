class_name WorldCutsceneContext
extends CutsceneContext
## The services steps act through, on the world: the cast, Ivo, the camera's rig, the letterbox, the fade, the dialogue
## director, voices and bubbles (systems/cutscenes).

## Px over an actor's feet a bubble floats; Ivo is taller.
const ACTOR_BUBBLE_HEIGHT := 50.0
const IVO_BUBBLE_HEIGHT := 66.0
## Scaled seconds the frame takes back to Ivo at the scene's end.
const RETURN_SECONDS := 0.8
## Real seconds the scene's music fades over when the scene is skipped.
const SKIP_MUSIC_FADE := 0.8
## The name a scene's muffle is opened under (Music.muffle); the director owns it, so a quit mid-scene closes it.
const MUFFLE_ID := &"cutscene"

var cast: CutsceneCast
var _director: CutsceneDirector
var _rig: CameraRig
var _ivo_controller: ScriptedController
var _voices: Array[AudioStreamPlayer] = []
## The scene's music request; restore releases it.
var _music: MusicRequest
var _melodies: Array[MelodyPlayer] = []
var _bubbles: Array[EmoteBubble] = []
var _visuals: Array[CutsceneVisual] = []
var _blooms: Array[MemoryBloom] = []
var _frayed: Array[StoryActor] = []
## The year a CutsceneYear ran; restore settles it.
var _year: RegionYear
var _rig_used: bool = false
var _driving_ivo: bool = false
var _posed: bool = false
var _muffled: bool = false


func _init(director: CutsceneDirector, scope: Node, rig: CameraRig, ivo_controller: ScriptedController) -> void:
	_director = director
	cast = CutsceneCast.new(scope)
	_rig = rig
	_ivo_controller = ivo_controller

func point_of(id: StringName) -> Vector2:
	if id == CutsceneStep.IVO:
		return _director.ivo.global_position
	return cast.point_of(id)

func walk(id: StringName, x: float, pace: float, run: bool = false) -> CutsceneTask:
	if id == CutsceneStep.IVO:
		assert(not run, "Ivo has no scripted run")
		if not _driving_ivo:
			_driving_ivo = true
			_director.ivo_driven.emit(_ivo_controller)
		_ivo_controller.walk_to(x, pace)
		var arrived := func() -> bool:
			if _ivo_controller.is_walking():
				return false
			_director.note_ivo_turned()
			return true
		return CutsceneUntilTask.new(arrived, _ivo_controller.stop)
	var found := cast.actor(id)
	if found == null:
		return CutsceneTask.new()
	found.walk_to(x, pace, run)
	return CutsceneUntilTask.new(func() -> bool: return not is_instance_valid(found) or not found.is_walking())

func place(id: StringName, point: Vector2) -> void:
	var body := _body(id)
	if body != null:
		body.velocity = Vector2.ZERO
		body.teleport(point)

func face(id: StringName, direction: int) -> void:
	var body := _body(id)
	if body != null:
		body.face_towards(float(direction))
	if id == CutsceneStep.IVO:
		_director.note_ivo_turned()

func gesture(id: StringName, clip: StringName) -> CutsceneTask:
	var found := cast.actor(id)
	if found == null:
		return CutsceneTask.new()
	found.gesture(clip)
	return CutsceneUntilTask.new(func() -> bool: return not is_instance_valid(found) or found.is_settled())

func land_gesture(id: StringName, clip: StringName) -> void:
	var found := cast.actor(id)
	if found != null:
		found.land_gesture(clip)

func emote(id: StringName, shown: CutsceneEmote.Emote, seconds: float, height: float = 0.0) -> void:
	var target: Node2D = _director.ivo if id == CutsceneStep.IVO else cast.actor(id)
	if target == null:
		return
	var bubble := EmoteBubble.new()
	_director.add_child(bubble)
	if height <= 0.0:
		height = IVO_BUBBLE_HEIGHT if id == CutsceneStep.IVO else ACTOR_BUBBLE_HEIGHT
	bubble.show_over(target, height, shown, seconds)
	_bubbles.append(bubble)

func pose(held: DialogueBeat.Pose) -> void:
	_posed = true
	_director.ivo_posed.emit(held)

func bars(open: bool, seconds: float) -> void:
	if _director.letterbox == null:
		return
	if open:
		_director.letterbox.open(seconds)
	else:
		_director.letterbox.close(seconds)

func frame(centre: Vector2, zoom: float, seconds: float) -> void:
	var camera := _director.camera
	if camera == null:
		return
	if not _rig_used:
		_rig_used = true
		_director.stop_return()
		_rig.move_to(camera.rig_point_for(camera.shown_centre()), 0.0)
		camera.follow(_rig)
	_rig.move_to(camera.rig_point_for(centre), seconds)
	if zoom > 0.0:
		camera.zoom_to(zoom, seconds)

func talk(set: DialogueSet, at: Vector2) -> CutsceneTask:
	var dialogue := _director.dialogue
	if set == null or dialogue == null:
		return CutsceneTask.new()
	if not dialogue.start_dialogue(set.current(SaveSystem.player_data), at):
		return CutsceneTask.new()
	return CutsceneUntilTask.new(func() -> bool: return not dialogue.is_talking())

func sound(stream: AudioStream) -> CutsceneTask:
	var voice := AudioStreamPlayer.new()
	voice.stream = stream
	voice.bus = AudioBuses.SFX
	_director.add_child(voice)
	voice.play()
	_voices.append(voice)
	return CutsceneUntilTask.new(func() -> bool: return not is_instance_valid(voice) or not voice.playing)

func melody(played: Melody, count: int, voices: Array[AudioStream]) -> CutsceneTask:
	var player := MelodyPlayer.new()
	_director.add_child(player)
	player.voices = voices
	player.play(played, count)
	_melodies.append(player)
	return CutsceneUntilTask.new(func() -> bool: return not is_instance_valid(player) or not player.is_playing())

func music(cue: MusicCue, fade: float) -> void:
	if _music != null:
		Music.release(_music, fade)
		_music = null
	if cue != null:
		_music = Music.request(cue, MusicRequest.Layer.SCENE, _director)

func muffle(amount: float) -> void:
	_muffled = amount > 0.0
	if _muffled:
		Music.muffle(MUFFLE_ID, amount, _director)
	else:
		Music.unmuffle(MUFFLE_ID)

func silence() -> void:
	for voice: AudioStreamPlayer in _voices:
		if is_instance_valid(voice):
			voice.queue_free()
	_voices.clear()
	for player: MelodyPlayer in _melodies:
		if is_instance_valid(player):
			player.stop()
			player.queue_free()
	_melodies.clear()

func music_position() -> float:
	return Music.position() if Music.playing() != null else -1.0

func fade(to_black: bool, seconds: float, colour: Color = Color.BLACK) -> void:
	if _director.fade == null:
		return
	if to_black:
		_director.fade.to_colour(colour, seconds)
	else:
		_director.fade.to_clear(seconds)

func show_visual(id: StringName, alpha: float, seconds: float) -> void:
	var visual := cast.find_visual(id)
	if visual == null:
		return
	visual.fade_to(alpha, seconds)
	if not _visuals.has(visual):
		_visuals.append(visual)

func bloom(step: CutsceneBloom, centre: Vector2, seconds: float) -> void:
	var found := cast.find_bloom(step.bloom_id)
	if found == null:
		return
	found.bloom_to(step.shape, step.rect_size, step.radius, centre, step.strength, step.ring, seconds)
	if not _blooms.has(found):
		_blooms.append(found)

func fray(id: StringName, on: bool) -> void:
	var found := cast.actor(id)
	if found == null:
		return
	for child: Node in found.get_children():
		if child is CorruptionEdge:
			(child as CorruptionEdge).agitate(on)
	if on and not _frayed.has(found):
		_frayed.append(found)

func stage(staging_id: StringName, child: StringName, seconds: float) -> void:
	var staging := cast.find_staging(staging_id)
	if staging != null:
		staging.stand_in(child, seconds)

## Whether the frame was taken from Ivo and must return to him.
func took_camera() -> bool:
	return _rig_used

## Ends all the scene started but the record, the bars at once when `cut`; `clear_fade` also clears a fade it left black.
func restore(clear_fade: bool, cut: bool = false) -> void:
	for found: StoryActor in _frayed:
		if is_instance_valid(found):
			fray(found.actor_id, false)
	_frayed.clear()
	cast.release_all()
	for found: MemoryBloom in _blooms:
		if is_instance_valid(found):
			found.reset()
	_blooms.clear()
	for visual: CutsceneVisual in _visuals:
		if is_instance_valid(visual):
			visual.reset()
	_visuals.clear()
	silence()
	if _muffled:
		muffle(0.0)
	# A skip fades the scene's music out; a scene that ended lets a one-shot cue play to its end.
	music(null, SKIP_MUSIC_FADE if cut else -1.0)
	for bubble: EmoteBubble in _bubbles:
		if is_instance_valid(bubble):
			bubble.queue_free()
	_bubbles.clear()
	if _director.letterbox != null and _director.letterbox.is_open():
		_director.letterbox.close(0.0 if cut else _director.letterbox_close_seconds)
	_ivo_controller.stop()
	if _driving_ivo:
		_driving_ivo = false
		_director.ivo_driven.emit(null)
	if _posed:
		_posed = false
		_director.ivo_posed.emit(DialogueBeat.Pose.NONE)
	if _director.engraving != null:
		_director.engraving.hide_now()
	if _director.credits != null:
		_director.credits.hide_now()
	settle_year()
	if clear_fade and _director.fade != null and _director.fade.is_black():
		_director.fade.to_clear()

func engrave(frame: EngravingFrame, tint: Color, dissolve: bool) -> void:
	if _director.engraving != null and frame != null:
		_director.engraving.show_frame(frame, tint, dissolve)

func land_engraving() -> void:
	if _director.engraving != null:
		_director.engraving.land()

func clear_engraving(seconds: float) -> void:
	if _director.engraving != null:
		_director.engraving.clear(seconds)

func exit(id: StringName) -> void:
	cast.exit(id)

func roll_credits(sheet: CreditsSheet) -> void:
	if _director.credits != null:
		_director.credits.roll(sheet)

func credits_done() -> bool:
	return _director.credits == null or _director.credits.is_done()

func land_credits() -> void:
	if _director.credits != null:
		_director.credits.land()

func run_year(seconds: float) -> void:
	var field := MemoryField.find_in(_director)
	_year = field.year if field != null else null
	if _year != null:
		_year.run_year(seconds)

func settle_year() -> void:
	if _year != null and is_instance_valid(_year):
		_year.settle()
	_year = null

func _body(id: StringName) -> Character:
	if id == CutsceneStep.IVO:
		return _director.ivo
	var found: Character = cast.actor(id)
	return found if found != null else cast.find_body(id)
