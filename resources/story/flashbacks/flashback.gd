class_name Flashback
extends Resource
## One flashback's visit: the four scenes FlashbackDirector runs in order, its music and where Ivo lands in the past
## (architecture/story-05-playable-flashbacks).

## 1..FlashbackSchedule.COUNT; the leaving scene's id is FlashbackSchedule.id(number).
@export var number: int = 1
## Played in the present by a trigger or a beat; its recorded end begins the visit.
@export var crossing: Cutscene
## Played by FlashbackDirector in the past room once Ivo lands there.
@export var opening: Cutscene
## Played in the past by its contents; its recorded end takes Ivo back, under the black it leaves.
@export var leaving: Cutscene
## Played by FlashbackDirector where Ivo stood before the visit; it names only Ivo.
@export var returning: Cutscene
## Asked at SCENE layer from the crossing's end to the returning scene's end.
@export var music: MusicCue
## Seconds into `music` the travel into the past waits for.
@export var entry_mark: float = 0.0
## Seconds of the white cover before the travel into the past; 0 cuts.
@export var entry_fade: float = 0.5
## Px of each letterbox bar while Ivo is in the past, 0..Letterbox.bar_height.
@export var bars_thin: float = 0.0
## The past room's id (Room.id(), its scene file name).
@export var past_room: StringName = &"garden_past"
## Where Ivo's feet land, px from the past room's top-left corner.
@export var arrival: Vector2 = Vector2.ZERO
@export_enum("West:-1", "East:1") var arrival_facing: int = 1
