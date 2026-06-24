class_name NPCNode
extends Node3D

## NPC 节点：可对话
## 玩家靠近按 E 触发

@export var npc_id: String
@export var dialogue_id: String
@export var event_id: String = ""

func on_interact() -> void:
	# 1. 触发对话
	if dialogue_id != "":
		var parser = DialogueParser.load_from_file("res://data/dialogues/%s.json" % dialogue_id)
		if parser.id != "":
			var DialogueUI = load("res://scripts/ui/dialogue_ui.gd")
			var ui: Control = DialogueUI.new()
			var parent = get_tree().current_scene
			if parent == null:
				parent = get_tree().root
			parent.add_child(ui)
			ui.start_dialogue(parser)
	# 2. 触发事件
	if event_id != "":
		# 注册（懒加载） + 触发
		var globals = _get_globals()
		if globals and globals.event_system:
			if not globals.event_system.listeners.has("on_talk"):
				# 注册默认事件
				var exec = EventExecutor.new(globals.event_system, globals.party_manager)
				exec.register_from_json("res://data/events/%s.json" % event_id)
			globals.event_system.trigger("on_talk", npc_id)

func _get_globals() -> Node:
	# GameGlobals 是 autoload
	var root = get_tree().root
	for child in root.get_children():
		if child.name == "GameGlobals":
			return child
	return null