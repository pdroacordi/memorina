class_name BearerFragment
extends Resource
## One bearer fragment: the guardian whose tube holds it, the song that wakes it, its three scenes, its music and where
## Ivo stands on the stage (architecture/story-04-bearer-fragments).

@export var guardian: Enums.Guardian = Enums.Guardian.FROST
## That guardian's `GuardianStats.song`; a world performance of it arms the fragment.
@export var song: Song
## Played in the room Ivo stands in; not skippable, its recorded end covered in the paper colour.
@export var call: Cutscene
## Played on the stage; id BearerSchedule.id(guardian), so its record is the fragment seen.
@export var engraving: Cutscene
## Played where Ivo stood before the fragment; not skippable, it names only Ivo.
@export var returning: Cutscene
## Asked at SCENE layer from the travel to the stage to the returning scene's end.
@export var music: MusicCue
## The stage room's id (Room.id(), its scene file name).
@export var stage_room: StringName = &"bearer_stage"
## Where Ivo's feet land, px from the stage room's top-left corner.
@export var arrival: Vector2 = Vector2(320, 288)
@export_enum("West:-1", "East:1") var arrival_facing: int = 1
