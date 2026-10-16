class_name CutsceneRoomsTest extends GdUnitTestSuite

## Every cutscene a contents scene starts (a CutsceneBeat or a CutsceneTrigger) names only ids that resolve in that
## contents scene and gestures its actors have; a beat holds STILL and its scene holds no talk of its own; every staging
## child an actor stands for has a clip.

const ROOMS := "res://scenes/world/rooms"


func _contents(dir: String) -> PackedStringArray:
	var found := PackedStringArray()
	for sub: String in DirAccess.get_directories_at(dir):
		found.append_array(_contents(dir.path_join(sub)))
	for file: String in DirAccess.get_files_at(dir):
		if file.ends_with("_contents.tscn") or (dir == ROOMS and file.begins_with("trials_") and file.ends_with(".tscn")):
			found.append(dir.path_join(file))
	return found

func _descendants(node: Node) -> Array[Node]:
	var found: Array[Node] = [node]
	for child: Node in node.get_children():
		found.append_array(_descendants(child))
	return found

func test_every_scene_names_ids_its_contents_hold() -> void:
	var problems := PackedStringArray()
	var hosts := 0
	for path: String in _contents(ROOMS):
		var root := (load(path) as PackedScene).instantiate()
		var ids: Array[StringName] = [CutsceneStep.IVO]
		var actors: Array[StoryActor] = []
		var starts: Array[Node] = []
		for node: Node in _descendants(root):
			if node is StoryActor:
				var actor := node as StoryActor
				ids.append(actor.actor_id)
				actors.append(actor)
			elif node is CutsceneMark:
				ids.append((node as CutsceneMark).mark_id)
			elif node is CutsceneVisual:
				ids.append((node as CutsceneVisual).visual_id)
			elif node is FactStaging and (node as FactStaging).staging_id != &"":
				ids.append((node as FactStaging).staging_id)
			if node is CutsceneBeat or node is CutsceneTrigger:
				starts.append(node)
		for id: StringName in ids:
			if ids.count(id) > 1:
				problems.append("%s: id '%s' names two nodes" % [path.get_file(), id])
		for start: Node in starts:
			hosts += 1
			if start is CutsceneBeat and (start as CutsceneBeat).hold != DialogueBeat.Hold.STILL:
				problems.append("%s: %s does not hold STILL" % [path.get_file(), start.name])
			var scene: Cutscene = start.get(&"cutscene")
			if scene == null:
				problems.append("%s: %s has no cutscene" % [path.get_file(), start.name])
				continue
			for leaf: CutsceneStep in CutsceneCatalog.leaves(scene.steps):
				for id: StringName in leaf.names():
					if not ids.has(id):
						problems.append("%s: '%s' names '%s', not in its contents" % [path.get_file(), scene.id, id])
				if start is CutsceneBeat and leaf is CutsceneTalk:
					problems.append("%s: '%s' is played from a beat and holds a talk" % [path.get_file(), scene.id])
				if leaf is CutsceneGesture:
					var gesture := leaf as CutsceneGesture
					var by := _actor(actors, gesture.actor)
					var resolver := by.get_node("AnimationResolver") as StoryAnimationResolver if by != null else null
					if resolver == null or not resolver.clips().has(gesture.clip):
						problems.append("%s: '%s' asks '%s' for '%s', a clip it does not have" % [path.get_file(), scene.id,
								gesture.actor, gesture.clip])
		for actor: StoryActor in actors:
			var staging := actor.get_node_or_null(actor.stands_for) as FactStaging
			var resolver := actor.get_node("AnimationResolver") as StoryAnimationResolver
			if staging == null:
				problems.append("%s: actor '%s' stands for no FactStaging" % [path.get_file(), actor.actor_id])
				continue
			for child: Node in staging.get_children():
				var clip := StringName(String(child.name).to_snake_case())
				if not resolver.clips().has(clip):
					problems.append("%s: '%s' has no clip for %s" % [path.get_file(), actor.actor_id, child.name])
		root.free()
	assert_array(Array(problems)).is_empty()
	assert_int(hosts).is_greater_equal(1)

func _actor(actors: Array[StoryActor], id: StringName) -> StoryActor:
	for actor: StoryActor in actors:
		if actor.actor_id == id:
			return actor
	return null

## Every catalog scene is started somewhere, and every started scene is in the catalog.
func test_the_catalog_and_the_rooms_agree() -> void:
	var catalog := load("res://resources/cutscene/cutscene_catalog.tres") as CutsceneCatalog
	var started: Array[StringName] = []
	for path: String in _contents(ROOMS):
		var root := (load(path) as PackedScene).instantiate()
		for node: Node in _descendants(root):
			if node is CutsceneBeat or node is CutsceneTrigger:
				var scene: Cutscene = node.get(&"cutscene")
				if scene != null:
					started.append(scene.id)
					assert_object(catalog.find(scene.id)).override_failure_message(String(scene.id)).is_not_null()
		root.free()
	for scene: Cutscene in catalog.scenes:
		assert_bool(started.has(scene.id)).override_failure_message(String(scene.id)).is_true()
