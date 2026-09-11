class_name BruteShadow
extends Enemy
## BruteShadow doesn't exist to the player until they wander close enough.
## The actual "play the spawn animation now" decision lives entirely in the
## AnimationTree's own Start -> spawn transition (advance_expression =
## "should_spawn()", see brute_shadow.tscn) — this script only flips the flag
## that expression reads, plus handles what isn't animation-graph business:
## staying hidden/inert until then, and resuming physics once the spawn
## clip's known duration has elapsed. Not on Enemy/EnemyAI since this isn't
## true of every common enemy.

## Matches the "spawn" animation's length (brute_shadow.tscn). Timer-based
## rather than AnimationPlayer.animation_finished: that signal reflects
## direct play() calls on the AnimationPlayer, not animations driven through
## the AnimationNodeStateMachine, so it never fires for this.
@export var spawn_duration: float = 0.75

@onready var _spawn_trigger : PlayerProximityTrigger = $SpawnTrigger
@onready var _anim_tree     : AnimationTree = $AnimationTree
## Enemy already holds $AI as the generic AIController; this is a second,
## more specific reference so BruteShadow's own animation contract (below)
## can read attack state without widening AIController's generic contract.
@onready var _brute_ai      : BruteShadowAI = $AI

var _player_near: bool = false
var _spawn_timer: float = 0.0


func _ready() -> void:
	super()
	if is_queued_for_deletion():
		return
	hide()
	hurtbox.monitorable = false
	set_physics_process(false)
	set_process(false)
	_anim_tree.active = true
	_spawn_trigger.player_entered.connect(_on_player_entered)

## Only running during the spawn window (see set_process calls below) — the
## "wait for the spawn clip to finish" clock.
func _process(delta: float) -> void:
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		set_physics_process(true)
		set_process(false)

## Read by the Start -> spawn transition's advance_expression in
## brute_shadow.tscn. Renaming this or changing what it means breaks that
## transition SILENTLY, same rule as Player's animation contract.
func should_spawn() -> bool:
	return _player_near

func _on_player_entered() -> void:
	_player_near = true
	show()
	_spawn_timer = spawn_duration
	set_process(true)

#############################################
##  A N I M A T I O N   C O N T R A C T    ##
#############################################
## brute_shadow.tscn's AnimationTree calls these by NAME from
## advance_expression strings. Renaming one, or changing what it means,
## breaks animation SILENTLY at runtime — no compile error, no warning.
## Change the scene and this script together.

func should_attack() -> bool:
	return _brute_ai.is_attacking
