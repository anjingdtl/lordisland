class_name Chest
extends Node3D

## 宝箱：拾取后给物品，一次性

@export var item_id: String = "heal_potion"
@export var item_count: int = 1
@export var open_flag: String = ""
@export var message_key: String = "chest_heal_potion_msg"

var _opened: bool = false

func _ready() -> void:
	if open_flag != "":
		var globals = _get_globals()
		if globals and globals.event_system:
			if globals.event_system.get_flag(open_flag) == true:
				_opened = true
				visible = false

func on_interact() -> void:
	if _opened:
		return
	_opened = true
	var globals = _get_globals()
	if globals:
		var msg = TranslationServer.translate(message_key)
		print(msg)
		if globals.event_system:
			globals.event_system.set_flag("item_%s" % item_id, item_count)
			if open_flag != "":
				globals.event_system.set_flag(open_flag, true)
	visible = false

func _get_globals() -> Node:
	var root = get_tree().root
	for child in root.get_children():
		if child.name == "GameGlobals":
			return child
	return null