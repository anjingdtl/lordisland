class_name BattleController
extends Node

## 战斗控制器
## 状态机：INTRO -> PLAYER_TURN / ENEMY_TURN -> ANIMATING -> ENDED
## 信号驱动 UI 更新

signal battle_started
signal turn_started(actor: Actor)
signal actor_acted(actor: Actor, action: String, targets: Array, results: Array)
signal actor_damaged(target: Actor, amount: int, is_crit: bool)
signal actor_healed(target: Actor, amount: int)
signal actor_died(actor: Actor)
signal battle_ended(victory: bool, exp_gained: int)
signal ui_state_changed(state: int)

enum State {
	INTRO,
	PLAYER_TURN,
	ENEMY_TURN,
	ANIMATING,
	ENDED
}

const BattleFormula = preload("res://scripts/systems/battle_formula.gd")

var state: int = State.INTRO
var party: Array[Actor] = []
var enemies: Array[Actor] = []
var turn_queue: Array[Actor] = []
var current_actor: Actor = null
var turn_index: int = 0
var total_exp_gained: int = 0

# 缓存加载的技能/敌人数据
var _skills_cache: Dictionary = {}
var _enemies_cache: Dictionary = {}

func setup(party_data: Array, enemy_ids: Array) -> void:
	_skills_cache = _load_json("res://data/skills.json")
	_enemies_cache = _load_json("res://data/enemies.json")
	for pd in party_data:
		var a = Actor.new(pd)
		a.is_player = true
		party.append(a)
	for eid in enemy_ids:
		var ed = _enemies_cache.get(eid, {})
		if not ed.is_empty():
			enemies.append(Actor.new(ed))

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("JSON not found: %s" % path)
		return {}
	var f = FileAccess.open(path, FileAccess.READ)
	var text = f.get_as_text()
	var parsed = JSON.parse_string(text)
	if parsed == null:
		push_error("JSON parse error in %s" % path)
		return {}
	return parsed

func start_battle() -> void:
	state = State.INTRO
	battle_started.emit()
	_build_turn_queue()
	_next_turn()

func _build_turn_queue() -> void:
	turn_queue.clear()
	var all: Array[Actor] = []
	all.append_array(party)
	all.append_array(enemies)
	# 按 agi 降序排，速度相同时按 agi_total
	all.sort_custom(func(a: Actor, b: Actor): return a.agi_total() > b.agi_total())
	turn_queue = all
	turn_index = 0

func _next_turn() -> void:
	while turn_index < turn_queue.size():
		current_actor = turn_queue[turn_index]
		turn_index += 1
		if current_actor.is_alive:
			break
		current_actor = null
	if current_actor == null or not _any_alive_in(party) or not _any_alive_in(enemies):
		_finish_battle()
		return
	if current_actor.is_player:
		state = State.PLAYER_TURN
	else:
		state = State.ENEMY_TURN
	turn_started.emit(current_actor)
	ui_state_changed.emit(state)

func _any_alive_in(group: Array[Actor]) -> bool:
	for a in group:
		if a.is_alive:
			return true
	return false

func _finish_battle() -> void:
	state = State.ENDED
	var victory := _any_alive_in(party) and not _any_alive_in(enemies)
	if victory:
		total_exp_gained = 0
		for e in enemies:
			total_exp_gained += e.exp_reward
	battle_ended.emit(victory, total_exp_gained)
	ui_state_changed.emit(state)

## 玩家行动：选 skill + target
func player_action(skill_id: String, target_idx: int) -> void:
	if state != State.PLAYER_TURN:
		return
	var actor := current_actor
	var skill = _skills_cache.get(skill_id, {})
	if skill.is_empty():
		return
	if actor.mp < skill.get("mp_cost", 0):
		return
	# 选目标
	var targets: Array[Actor] = []
	match skill.get("target", ""):
		"single_enemy":
			if target_idx >= 0 and target_idx < enemies.size():
				var t = enemies[target_idx]
				if t.is_alive:
					targets.append(t)
		"single_ally":
			if target_idx >= 0 and target_idx < party.size():
				var t = party[target_idx]
				if t.is_alive:
					targets.append(t)
		"self":
			targets.append(actor)
		"all_enemies":
			for e in enemies:
				if e.is_alive:
					targets.append(e)
		"all_allies":
			for p in party:
				if p.is_alive:
					targets.append(p)
	if targets.is_empty():
		return
	# 扣 MP
	actor.mp -= skill.get("mp_cost", 0)
	# 执行
	state = State.ANIMATING
	ui_state_changed.emit(state)
	var results = await _execute_skill(actor, skill, targets)
	actor_acted.emit(actor, skill_id, targets, results)
	# 动画占位（不 await timer，避免依赖 main loop）
	_end_turn()

