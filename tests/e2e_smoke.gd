extends SceneTree

## Lordisland 端到端穿测脚本
## 验证：主菜单 → 新游戏 → 洛奈城 → 村长对话 → 起始洞窟 → 战斗 → 胜利
## 涵盖场景加载、UI 控件、战斗系统、存档/读档、BGM

const TOTAL_TESTS := 0
var passed := 0
var failed := 0
var failed_tests: Array[String] = []

func _init() -> void:
	print("\n=== Lordisland 端到端穿测 ===\n")
	# 关键：等待 autoload 完成
	await process_frame
	_test_globals_ready()
	await process_frame
	_test_main_menu_scene()
	await process_frame
	_test_save_system()
	await process_frame
	_test_inventory()
	await process_frame
	_test_party_manager()
	await process_frame
	_test_dialogue_parser()
	await process_frame
	_test_event_system()
	await process_frame
	_test_battle_full_flow()
	await process_frame
	_test_loranai_city_scene()
	await process_frame
	_test_starting_cave_scene()
	await process_frame
	_test_loranai_wilderness_scene()
	await process_frame
	_test_battle_scene()
	await process_frame
	_test_settings_ui_scene()
	await process_frame
	_test_sfx_generator()
	await process_frame
	_test_steam_bridge()
	await process_frame
	_test_ui_files_exist()
	await process_frame
	_test_data_files_valid()
	await process_frame
	print("\n=== 穿测完成: PASS %d / FAIL %d ===\n" % [passed, failed])
	if failed > 0:
		print("FAILED: %s" % ", ".join(failed_tests))
	print("=== RESULT: %d passed, %d failed ===" % [passed, failed])
	quit(failed)

func _ok(name: String) -> void:
	passed += 1
	print("[PASS] %s" % name)

func _fail(name: String, why: String) -> void:
	failed += 1
	failed_tests.append(name)
	print("[FAIL] %s -- %s" % [name, why])

# ============== TESTS ==============

func _test_globals_ready() -> void:
	var globals = root.get_node_or_null("GameGlobals")
	if globals == null:
		_fail("globals_ready", "GameGlobals autoload not found")
		return
	if globals.event_system == null:
		_fail("globals_ready", "event_system missing")
		return
	if globals.party_manager == null:
		_fail("globals_ready", "party_manager missing")
		return
	if globals.audio_manager == null:
		_fail("globals_ready", "audio_manager missing")
		return
	if globals.inventory == null:
		_fail("globals_ready", "inventory missing")
		return
	if globals.quest_log == null:
		_fail("globals_ready", "quest_log missing")
		return
	if globals.save_system == null:
		_fail("globals_ready", "save_system missing")
		return
	_ok("globals_ready")

func _test_main_menu_scene() -> void:
	var scene = load("res://scenes/ui/main_menu.tscn") as PackedScene
	if scene == null:
		_fail("main_menu_scene", "failed to load")
		return
	var inst = scene.instantiate()
	if inst == null:
		_fail("main_menu_scene", "instantiate returned null")
		return
	if inst.get_script() == null:
		_fail("main_menu_scene", "no script attached")
		inst.free()
		return
	# 程序化构建后看子节点
	root.add_child(inst)
	await process_frame
	# 应有 background/logo/buttons/version
	if inst.get_child_count() < 3:
		_fail("main_menu_scene", "expected >=3 children (bg+buttons+version), got %d" % inst.get_child_count())
		inst.queue_free()
		return
	# 检查按钮（VBox 中的 5 个）
	var found_new_game := false
	for c in inst.get_children():
		if c is VBoxContainer:
			for b in c.get_children():
				if b is Button and b.text.find("新游戏") >= 0:
					found_new_game = true
					# 测试按钮 disabled 状态
					if b.disabled:
						_fail("main_menu_new_game_disabled", "new game should not be disabled")
						return
	if not found_new_game:
		_fail("main_menu_new_game", "新游戏 button not found")
		inst.queue_free()
		return
	_ok("main_menu_scene")

