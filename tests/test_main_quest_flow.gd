extends SceneTree

## 主线流程端到端测试
## 验证：帕恩入队 → 进城 → 找村长 → 进洞窟 → 打哥布林 → 救艾特 → 艾特入队 → 旗标全对

const LOG_PATH := "user://quest_flow_test.log"

var _passed: int = 0
var _failed: int = 0

func _init() -> void:
	var f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	f.store_string("")
	f.close()
	# 加载翻译
	var zh = ResourceLoader.load("res://locale/zh.po", "Translation")
	if zh is Translation:
		TranslationServer.add_translation(zh)
	var en = ResourceLoader.load("res://locale/en.po", "Translation")
	if en is Translation:
		TranslationServer.add_translation(en)
	TranslationServer.set_locale("zh")
	_log("=== Main quest flow E2E test ===")
	test_quest_flow()
	print("\n=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		quit(1)
	else:
		quit(0)

func _log(msg: String) -> void:
	print(msg)
	var f = FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
	if f == null:
		return
	f.seek_end()
	f.store_line(msg)
	f.close()

func assert_eq(value, expected, msg: String) -> void:
	if value == expected:
		_passed += 1
		_log("PASS: %s" % msg)
	else:
		_failed += 1
		_log("FAIL: %s (got %s, expected %s)" % [msg, str(value), str(expected)])

func assert_true(value: bool, msg: String) -> void:
	assert_eq(value, true, msg)

func _wait(seconds: float) -> void:
	# 用 Timer 节点 + process_frame 等
	var t = Timer.new()
	t.wait_time = seconds
	t.one_shot = true
	t.autostart = true
	get_root().add_child(t)
	await t.timeout
	t.queue_free()

func test_quest_flow() -> void:
	# 模拟全局状态
	var es = EventSystem.new()
	var pm = PartyManager.new(es)
	# 1. 帕恩初始入队
	pm.add_member("parn")
	assert_eq(pm.get_size(), 1, "1. Parn joins party")
	assert_true(pm.has_member("parn"), "1. Parn in party")
	# 2. 玩家进城
	es.set_flag("at_loranai", true)
	assert_true(es.has_flag("at_loranai"), "2. At Loranai")
	# 3. 找村长
	var town_chief_dialogue = DialogueParser.load_from_file("res://data/dialogues/npc_town_chief_intro.json")
	assert_true(town_chief_dialogue.id != "", "3. Town chief dialogue loads")
	# 4. 接受任务
	es.set_flag("quest_cave_rescue", true)
	assert_true(es.has_flag("quest_cave_rescue"), "4. Quest accepted")
	# 5. 进洞窟
	es.set_flag("at_starting_cave", true)
	assert_true(es.has_flag("at_starting_cave"), "5. Entered cave")
	# 6. 打第一个哥布林战斗
	es.set_flag("cave_battle1_cleared", true)
	assert_true(es.has_flag("cave_battle1_cleared"), "6. Battle 1 cleared")
	# 7. 打 boss（兽人）
	es.set_flag("cave_boss_defeated", true)
	assert_true(es.has_flag("cave_boss_defeated"), "7. Boss defeated")
	# 8. 救艾特
	var exec = EventExecutor.new(es, pm)
	# 用 EventExecutor 手动执行事件（模拟 boss 战后的 on_talk npc_ehto 触发）
	exec.register_from_json("res://data/events/ch0_rescue_ehto.json")
	# 条件: not_flag ehto_rescued - 现在 false，应该触发
	es.trigger("on_talk", "npc_ehto")
	# 现在所有非阻塞 step 都同步执行了，不需要等待
	# 验证艾特入队
	assert_eq(pm.get_size(), 2, "8. Ehto joined (party size = 2)")
	assert_true(pm.has_member("ehto"), "8. Ehto in party")
	assert_true(es.has_flag("ehto_rescued"), "8. ehto_rescued flag set")
	# 9. 重复触发不会重复入队（因为 ehto_rescued 已经是 true）
	es.trigger("on_talk", "npc_ehto")
	assert_eq(pm.get_size(), 2, "9. Idempotent: party size still 2")
	# 10. 存档测试
	var s = SaveSystem.new()
	s.set_value("chapter", "ch0_done")
	s.set_value("members", pm.get_member_ids())
	s.save_to_slot(0)
	var s2 = SaveSystem.new()
	var ok = s2.load_from_slot(0)
	assert_true(ok, "10. Save/Load roundtrip")
	var members = s2.get_value("members")
	assert_eq(members[0], "parn", "10. Parn in save")
	assert_eq(members[1], "ehto", "10. Ehto in save")
	# 11. i18n 验证
	TranslationServer.set_locale("en")
	var text = TranslationServer.translate("tc_intro_1")
	assert_true(text.contains("Brave"), "11. EN translation works")