class_name DialogueBeat
extends Node
## A scripted beat a line's `cue` hands the talk to: the box closes, Ivo is held as `hold` says, and the talk resumes at
## `finished` (systems/dialogue, systems/story). A scene composes one and calls `finish()` when its beat is over.

signal started
signal finished
## A Memorina note input reached the beat (hold NOTES).
signal note_received(note: Enums.Note, glyph_set: Enums.GlyphSet)
## The beat shows `count` notes of `notes` on the phrase sheet (dimmed), in `glyph_set`'s glyphs.
signal phrase_shown(notes: Array[Enums.Note], count: int, glyph_set: Enums.GlyphSet)
## Note `index` of the shown phrase sounded.
signal phrase_lit(index: int)
signal phrase_closed
## The beat gave up before its end: the talk ends unheard (a swing let fall, flashback 3).
signal abandoned
## Ivo holds `pose` (Pose) from now, still held as `hold` says.
signal pose_changed(pose: int)

const GROUP := &"dialogue_beats"

## FREE: Ivo moves. STILL: he hears nothing. NOTES: only the four note inputs reach the beat. HELD_UP: only whether Up is
## held reaches it, read through `Player.up_held()`. Append only: scenes store these as ints.
enum Hold { FREE, STILL, NOTES, HELD_UP }
## What Ivo holds from the beat's start until the next beat or the talk's end; SEATED (STORY-16) sits him where he
## stands, the bench's clip; the last four are the flashbacks' (STORY-05). Append only: scenes store these as ints.
enum Pose { NONE, GUITAR, MEMORINA, SEATED, KNEEL, SIT_GROUND, PUSH_SWING, RIBBON }

## Matches a DialogueLine's `cue`.
@export var cue: StringName = &""
@export var hold: Hold = Hold.STILL
@export var pose: Pose = Pose.NONE
## What Ivo turns to as the beat starts and keeps facing for the rest of the talk; empty keeps what he faces.
@export var face: NodePath

## Who the talk is held for (DialogueDirector.listener), set before `start()`; null outside a talk.
var listener: Node2D


## The beat for `cue` in the tree; null when none is loaded.
static func find(tree: SceneTree, wanted: StringName) -> DialogueBeat:
	for node: Node in tree.get_nodes_in_group(GROUP):
		var beat := node as DialogueBeat
		if beat != null and beat.cue == wanted:
			return beat
	return null

func _enter_tree() -> void:
	add_to_group(GROUP)

## The world point Ivo faces during the beat; `fallback` when `face` names nothing.
func face_point(fallback: Vector2) -> Vector2:
	var target := get_node_or_null(face) as Node2D if not face.is_empty() else null
	return target.global_position if target != null else fallback

## Where Ivo faces when the talk resumes and to its end: the point the beat started facing, unless the beat turned him.
func face_after(facing: Vector2) -> Vector2:
	return facing

func start() -> void:
	started.emit()

## A note input from Ivo; the director passes it on only while this beat holds NOTES.
func receive_note(note: Enums.Note, glyph_set: Enums.GlyphSet) -> void:
	note_received.emit(note, glyph_set)

func finish() -> void:
	finished.emit()

func abandon() -> void:
	abandoned.emit()

## Changes what Ivo holds mid-beat (the push given, he stands to hear her).
func change_pose(to: Pose) -> void:
	pose_changed.emit(to)
