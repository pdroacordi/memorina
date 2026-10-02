class_name SceneKey extends RefCounted

## Persistent scene key; a scene UID survives editor renames, with path fallback.

static func of(node: Node) -> String:
	var path := node.scene_file_path
	if path.is_empty():
		push_warning("SceneKey: %s is not an instanced scene, keyed by its node path" % node.get_path())
		return String(node.get_path())
	var uid := ResourceLoader.get_resource_uid(path)
	if uid != ResourceUID.INVALID_ID:
		return ResourceUID.id_to_text(uid)
	return path
