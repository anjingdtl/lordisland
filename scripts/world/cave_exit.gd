class_name CaveExit
extends Node3D

## 洞窟出口：玩家按 E 切换场景

@export var target_scene: String = "res://scenes/world/starting_cave.tscn"

func on_interact() -> void:
	print("Entering cave...")
	var globals = _get_globals()
	if globals and globals.scene_manager:
		globals.scene_manager.change_to(target_scene)
	else:
		# fallback
		get_tree().change_scene_to_file(target_scene)

func _get_globals() -> Node:
	var root = get_tree().root
	for child in root.get_children():
		if child.name == "GameGlobals":
			return child
	return null