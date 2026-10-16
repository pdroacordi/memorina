class_name CutsceneCast
extends RefCounted
## The actors, marks and visuals a cutscene names, found by id inside its host's contents scene (systems/cutscenes).
## An actor enters on its first step; `release_all()` hands every entered actor's place back to its staging.

## The host's contents scene root: ids resolve under it only, so neighbour rooms' ids stay apart.
var _scope: Node
var _entered: Array[StoryActor] = []


func _init(scope: Node) -> void:
	_scope = scope

## The node of `group` under `scope` whose `property` is `id`; null when none is.
static func find_in(scope: Node, group: StringName, property: StringName, id: StringName) -> Node:
	if scope == null or not scope.is_inside_tree():
		return null
	for node: Node in scope.get_tree().get_nodes_in_group(group):
		if (node == scope or scope.is_ancestor_of(node)) and node.get(property) == id:
			return node
	return null

func find_actor(id: StringName) -> StoryActor:
	return find_in(_scope, StoryActor.GROUP, &"actor_id", id) as StoryActor

func find_mark(id: StringName) -> CutsceneMark:
	return find_in(_scope, CutsceneMark.GROUP, &"mark_id", id) as CutsceneMark

func find_visual(id: StringName) -> CutsceneVisual:
	return find_in(_scope, CutsceneVisual.GROUP, &"visual_id", id) as CutsceneVisual

## The actor `id`, entered on first use; null when the contents have none.
func actor(id: StringName) -> StoryActor:
	var found := find_actor(id)
	if found != null and not _entered.has(found):
		found.enter()
		_entered.append(found)
	return found

## Where `id` stands: an entered actor's feet, an actor's rest child before it enters, a mark or a visual.
func point_of(id: StringName) -> Vector2:
	var found := find_actor(id)
	if found != null:
		if _entered.has(found):
			return found.global_position
		var rest := found.rest_child()
		return rest.global_position if rest != null else found.global_position
	var mark := find_mark(id)
	if mark != null:
		return mark.global_position
	var visual := find_visual(id)
	if visual != null:
		return visual.global_position
	push_error("Cutscene: no actor, mark or visual '%s' in %s" % [id, _scope.name if _scope != null else "nothing"])
	return Vector2.ZERO

func entered() -> Array[StoryActor]:
	return _entered

## Every entered actor's staging shows its rest at once and the actor leaves; the stagings first, so no frame shows
## neither.
func release_all() -> void:
	for found: StoryActor in _entered:
		if is_instance_valid(found) and found.staging() != null:
			found.staging().uncover()
	for found: StoryActor in _entered:
		if is_instance_valid(found):
			found.leave()
	_entered.clear()
