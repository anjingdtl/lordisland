class_name EventExecutor
extends RefCounted

## 事件执行器：把 JSON 描述的 steps 转成实际游戏行为
## 支持：
##   show_dialogue - 触发对话
##   set_flag - 设置 flag
##   join_party - 角色加入队伍
##   start_battle - 开始战斗
##   give_item - 给物品

var event_system: EventSystem
var party_manager: Node  # PartyManager（待实现）

func _init(es: EventSystem, party_mgr: Node = null) -> void:
	event_system = es
	party_manager = party_mgr

## 执行步骤列表（异步：等待对话/战斗完成）
func execute_steps(steps: Array, parent: Node) -> void:
	for step in steps:
		match step.get("type", ""):
			"show_dialogue":
				await _show_dialogue(step["id"], parent)
			"set_flag":
				event_system.set_flag(step["key"], step["value"])
			"join_party":
				_join_party(step["character"])
			"start_battle":
				await _start_battle(step["enemies"], parent)
			"give_item":
				_give_item(step["item_id"], step.get("count", 1))

func _show_dialogue(dialogue_id: String, parent: Node) -> void:
	var parser = DialogueParser.load_from_file("res://data/dialogues/%s.json" % dialogue_id)
	if parser.id == "":
		push_warning("Dialogue not found: %s" % dialogue_id)
		return
	# 程序化创建 UI 实例（避免硬依赖 .tscn）
	var DialogueUIScript = load("res://scripts/ui/dialogue_ui.gd")
	var ui: Control = DialogueUIScript.new()
	parent.add_child(ui)
	ui.start_dialogue(parser)
	# 等待完成（await 信号）
	if ui.dialogue_finished.is_connected(_noop):
		pass  # already connected
	await ui.dialogue_finished

func _noop() -> void:
	pass

func _start_battle(enemy_ids: Array, parent: Node) -> void:
	# 切换到战斗场景
	print("Starting battle with: %s" % str(enemy_ids))
	# TODO: 集成 BattleController

func _join_party(character_id: String) -> void:
	if party_manager and party_manager.has_method("add_member"):
		party_manager.add_member(character_id)
	event_system.set_flag("party_has_%s" % character_id, true)
	print("Party joined: %s" % character_id)

func _give_item(item_id: String, count: int) -> void:
	print("Got item: %s x%d" % [item_id, count])
	event_system.set_flag("item_%s" % item_id, count)

## 注册一个完整事件到 EventSystem（从 JSON 加载）
func register_from_json(path: String) -> bool:
	if not FileAccess.file_exists(path):
		push_warning("Event file not found: %s" % path)
		return false
	var f = FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	if data == null:
		return false
	# 注册触发器
	var trigger_type = data.get("trigger", "on_talk")
	var key = data.get("key", data.get("id", ""))
	var conditions = data.get("conditions", [])
	var steps = data.get("steps", [])
	# 闭包：捕获 self 和 steps 和 parent
	var callback = func(_ctx): _run_steps_later(steps)
	event_system.register(trigger_type, key, callback, conditions)
	return true

func _run_steps_later(steps: Array) -> void:
	# 找一个 parent 节点
	var ml = Engine.get_main_loop()
	var parent: Node = null
	if ml is SceneTree:
		parent = (ml as SceneTree).current_scene
		if parent == null:
			parent = (ml as SceneTree).root
	if parent == null:
		push_warning("No parent scene to execute event steps")
		return
	_run_steps_async(steps, parent)

func _run_steps_async(steps: Array, parent: Node) -> void:
	await execute_steps(steps, parent)