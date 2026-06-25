extends SceneTree

## 任务系统测试

const EventSystem = preload("res://scripts/systems/event_system.gd")
const QuestLog = preload("res://scripts/core/quest_log.gd")

var _passed: int = 0
var _failed: int = 0

func _init() -> void:
	var zh = ResourceLoader.load("res://locale/zh.po", "Translation")
	if zh is Translation:
		TranslationServer.add_translation(zh)
	TranslationServer.set_locale("zh")
	test_quest_data_loaded()
	test_quest_accept()
	test_quest_complete()
	test_quest_save_load()
	test_quest_active_completed()
	test_quest_unknown()
	test_quest_in_gameglobals()
	print("\n=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		quit(1)
	else:
		quit(0)

func assert_eq(value, expected, msg: String) -> void:
	if value == expected:
		_passed += 1
		print("PASS: %s" % msg)
	else:
		_failed += 1
		print("FAIL: %s (got %s, expected %s)" % [msg, str(value), str(expected)])

func assert_true(value: bool, msg: String) -> void:
	assert_eq(value, true, msg)

func test_quest_data_loaded() -> void:
	var es = EventSystem.new()
	var ql = QuestLog.new(es)
	assert_eq(ql.quest_data.size(), 3, "3 quests loaded")
	assert_true(ql.quest_data.has("quest_goblin_hunt"), "goblin_hunt quest")
	assert_eq(ql.quest_data.quest_goblin_hunt.reward_gold, 100, "goblin_hunt reward 100")

func test_quest_accept() -> void:
	var es = EventSystem.new()
	var ql = QuestLog.new(es)
	assert_true(ql.accept("quest_goblin_hunt"), "accept goblin_hunt")
	assert_true(ql.is_active("quest_goblin_hunt"), "goblin_hunt active")
	# 重复接受
	assert_true(not ql.accept("quest_goblin_hunt"), "duplicate accept fails")

func test_quest_complete() -> void:
	var es = EventSystem.new()
	var ql = QuestLog.new(es)
	ql.accept("quest_lost_sword")
	ql.complete("quest_lost_sword")
	assert_true(not ql.is_active("quest_lost_sword"), "lost_sword no longer active")
	assert_true(ql.is_completed("quest_lost_sword"), "lost_sword completed")
	# 完成未接受的任务
	assert_true(not ql.complete("quest_meet_three"), "complete unaccepted fails")

func test_quest_save_load() -> void:
	var es = EventSystem.new()
	var ql = QuestLog.new(es)
	ql.accept("quest_goblin_hunt")
	ql.accept("quest_lost_sword")
	ql.complete("quest_lost_sword")
	var data = ql.to_dict()
	var ql2 = QuestLog.new(es)
	ql2.restore(data)
	assert_eq(ql2.active_quests.size(), 1, "1 active after restore")
	assert_eq(ql2.completed_quests.size(), 1, "1 completed after restore")
	assert_true(ql2.is_active("quest_goblin_hunt"), "goblin_hunt active restored")
	assert_true(ql2.is_completed("quest_lost_sword"), "lost_sword completed restored")

func test_quest_active_completed() -> void:
	var es = EventSystem.new()
	var ql = QuestLog.new(es)
	assert_eq(ql.active_quests.size(), 0, "no active initially")
	assert_eq(ql.completed_quests.size(), 0, "no completed initially")
	ql.accept("quest_meet_three")
	assert_eq(ql.active_quests.size(), 1, "1 active after accept")

func test_quest_unknown() -> void:
	var es = EventSystem.new()
	var ql = QuestLog.new(es)
	assert_true(not ql.accept("quest_does_not_exist"), "unknown quest rejected")
	assert_true(not ql.complete("quest_does_not_exist"), "unknown complete rejected")

func test_quest_in_gameglobals() -> void:
	# GameGlobals 创建时应该有 quest_log
	var globals_script = load("res://scripts/core/game_globals.gd")
	# 不实际实例化（autoload 由 Godot 加载），但验证脚本无错
	assert_true(globals_script != null, "game_globals script loads")
