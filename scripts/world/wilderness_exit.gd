class_name WildernessExit
extends Node3D

## 野外地图双向出口

@export var target_scene: String = "res://scenes/world/loranai_wilderness.tscn"
@export var target_marker: String = ""

func on_interact() -> void:
	get_tree().change_scene_to_file(target_scene)