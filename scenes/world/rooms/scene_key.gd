class_name SceneKey extends RefCounted

## How the save names a place - a region, a room - so the name outlives the
## session: the uid of the scene it was instanced from, falling back to the
## scene's path. A uid survives a rename made in the editor, so an old save
## still finds its bench and its death marks after the files move.

static func of(node: Node) -> String:
	var path := node.scene_file_path
	if path.is_empty():
		push_warning("SceneKey: %s is not an instanced scene, keyed by its node path" % node.get_path())
		return String(node.get_path())
	var uid := ResourceLoader.get_resource_uid(path)
	if uid != ResourceUID.INVALID_ID:
		return ResourceUID.id_to_text(uid)
	return path
