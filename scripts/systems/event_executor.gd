class_name EventExecutor
extends RefCounted

## 事件执行器：把 JSON 描述的 steps 转成实际游戏行为
## 非阻塞 step 同步执行；阻塞 step（对话/战斗）异步等待
## 支持：
##   show_dialogue - 触发对话
##   set_flag - 设置 flag
##   join_party - 角色加入队伍
##   start_battle - 开始战斗
##   give_item - 给物品

const DialogueParserScript = preload("res://scripts/systems/dialogue_parser.gd")

var event_system: RefCounted
var party_manager: Object

func _init(es: RefCounted, party_mgr: Object = null) -> void:
	event_system = es
	party_manager = party_mgr

## 同步执行所有非阻塞 step
func execute_steps_sync(steps: Array) -> void:
	for step in steps:
		match step.get("type", ""):
			"set_flag":
				event_system.set_flag(step["key"], step["value"])
			"join_party":
				_join_party(step["character"])
			"give_item":
				_give_item(step["item_id"], step.get("count", 1))
			"show_dialogue":
				# 同步启动对话（不等待）
				_start_dialogue(step["id"])
			"start_battle":
				_start_battle(step["enemies"])
			_:
				push_warning("Unknown step type: %s" % step.get("type", ""))

## 异步执行：同步 part + 异步 part（阻塞 step）
func execute_steps(steps: Array, parent: Node) -> void:
	# 先同步
	var sync_steps: Array = []
	var async_steps: Array = []
	for step in steps:
		if step.get("type", "") in ["show_dialogue", "start_battle"]:
			async_steps.append(step)
		else:
			sync_steps.append(step)
	# 同步部分
	execute_steps_sync(sync_steps)
	# 异步部分（按顺序执行）
	for step in async_steps:
		match step.get("type", ""):
			"show_dialogue":
				await _show_dialogue(step["id"], parent)
			"start_battle":
				await _start_battle_async(step["enemies"], parent)

func _join_party(character_id: String) -> void:
	if party_manager and party_manager.has_method("add_member"):
		party_manager.add_member(character_id)
	event_system.set_flag("party_has_%s" % character_id, true)
	print("Party joined: %s" % character_id)

func _give_item(item_id: String, count: int) -> void:
	print("Got item: %s x%d" % [item_id, count])
	event_system.set_flag("item_%s" % item_id, count)

func _start_dialogue(dialogue_id: String) -> void:
	# 立即创建 DialogueUI（不等待完成）
	var parser = DialogueParserScript.load_from_file("res://data/dialogues/%s.json" % dialogue_id)
	if parser.id == "":
		return
	var ml = Engine.get_main_loop()
	var parent: Node = null
	if ml is SceneTree:
		parent = (ml as SceneTree).current_scene
		if parent == null:
			parent = (ml as SceneTree).root
	if parent == null:
		return
	var DialogueUIScript = load("res://scripts/ui/dialogue_ui.gd")
	var ui: Control = DialogueUIScript.new()
	parent.add_child(ui)
	ui.start_dialogue(parser)

func _show_dialogue(dialogue_id: String, parent: Node) -> void:
	var parser = DialogueParserScript.load_from_file("res://data/dialogues/%s.json" % dialogue_id)
	if parser.id == "":
		return
	var DialogueUIScript = load("res://scripts/ui/dialogue_ui.gd")
	var ui: Control = DialogueUIScript.new()
	parent.add_child(ui)
	ui.start_dialogue(parser)
	await ui.dialogue_finished

func _start_battle(enemy_ids: Array) -> void:
	print("Starting battle with: %s" % str(enemy_ids))

func _start_battle_async(enemy_ids: Array, parent: Node) -> void:
	# TODO: 集成 BattleController
	pass

## 注册一个完整事件到 EventSystem（从 JSON 加载）
func register_from_json(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var f = FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	if data == null:
		return false
	var trigger_type = data.get("trigger", "on_talk")
	var key = data.get("key", data.get("id", ""))
	var conditions = data.get("conditions", [])
	var steps = data.get("steps", [])
	var self_ref = self
	# 闭包：捕获 self 和 steps
	var callback = func(_ctx): self_ref._on_event_triggered(steps)
	event_system.register(trigger_type, key, callback, conditions)
	return true

func _on_event_triggered(steps: Array) -> void:
	# 同步执行（不等待阻塞 step）
	execute_steps_sync(steps)
	# 异步执行（启动对话/战斗，不阻塞触发器）
	for step in steps:
		match step.get("type", ""):
			"show_dialogue":
				_start_dialogue(step["id"])
			"start_battle":
				_start_battle(step["enemies"])