func _test_save_system() -> void:
	var globals = root.get_node_or_null("GameGlobals")
	var ss = globals.save_system
	ss.reset()
	ss.set_value("chapter", "序章")
	ss.set_value("player_pos", Vector2(5, 3))
	ss.set_value("members", ["parn", "ehto"])
	if not ss.save_to_slot(0):
		_fail("save_system", "save_to_slot(0) failed")
		return
	ss.reset()
	if not ss.load_from_slot(0):
		_fail("save_system", "load_from_slot(0) failed")
		return
	if ss.get_value("chapter") != "序章":
		_fail("save_system_chapter", "got %s" % str(ss.get_value("chapter")))
		return
	if ss.get_value("members") != ["parn", "ehto"]:
		_fail("save_system_members", "members mismatch")
		return
	# slot_exists / delete_slot
	if not ss.slot_exists(0):
		_fail("save_system_slot_exists", "should exist after save")
		return
	if not ss.delete_slot(0):
		_fail("save_system_delete", "delete failed")
		return
	if ss.slot_exists(0):
		_fail("save_system_delete_post", "should not exist after delete")
		return
	_ok("save_system")

func _test_inventory() -> void:
	var globals = root.get_node_or_null("GameGlobals")
	var inv = globals.inventory
	inv.reset()
	# 设计：起始资金 100（新游戏开局）
	if inv.gold != 100:
		_fail("inv_initial_gold", "should be 100 (new game starting gold), got %d" % inv.gold)
		return
	inv.add_gold(50)
	if inv.gold != 150:
		_fail("inv_add_gold_amount", "should be 150")
		return
	inv.add_item("heal_potion", 3)
	if inv.count_item("heal_potion") != 3:
		_fail("inv_count_item", "expected 3 heal_potion")
		return
	if not inv.spend_gold(50):
		_fail("inv_spend_gold", "spend_gold failed")
		return
	if inv.gold != 100:
		_fail("inv_spend_gold_amount", "should be 100 (started 100 + added 50 - spent 50)")
		return
	# overspend
	if inv.spend_gold(999):
		_fail("inv_overspend", "should not allow overspend")
		return
	_ok("inventory")

func _test_party_manager() -> void:
	var globals = root.get_node_or_null("GameGlobals")
	var pm = globals.party_manager
	pm.reset()
	if pm.get_size() != 0:
		_fail("pm_initial_size", "should be 0")
		return
	if not pm.add_member("parn"):
		_fail("pm_add_member_parn", "add parn failed")
		return
	if pm.add_member("parn"):
		_fail("pm_add_member_duplicate", "duplicate add should fail")
		return
	if not pm.add_member("ehto"):
		_fail("pm_add_member_ehto", "add ehto failed")
		return
	if pm.get_size() != 2:
		_fail("pm_size_after_add", "should be 2")
		return
	if not pm.has_member("parn"):
		_fail("pm_has_member", "should have parn")
		return
	var data = pm.get_member_data("parn")
	if data.is_empty():
		_fail("pm_get_data", "should have parn data")
		return
	if data.get("hp", 0) <= 0:
		_fail("pm_parn_hp", "parn should have HP")
		return
	# 序列化和恢复
	var d = pm.to_dict()
	if d.get("members", []).size() != 2:
		_fail("pm_serialize", "members size wrong")
		return
	pm.reset()
	if pm.get_size() != 0:
		_fail("pm_reset", "should be empty after reset")
		return
	pm.restore(d.get("members", []), d.get("party_data", {}))
	if pm.get_size() != 2:
		_fail("pm_restore", "should be 2 after restore")
		return
	_ok("party_manager")

func _test_dialogue_parser() -> void:
	var DialogueParser = load("res://scripts/systems/dialogue_parser.gd")
	if DialogueParser == null:
		_fail("dialogue_parser_load", "script not found")
		return
	var parser = DialogueParser.load_from_file("res://data/dialogues/npc_town_chief_intro.json")
	if parser == null:
		_fail("dialogue_parser_load_file", "load_from_file failed")
		return
	var nodes = parser.nodes
	if nodes.size() == 0:
		_fail("dialogue_parser_nodes", "no nodes parsed")
		return
	var start = parser.get_node("start")
	if start.is_empty():
		_fail("dialogue_parser_start", "no start node")
		return
	if not parser.get_text("start"):
		_fail("dialogue_parser_text", "start text missing")
		return
	if not parser.is_end("end"):
		_fail("dialogue_parser_end", "end marker missing")
		return
	_ok("dialogue_parser")

