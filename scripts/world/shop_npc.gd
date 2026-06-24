class_name ShopNPC
extends Node3D

## 商店 NPC：玩家按 E 打开商店 UI

@export var shop_id: String = "loranai_shop"

func on_interact() -> void:
	var ShopUI = load("res://scripts/ui/shop_ui.gd")
	var ui: Control = ShopUI.new()
	var parent = get_tree().current_scene
	if parent == null:
		parent = get_tree().root
	parent.add_child(ui)
	ui.closed.connect(func(): ui.queue_free())