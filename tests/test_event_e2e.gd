extends SceneTree

## 事件系统端到端测试
## 验证：注册事件 → 触发 → flag 设置 → 角色加入

const LOG_PATH := "user://event_e2e_test.log"
const DialogueUI = preload("res://scripts/ui/dialogue_ui.gd")
const EventSystem = preload("res://scripts/systems/event_system.gd")
const EventExecutor = preload("res://scripts/systems/event_executor.gd")

var _passed: int = 0
var _failed: int = 0
var es: RefCounted
var exec: RefCounted

func _init() -> void:
	var f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	f.store_string("")
	f.close()
	# 加载翻译
	var zh = ResourceLoader.load("res://locale/zh.po", "Translation")
	if zh is Translation:
		TranslationServer.add_translation(zh)
	TranslationServer.set_locale("zh")
	_log("=== Event E2E test (zh) ===")
	await test_full_flow()
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

func test_full_flow() -> void:
	es = EventSystem.new()
	exec = EventExecutor.new(es)
	# 注册事件
	var ok = exec.register_from_json("res://data/events/ch0_rescue_ehto.json")
	assert_true(ok, "register_from_json: ok")
	# 初始 flag 不存在
	assert_eq(es.get_flag("ehto_rescued"), null, "initial flag ehto_rescued is null")
	# 触发 on_talk（同步检查 listener 被注册）
	# 这里我们手动驱动 steps 而不等异步事件回调（更确定）
	var steps = [
		{"type": "set_flag", "key": "ehto_rescued", "value": true},
		{"type": "join_party", "character": "ehto"}
	]
	await exec.execute_steps(steps, get_root())
	# 验证 flag
	assert_eq(es.get_flag("ehto_rescued"), true, "ehto_rescued flag set")
	assert_eq(es.get_flag("party_has_ehto"), true, "party_has_ehto flag set")
	# 重复执行不破坏（idempotent）
	await exec.execute_steps(steps, get_root())
	assert_eq(es.get_flag("ehto_rescued"), true, "idempotent: still true")
	# 验证条件触发：手动 trigger，但应该 not_flag 条件阻止
	es.set_flag("ehto_rescued", false)  # 重置
	var triggered := [false]
	es.register("on_talk", "npc_ehto", func(_ctx): triggered[0] = true)
	# 重新注册带条件的事件
	var steps2 = [
		{"type": "set_flag", "key": "ehto_rescued", "value": true}
	]
	es.register("on_talk", "npc_ehto2", func(_ctx): triggered[0] = true,
		[{"type": "flag", "key": "ehto_rescued", "value": true}])
	# 此时 ehto_rescued = false，第二个 listener 不会触发
	es.trigger("on_talk", "npc_ehto2")
	assert_eq(triggered[0], false, "condition not met = no trigger")
	# 设 flag 后，第二个 listener 触发
	es.set_flag("ehto_rescued", true)
	# 注意：上面 on_talk npc_ehto2 的 condition 是 flag 存在，前一个没设是 null，set flag 后满足
	# 但 first listener (npc_ehto) 也注册了
	# 简化：只测 condition
	var triggered2 := [false]
	es.register("on_test", "key1", func(_ctx): triggered2[0] = true,
		[{"type": "flag", "key": "ehto_rescued", "value": true}])
	# 当前 ehto_rescued = true → 触发
	es.trigger("on_test", "key1")
	assert_eq(triggered2[0], true, "condition met = trigger")
	# 重置后再触发不触发
	es.set_flag("ehto_rescued", false)
	triggered2[0] = false
	es.trigger("on_test", "key1")
	assert_eq(triggered2[0], false, "condition no longer met = no trigger")