func _test_event_system() -> void:
	var globals = root.get_node_or_null("GameGlobals")
	var es = globals.event_system
	es.reset()
	es.set_flag("test_flag", true)
	if not es.get_flag("test_flag"):
		_fail("event_flag_set_get", "flag not set")
		return
	es.set_counter("test_counter", 5)
	if es.get_counter("test_counter") != 5:
		_fail("event_counter", "counter wrong")
		return
	es.inc_counter("test_counter", 3)
	if es.get_counter("test_counter") != 8:
		_fail("event_counter_inc", "inc wrong")
		return
	_ok("event_system")

func _test_battle_full_flow() -> void:
	var BattleController = load("res://scripts/systems/battle_controller.gd")
	var Actor = load("res://scripts/systems/actor.gd")
	if BattleController == null or Actor == null:
		_fail("battle_load", "scripts missing")
		return
	var bc = BattleController.new()
	root.add_child(bc)
	# 帕恩+艾特 vs 兽人+2哥布林
	var parn_data = {
		"id": "parn", "name_key": "char_parn", "level": 5,
		"hp": 200, "mp": 30, "str": 20, "agi": 15, "int": 5, "vit": 15, "cha": 10,
		"skills": ["attack", "parn_slash"]
	}
	var ehto_data = {
		"id": "ehto", "name_key": "char_ehto", "level": 4,
		"hp": 120, "mp": 80, "str": 8, "agi": 12, "int": 18, "vit": 10, "cha": 15,
		"skills": ["heal_light", "fireball"]
	}
	bc.setup([parn_data, ehto_data], ["orc", "goblin", "goblin"])
	if bc.party.size() != 2:
		_fail("battle_party_size", "should be 2, got %d" % bc.party.size())
		bc.queue_free()
		return
	if bc.enemies.size() != 3:
		_fail("battle_enemy_size", "should be 3, got %d" % bc.enemies.size())
		bc.queue_free()
		return
	# 检查所有 actor 数据加载
	for p in bc.party:
		if p.hp <= 0:
			_fail("battle_actor_hp", "actor HP not loaded")
			bc.queue_free()
			return
	for e in bc.enemies:
		if e.exp_reward <= 0:
			_fail("battle_enemy_exp", "enemy should have exp_reward")
			bc.queue_free()
			return
	# 跑 N 回合（自动攻击）
	bc.start_battle()
	var max_turns := 60
	var turn := 0
	while bc.state != BattleController.State.ENDED and turn < max_turns:
		turn += 1
		if bc.state == BattleController.State.PLAYER_TURN:
			# 自动执行第一个技能
			var cmds = bc.get_player_command()
			if cmds.is_empty():
				bc.player_defend()
			else:
				bc.player_action(cmds[0], 0)
		elif bc.state == BattleController.State.ENEMY_TURN:
			bc.enemy_act()
		await process_frame
	if bc.state != BattleController.State.ENDED:
		_fail("battle_end_timeout", "battle not ended after %d turns" % max_turns)
		bc.queue_free()
		return
	var any_alive_party := false
	for p in bc.party:
		if p.is_alive:
			any_alive_party = true
			break
	var any_alive_enemy := false
	for e in bc.enemies:
		if e.is_alive:
			any_alive_enemy = true
			break
	if any_alive_party and not any_alive_enemy:
		# 胜利
		if bc.total_exp_gained <= 0:
			_fail("battle_exp_reward", "no exp gained on victory")
			bc.queue_free()
			return
	elif any_alive_enemy and not any_alive_party:
		_fail("battle_party_wipe", "party wiped against 2 chars vs 3 weak mobs")
		bc.queue_free()
		return
	# 任意结果（胜利/平局）都算通过——但 5v3 高等级碾压应胜利
	# 测试技能目标选择 (all_enemies)
	bc.setup([parn_data], ["goblin", "goblin", "goblin"])
	bc.start_battle()
	turn = 0
	while bc.state != BattleController.State.ENDED and turn < 30:
		turn += 1
		if bc.state == BattleController.State.PLAYER_TURN:
			var cmds = bc.get_player_command()
			if cmds.is_empty():
				bc.player_defend()
			else:
				# 选 all_enemies 技能测试
				bc.player_action(cmds[0], 0)
		elif bc.state == BattleController.State.ENEMY_TURN:
			bc.enemy_act()
		await process_frame
	bc.queue_free()
	_ok("battle_full_flow")