## 敌方 AI 行动
func enemy_act() -> void:
	if state != State.ENEMY_TURN:
		return
	var actor := current_actor
	# 简单 AI：选第一个可用技能 + 第一个活着的玩家
	var skill_id := "attack"
	if not actor.skills.is_empty():
		skill_id = actor.skills[0]
	var skill = _skills_cache.get(skill_id, {})
	if skill.is_empty():
		# fallback
		skill = _skills_cache.get("attack", {})
		skill_id = "attack"
	# 扣 MP
	if actor.mp >= skill.get("mp_cost", 0):
		actor.mp -= skill.get("mp_cost", 0)
		# 选目标
		var targets: Array[Actor] = []
		match skill.get("target", ""):
			"single_enemy":
				for p in party:
					if p.is_alive:
						targets.append(p)
						break
			"single_ally":
				targets.append(actor)
			"all_enemies":
				for p in party:
					if p.is_alive:
						targets.append(p)
		state = State.ANIMATING
		ui_state_changed.emit(state)
		var results = await _execute_skill(actor, skill, targets)
		actor_acted.emit(actor, skill_id, targets, results)
	else:
		# MP 不够，skip
		actor_acted.emit(actor, "skip", [], [])
	_end_turn()

func _end_turn() -> void:
	# tick 状态效果
	for a in (party + enemies):
		if a.is_alive:
			a.tick_status()
	# 检查战斗是否结束
	if not _any_alive_in(party) or not _any_alive_in(enemies):
		_finish_battle()
		return
	# 下一个
	if turn_index >= turn_queue.size():
		# 回合结束，重建队列
		_build_turn_queue()
	_next_turn()

## 实际执行技能
func _execute_skill(actor: Actor, skill: Dictionary, targets: Array[Actor]) -> Array:
	var results: Array = []
	var hits := int(skill.get("hits", 1))
	for target in targets:
		for h in hits:
			var result := {"target": target, "amount": 0, "is_crit": false, "missed": false}
			match skill.get("type", ""):
				"physical":
					var stat_val: int = actor.call(skill.get("stat", "str") + "_total")
					var atk = stat_val + actor.level * 0.5
					var crit_rate = 0.05 + skill.get("crit_boost", 0.0)
					var crit = BattleFormula.roll_critical(crit_rate)
					var dmg = BattleFormula.physical_damage(int(atk), target.vit_total(), crit, BattleFormula.roll_variance())
					var actual = target.take_damage(dmg)
					result["amount"] = actual
					result["is_crit"] = crit > 1.0
					actor_damaged.emit(target, actual, result["is_crit"])
					if not target.is_alive:
						actor_died.emit(target)
				"magical":
					var stat_val: int = actor.call(skill.get("stat", "int") + "_total")
					var mgk = stat_val + actor.level * 0.5
					var dmg = BattleFormula.magical_damage(int(mgk), skill.get("coeff", 1.0), target.vit_total() / 2, BattleFormula.roll_variance())
					var actual = target.take_damage(dmg)
					result["amount"] = actual
					actor_damaged.emit(target, actual, false)
					if not target.is_alive:
						actor_died.emit(target)
				"heal":
					var stat_val: int = actor.call(skill.get("stat", "int") + "_total")
					var heal_amt = int(stat_val * skill.get("coeff", 1.0) * BattleFormula.roll_variance())
					var actual = target.heal(heal_amt)
					result["amount"] = actual
					actor_healed.emit(target, actual)
				"buff":
					var stat_buff: Dictionary = skill.get("stat_buff", {})
					var dur: int = skill.get("duration", 3)
					for sk in stat_buff:
						target.add_status("%s_%s" % [skill["id"], target.id], sk, int(stat_buff[sk]), dur)
					result["amount"] = 0
			results.append(result)
	return results

## 跳过本回合（玩家逃跑/防御）
func player_defend() -> void:
	if state != State.PLAYER_TURN:
		return
	state = State.ANIMATING
	ui_state_changed.emit(state)
	current_actor.add_status("defend_%s" % current_actor.id, "vit", 5, 1)
	actor_acted.emit(current_actor, "defend", [], [])
	_end_turn()

func player_run_away() -> bool:
	if state != State.PLAYER_TURN:
		return false
	# 简单判定：随机
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var success = rng.randf() > 0.5
	if success:
		state = State.ENDED
		battle_ended.emit(false, 0)  # 逃跑算"未胜利"
		ui_state_changed.emit(state)
	return success

## 给 UI 用：获取当前可执行指令
func get_player_command() -> Array:
	if state != State.PLAYER_TURN or current_actor == null:
		return []
	var cmds: Array = []
	for sid in current_actor.skills:
		var s = _skills_cache.get(sid, {})
		if not s.is_empty() and current_actor.mp >= s.get("mp_cost", 0):
			cmds.append(sid)
	return cmds
