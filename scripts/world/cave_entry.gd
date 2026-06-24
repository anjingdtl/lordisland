class_name CaveEntry
extends Node3D

## 洞窟入口：玩家按 E 回到洛奈城

@export var target_scene: String = "res://scenes/world/loranai_city.tscn"

func on_interact() -> void:
	get_tree().change_scene_to_file(target_scene)