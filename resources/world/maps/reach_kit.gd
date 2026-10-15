class_name ReachKit extends Resource

## One stage of the journey: the milestones held there, read through the save's own facts (SaveFact.check), so a gate
## opens for a kit exactly when it would for a save holding the same (architecture/room-reachability-audit, TECH-08).

## A packed fact no kit holds: the need of a gate that never opens.
const NEVER := -1

@export var id: StringName
@export var milestones: Array[ReachMilestone] = []

var _data: PlayerData

## Dialogue and choice ids a need names, by the index it packs (DIALOGUE_HEARD, RESPONSE_CHOSEN).
static var _ids: Array[StringName] = []

## A need packs one save fact as `kind << 8 | index`; a fact that reads an id packs the id's place in `_ids`.
static func fact(kind: SaveFact.Kind, index: int) -> int:
	return (kind << 8) | index

## The need of a gate that `facts` open together; no facts is a gate that never opens (a FactBarrier without `requires`).
static func opened_by(facts: Array[SaveFact]) -> PackedInt32Array:
	var need := PackedInt32Array()
	for save_fact: SaveFact in facts:
		need.append(of(save_fact))
	if need.is_empty():
		need.append(NEVER)
	return need

static func song(which: Enums.Song) -> int:
	return fact(SaveFact.Kind.SONG, which)

static func of(save_fact: SaveFact) -> int:
	if _reads_an_id(save_fact.kind):
		if not _ids.has(save_fact.id):
			_ids.append(save_fact.id)
		return fact(save_fact.kind, _ids.find(save_fact.id))
	return fact(save_fact.kind, save_fact.index)

## The flags a save holding every milestone would have.
func player_data() -> PlayerData:
	if _data != null:
		return _data
	_data = PlayerData.new()
	for milestone: ReachMilestone in milestones:
		for skill: Enums.PlayerSkill in milestone.skills:
			_data.unlocked_player_skills[skill] = true
		for which: Enums.Song in milestone.songs:
			_data.learned_songs[which] = true
		for item: Enums.PlayerItem in milestone.items:
			_data.owned_items[item] = true
		for guardian: Enums.Guardian in milestone.restored_guardians:
			_data.restored_guardians[guardian] = true
			_data.met_guardians[guardian] = true
		for dialogue: StringName in milestone.dialogues:
			if not _data.dialogues_heard.has(dialogue):
				_data.dialogues_heard.append(dialogue)
	return _data

## Whether every packed fact in `need` holds; an empty need always does, NEVER never does.
func holds(need: PackedInt32Array) -> bool:
	var data := player_data()
	for packed: int in need:
		if packed == NEVER:
			return false
		var kind := (packed >> 8) as SaveFact.Kind
		var index := packed & 255
		var fact_id: StringName = _ids[index] if _reads_an_id(kind) else &""
		if not SaveFact.check(kind, 0 if _reads_an_id(kind) else index, data, fact_id):
			return false
	return true

func has_skill(skill: Enums.PlayerSkill) -> bool:
	return player_data().unlocked_player_skills[skill]

func has(milestone: ReachMilestone) -> bool:
	return milestone in milestones

static func _reads_an_id(kind: SaveFact.Kind) -> bool:
	return kind == SaveFact.Kind.DIALOGUE_HEARD or kind == SaveFact.Kind.RESPONSE_CHOSEN
