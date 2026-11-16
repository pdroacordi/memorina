class_name IvoSoundSet
extends Resource
## Ivo's body sounds, played by IvoSounds (systems/sound-effects).

## Step and soft landing by Enums.Surface; a surface with no entry is silent.
@export var surfaces: Dictionary[int, SurfaceSounds] = {}
@export var land_hard: SoundCue
@export var jump: SoundCue
@export var double_jump: SoundCue
@export var climb_grab: SoundCue
@export var climb_step: SoundCue
@export var swing: SoundCue
@export var hurt: SoundCue
@export var death: SoundCue
## Sitting down on a bench himself; an arrival's sit is silent.
@export var rest: SoundCue
## Taking a door, by Door look; every look has an entry and a null one is silent (ivo_sounds_test).
@export var door_open: Dictionary[String, SoundCue] = {}
## Arriving through the partner door, by its look; same keys as `door_open`.
@export var door_close: Dictionary[String, SoundCue] = {}
## Up at a sealed door.
@export var door_knock: SoundCue
## Taking something, by Player.Taken; a kind with no entry is silent.
@export var taken: Dictionary[int, SoundCue] = {}
## px/s; a slower landing (a step down) is silent.
@export var soft_land_min_speed: float = 200.0
## px/s at which a soft landing sounds at full level; Ivo's hard_land_speed.
@export var soft_land_full_speed: float = 800.0


## The sounds of `surface`, or null when it is silent.
func surface(which: Enums.Surface) -> SurfaceSounds:
	return surfaces.get(which) as SurfaceSounds
