class_name SceneManager
extends RefCounted

## 场景管理器：负责场景切换

func change_to(scene_path: String) -> void:
	var tree = Engine.get_main_loop()
	if tree is SceneTree:
		(tree as SceneTree).change_scene_to_file(scene_path)

func get_current_scene_path() -> String:
	var tree = Engine.get_main_loop()
	if tree is SceneTree:
		var cur = (tree as SceneTree).current_scene
		if cur:
			return cur.scene_file_path
	return ""