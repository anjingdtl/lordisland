class_name BattleTrigger
extends Node3D

## 战斗触发器：玩家踩上去开始战斗
## 战斗结束后根据胜负设置 flag

@export var enemies: Array[String] = []
@export var one_shot: bool = true
@export var trigger_flag: String = ""
@export var is_boss: bool = false
@export var event_id: String = ""  # 战斗胜利后触发的事件

var _triggered: bool = false

func on_interact() -> void:
	if _triggered and one_shot:
		return
	# 检查是否已触发过（用 flag）
	var globals = _get_globals()
	if not globals:
		return
	if trigger_flag != "" and globals.event_system.get_flag(trigger_flag) == true:
		_triggered = true
		# 已打过，移除 marker
		visible = false
		return
	# 战斗 - 简单实现：直接调用 BattleController
	_start_battle(globals)

func _start_battle(globals: Node) -> void:
	_triggered = true
	# 实例化 BattleController
	var BattleControllerScript = load("res://scripts/systems/battle_controller.gd")
	var bc = BattleControllerScript.new()
	get_tree().current_scene.add_child(bc)
	# 加载队伍
	var party_data: Array = []
	for char_id in globals.party_manager.get_member_ids():
		var d = globals.party_manager.get_member_data(char_id)
		if not d.is_empty():
			party_data.append(d)
	if party_data.is_empty():
		# fallback: 帕恩
		var f = FileAccess.open("res://data/characters/parn.json", FileAccess.READ)
		party_data.append(JSON.parse_string(f.get_as_text()))
	bc.setup(party_data, enemies)
	# 监听结束
	bc.battle_ended.connect(func(victory, exp): _on_battle_ended(victory, exp, globals))
	bc.start_battle()
	# TODO: 弹出战斗 UI

func _on_battle_ended(victory: bool, exp: int, globals: Node) -> void:
	if victory:
		if trigger_flag != "":
			globals.event_system.set_flag(trigger_flag, true)
		if is_boss and event_id != "":
			# 触发事件（救援艾特）
			globals.event_system.trigger("on_talk", "npc_ehto")
		visible = false  # 隐藏 marker
	else:
		_triggered = false  # 允许重试

func _get_globals() -> Node:
	var root = get_tree().root
	for child in root.get_children():
		if child.name == "GameGlobals":
			return child
	return null