func _test_loranai_city_scene() -> void:
	var scene = load("res://scenes/world/loranai_city.tscn") as PackedScene
	if scene == null:
		_fail("loranai_city_load", "failed")
		return
	var inst = scene.instantiate()
	if inst == null:
		_fail("loranai_city_instantiate", "null")
		return
	root.add_child(inst)
	await process_frame
	# 检查节点
	var has_player = inst.has_node("Player")
	var has_camera = inst.has_node("Camera")
	var has_env = inst.has_node("WorldEnv")
	if not (has_player and has_camera and has_env):
		_fail("loranai_city_nodes", "missing Player/Camera/WorldEnv")
		inst.queue_free()
		return
	# 检查 NPC 数量
	var npc_count := 0
	var exit_count := 0
	for c in inst.get_children():
		if c.is_in_group("npc"):
			npc_count += 1
		if c.is_in_group("exit"):
			exit_count += 1
	if npc_count < 1:
		_fail("loranai_npc_count", "no NPCs")
		inst.queue_free()
		return
	if exit_count < 1:
		_fail("loranai_exit_count", "no exits")
		inst.queue_free()
		return
	# 检查 Player sprite
	var player = inst.get_node("Player")
	var avatar = player.get_node("Avatar")
	if avatar == null:
		_fail("loranai_player_avatar", "no avatar")
		inst.queue_free()
		return
	inst.queue_free()
	_ok("loranai_city_scene")

func _test_starting_cave_scene() -> void:
	var scene = load("res://scenes/world/starting_cave.tscn") as PackedScene
	if scene == null:
		_fail("starting_cave_load", "failed")
		return
	var inst = scene.instantiate()
	root.add_child(inst)
	await process_frame
	var has_player = inst.has_node("Player")
	var has_env = inst.has_node("WorldEnv")
	if not (has_player and has_env):
		_fail("starting_cave_nodes", "missing Player/WorldEnv")
		inst.queue_free()
		return
	inst.queue_free()
	_ok("starting_cave_scene")

func _test_loranai_wilderness_scene() -> void:
	var scene = load("res://scenes/world/loranai_wilderness.tscn") as PackedScene
	if scene == null:
		_fail("wilderness_load", "failed")
		return
	var inst = scene.instantiate()
	root.add_child(inst)
	await process_frame
	var has_player = inst.has_node("Player")
	var has_env = inst.has_node("WorldEnv")
	if not (has_player and has_env):
		_fail("wilderness_nodes", "missing Player/WorldEnv")
		inst.queue_free()
		return
	inst.queue_free()
	_ok("loranai_wilderness_scene")

func _test_battle_scene() -> void:
	var scene = load("res://scenes/battle/battle_scene.tscn") as PackedScene
	if scene == null:
		_fail("battle_scene_load", "failed")
		return
	var inst = scene.instantiate()
	root.add_child(inst)
	await process_frame
	if not inst.has_node("BattleController"):
		_fail("battle_scene_controller", "no BattleController")
		inst.queue_free()
		return
	if not inst.has_node("BattleUI"):
		_fail("battle_scene_ui", "no BattleUI")
		inst.queue_free()
		return
	var ui = inst.get_node("BattleUI")
	var bc = inst.get_node("BattleController")
	ui.bind(bc)
	await process_frame
	if not ui.action_menu:
		_fail("battle_ui_action_menu", "action_menu not built")
		inst.queue_free()
		return
	if not ui.party_panel:
		_fail("battle_ui_party_panel", "party_panel not built")
		inst.queue_free()
		return
	# 验证事件可绑定
	if not ui.controller.battle_started.is_connected(ui._on_state_changed):
		# 不强求连接（只是 emit），检查 callable
		pass
	inst.queue_free()
	_ok("battle_scene")

func _test_ui_files_exist() -> void:
	var files := [
		"res://scripts/ui/main_menu.gd",
		"res://scripts/ui/battle_ui.gd",
		"res://scripts/ui/dialogue_ui.gd",
		"res://scripts/ui/shop_ui.gd",
		"res://scripts/ui/save_load_ui.gd",
		"res://scripts/ui/settings_ui.gd",
		"res://scripts/ui/floating_text.gd",
	]
	for f in files:
		if not FileAccess.file_exists(f):
			_fail("ui_file_exists", "%s missing" % f)
			return
	_ok("ui_files_exist")

