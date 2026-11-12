class_name AlbaAnimationResolver
extends StoryAnimationResolver
## Alba's clips. Each rest clip is named like the `Alba` staging child it stands for (systems/cutscenes).

const STANDING := &"standing"
const WALK := &"walk"
const SIT := &"sit"
const SEATED := &"seated"
const SIT_SING := &"sit_sing"
const PICK := &"pick"
const PICKED := &"picked"
const CHEST := &"chest"
const RISEN := &"risen"
const TURN := &"turn"
const TURNED := &"turned"
const RIBBON := &"ribbon"
const HOLDING_OUT := &"holding_out"
const LULLABY := &"lullaby"
const STONE := &"stone"
const FLOWERS := &"flowers"
const SWING := &"swing"
const POOL_BACK := &"pool_back"
const TREE_WITH_DAUGHTER := &"tree_with_daughter"

const CLIPS: Array[StringName] = [
	STANDING, WALK, SIT, SEATED, SIT_SING, PICK, PICKED, CHEST, RISEN, TURN, TURNED, RIBBON, HOLDING_OUT, LULLABY,
	STONE, FLOWERS, SWING, POOL_BACK, TREE_WITH_DAUGHTER,
]
## The rest clips, one per child of the past garden's `Alba` staging.
const RESTS: Array[StringName] = [STONE, FLOWERS, SWING, POOL_BACK, TREE_WITH_DAUGHTER]
const SETTLES: Dictionary[StringName, StringName] = {
	SIT: SEATED,
	PICK: PICKED,
	CHEST: RISEN,
	TURN: TURNED,
	RIBBON: HOLDING_OUT,
}


func clips() -> Array[StringName]:
	return CLIPS

func settles() -> Dictionary[StringName, StringName]:
	return SETTLES

func walk_clip() -> StringName:
	return WALK

func idle_clip() -> StringName:
	return STANDING
