@tool
class_name HelixStairShape extends Resource

## The numbers a helix stair turns, is ridden and is drawn by (architecture/walkable-helix-stair, Revision).

## Px from the axis to the shell's inner wall.
@export var wall_radius := 144.0
## Px from the axis to Ivo's plane: the front of the stair, where he rides.
@export var walk_radius := 96.0
## Px from the axis to the steps' inner edge (the open well).
@export var inner_radius := 48.0
## Px the stair rises per full turn.
@export var pitch := 320.0
## Full turns from foot to head.
@export var turns := 3.5
## Steps per full turn; each rises pitch / steps_per_turn px.
@export var steps_per_turn := 32
## Px from the axis to the eye that sees the turning tower; sets the perspective.
@export var eye_distance := 750.0
## Multiplies the rider's run speed into the speed of the front tread under him.
@export var speed_scale := 1.0


## Px from the foot to the head.
func head_rise() -> float:
	return pitch * turns

## Px each step rises.
func riser() -> float:
	return pitch / steps_per_turn

func step_count() -> int:
	return roundi(steps_per_turn * turns)

## Why these numbers cannot make a stair, as messages; empty when they can.
func problems() -> PackedStringArray:
	var found := PackedStringArray()
	if not (inner_radius > 0.0 and inner_radius < walk_radius and walk_radius < wall_radius and wall_radius < eye_distance):
		found.append("radii must grow: 0 < inner_radius < walk_radius < wall_radius < eye_distance")
	if pitch <= 0.0 or turns <= 0.0:
		found.append("pitch and turns must be positive")
	elif absf(head_rise() - roundf(head_rise() / RoomMap.CELL_PX) * RoomMap.CELL_PX) > 0.01:
		found.append("the head rise (pitch x turns, %.1f px) must be a multiple of %d px" % [head_rise(), RoomMap.CELL_PX])
	if steps_per_turn < 8:
		found.append("steps_per_turn must be at least 8")
	elif turns > 0.0 and absf(steps_per_turn * turns - step_count()) > 0.001:
		# The head is the last tread's top only when the steps end there (HelixMath.stand).
		found.append("steps_per_turn x turns (%.2f) must be a whole number of steps" % (steps_per_turn * turns))
	if speed_scale <= 0.0:
		found.append("speed_scale must be positive")
	return found