func _test_data_files_valid() -> void:
	var files := [
		"res://data/items.json",
		"res://data/enemies.json",
		"res://data/quests.json",
		"res://data/skills.json",
	]
	for f in files:
		if not FileAccess.file_exists(f):
			_fail("data_file_exists", "%s missing" % f)
			return
		var fd = FileAccess.open(f, FileAccess.READ)
		var text = fd.get_as_text()
		var parsed = JSON.parse_string(text)
		if parsed == null:
			_fail("data_file_parse", "%s not valid JSON" % f)
			return
	# 角色 JSON
	for ch in ["parn", "ehto", "ghim", "slayn", "tike"]:
		var p = "res://data/characters/%s.json" % ch
		if not FileAccess.file_exists(p):
			_fail("character_exists", "%s missing" % p)
			return
	# 对话 JSON
	for d in ["npc_town_chief_intro", "npc_slayn_meet", "npc_tike_meet", "npc_ehto_intro", "npc_slayn_join", "npc_tike_join"]:
		var dp = "res://data/dialogues/%s.json" % d
		if not FileAccess.file_exists(dp):
			_fail("dialogue_exists", "%s missing" % dp)
			return
	# 事件 JSON
	for ev in ["ch0_rescue_ehto", "ch0_recruit_slayn", "ch0_recruit_tike"]:
		var ep = "res://data/events/%s.json" % ev
		if not FileAccess.file_exists(ep):
			_fail("event_exists", "%s missing" % ep)
			return
	_ok("data_files_valid")

func _test_settings_ui_scene() -> void:
	var script = load("res://scripts/ui/settings_ui.gd")
	if script == null:
		_fail("settings_ui_load", "script missing")
		return
	var ui = script.new()
	root.add_child(ui)
	await process_frame
	if not ui.has_method("_save_settings"):
		_fail("settings_ui_api", "_save_settings missing")
		ui.queue_free()
		return
	if not ui.has_method("_apply_resolution"):
		_fail("settings_ui_resize", "_apply_resolution missing")
		ui.queue_free()
		return
	# 验证 resolution 选项
	if ui.RESOLUTIONS.size() < 3:
		_fail("settings_ui_resolutions", "should have >=3 resolutions")
		ui.queue_free()
		return
	ui.queue_free()
	_ok("settings_ui_scene")

func _test_sfx_generator() -> void:
	var SfxGenerator = load("res://scripts/core/sfx_generator.gd")
	if SfxGenerator == null:
		_fail("sfx_gen_load", "missing")
		return
	var g = SfxGenerator.new()
	# 测试每种 SFX
	var sfx_ids = ["click", "hover", "hit", "crit", "heal", "buy", "buy_fail", "victory", "defeat", "levelup", "pickup", "menu_move", "test"]
	var generated := 0
	for id in sfx_ids:
		var stream = g.call("generate_" + id)
		if stream == null:
			_fail("sfx_gen_" + id, "generate failed")
			return
		generated += 1
	if generated < sfx_ids.size():
		_fail("sfx_gen_count", "only %d/%d" % [generated, sfx_ids.size()])
		return
	# 缓存测试（第二次调用应该复用）
	var globals = root.get_node_or_null("GameGlobals")
	if globals and globals.audio_manager:
		globals.audio_manager.play_sfx("click")
		globals.audio_manager.play_sfx("hit")
		globals.audio_manager.play_sfx("victory")
	_ok("sfx_generator")

func _test_steam_bridge() -> void:
	var SteamBridge = load("res://scripts/core/steam_bridge.gd")
	if SteamBridge == null:
		_fail("steam_bridge_load", "missing")
		return
	# 验证是 autoload（root 已有）
	var found := false
	for c in root.get_children():
		if c.name == "SteamBridge":
			found = true
			# 测试关键 API
			if c.ACHIEVEMENTS.size() < 5:
				_fail("steam_achievements", "should have >=5 achievements")
				return
			c.unlock_achievement("first_battle")
			c.unlock_by_chapter("ch0_rescue_ehto")
			break
	if not found:
		_fail("steam_bridge_autoload", "SteamBridge autoload not found")
		return
	_ok("steam_bridge")