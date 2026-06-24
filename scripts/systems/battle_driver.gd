class_name BattleDriver
extends Node

## 5v3 战斗端到端测试
## 跑通完整回合循环，AI 自动选择攻击

const LOG_PATH := "d:/Claudeworkspace/Lordisland/.godot_cache/battle_test.log"

var _passed: int = 0
var _failed: int = 0
var _battle_ended: bool = false
var _victory: bool = false
var _exp: int = 0
var _turn_count: int = 0
var _action_count: int = 0
var ctrl: BattleController

func _ready() -> void:
	_log("=== BattleDriver ready ===")
	_run_battle_test()

func run() -> void:
	_log("=== BattleDriver.run() called ===")
	_run_battle_test()

func _log(msg: String) -> void:
	print(msg)
	var f = FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
	if f == null:
		return
	f.seek_end()
	f.store_line(msg)
	f.close()

func _run_battle_test() -> void:
	ctrl = BattleController.new()
	add_child(ctrl)
	ctrl.battle_ended.connect(_on_battle_ended)
	ctrl.actor_acted.connect(_on_actor_acted)

	# 加载 5 主角数据
	var party_data: Array = []
	for char_id in ["parn", "ehto", "slayn", "tike", "ghim"]:
		var p = FileAccess.open("res://data/characters/%s.json" % char_id, FileAccess.READ)
		party_data.append(JSON.parse_string(p.get_as_text()))

	# 3 个敌人：1 个 orc + 2 个 goblin
	ctrl.setup(party_data, ["orc", "goblin", "goblin"])

	print("\n=== 战斗开始: 5 主角 vs 3 敌人 (orc + 2 goblin) ===")
	for p in ctrl.party:
		print("  [我方] %s HP=%d MP=%d STR=%d" % [p.display_name(), p.hp, p.mp, p.str_total()])
	for e in ctrl.enemies:
		print("  [敌方] %s HP=%d MP=%d STR=%d" % [e.display_name(), e.hp, e.mp, e.str_total()])

	ctrl.start_battle()
	_log("=== Battle started, state=%d ===" % ctrl.state)

signal battle_finished

func _on_battle_ended(victory: bool, exp: int) -> void:
	_battle_ended = true
	_victory = victory
	_exp = exp
	print("\n=== 战斗结束: %s | 经验=%d | 总回合=%d | 总行动=%d ===" % [
		"胜利" if victory else "失败",
		exp, _turn_count, _action_count
	])
	_assert(victory, "玩家应该胜利（等级碾压 5v3 兽人+哥布林）")
	_assert(_exp > 0, "胜利时应该获得经验")
	_assert(_action_count > 0, "应该至少执行一次行动")
	battle_finished.emit()

func _on_actor_acted(actor: Actor, action: String, targets: Array, results: Array) -> void:
	_action_count += 1
	if actor.is_player:
		_turn_count += 1
	if _action_count <= 20 or _action_count % 10 == 0:
		_log("  [#%d] %s -> %s (targets=%d, results=%d)" % [
			_action_count, actor.display_name(), action, targets.size(), results.size()
		])

func _assert(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("PASS: %s" % msg)
	else:
		_failed += 1
		print("FAIL: %s" % msg)

# AI：每帧处理 BattleController 的状态，触发 AI 行动
func _process(_delta: float) -> void:
	if ctrl == null:
		return
	match ctrl.state:
		BattleController.State.ENEMY_TURN:
			ctrl.enemy_act.call_deferred()
		BattleController.State.PLAYER_TURN:
			_auto_player_action()
		BattleController.State.ENDED:
			if not _battle_ended:
				return
			print("\n=== 测试结果: %d passed, %d failed ===" % [_passed, _failed])
			if _failed > 0:
				get_tree().quit.call_deferred(1)
			else:
				get_tree().quit.call_deferred(0)

func _auto_player_action() -> void:
	if ctrl.current_actor == null:
		return
	# 智能 AI：
	# 1. 任何友军 HP < 50% 且当前角色能 heal → heal
	# 2. 否则：优先杀最低 HP 的敌人
	var cmds: Array = ctrl.get_player_command()
	if cmds.is_empty():
		ctrl.player_defend.call_deferred()
		return

	# 找需要治疗的友军
	var need_heal := false
	for a in ctrl.party:
		if a.is_alive and a.hp < a.max_hp * 0.5:
			need_heal = true
			break

	# 选技能
	var skill_id: String = cmds[0]
	if need_heal:
		for sid in cmds:
			var s = ctrl._skills_cache.get(sid, {})
			if s.get("type", "") == "heal":
				skill_id = sid
				break

	var skill = ctrl._skills_cache.get(skill_id, {})
	var target_idx := 0
	match skill.get("target", ""):
		"single_enemy":
			# 选 HP 最低的活敌人
			var lowest_hp := 99999
			for i in ctrl.enemies.size():
				var e = ctrl.enemies[i]
				if e.is_alive and e.hp < lowest_hp:
					lowest_hp = e.hp
					target_idx = i
		"single_ally":
			# 优先 HP 最低的活友军
			var lowest_hp := 99999
			for i in ctrl.party.size():
				var a = ctrl.party[i]
				if a.is_alive and a.hp < lowest_hp:
					lowest_hp = a.hp
					target_idx = i
		"self":
			target_idx = ctrl.party.find(ctrl.current_actor)
	ctrl.player_action.call_deferred(skill_id, target_idx)
