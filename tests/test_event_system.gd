extends SceneTree

## 事件系统测试

const EventSystem = preload("res://scripts/systems/event_system.gd")
const LOG_PATH := "user://event_test.log"

var _passed: int = 0
var _failed: int = 0

func _init() -> void:
	var f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	f.store_string("")
	f.close()
	_log("=== Event system test ===")
	test_register_and_trigger()
	test_conditions()
	test_flag_set_triggers_on_flag()
	test_multiple_listeners()
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

func test_register_and_trigger() -> void:
	var es = EventSystem.new()
	var triggered := [false]
	es.register("on_talk", "npc_ehto", func(_ctx): triggered[0] = true)
	es.trigger("on_talk", "npc_ehto")
	assert_true(triggered[0], "test_register_and_trigger")

func test_conditions() -> void:
	var es = EventSystem.new()
	var triggered := [false]
	es.register("on_flag", "ch1_started", func(_ctx): triggered[0] = true,
		[{"type": "flag", "key": "ch1_started", "value": true}])
	# 没设 flag → 不触发
	es.trigger("on_flag", "ch1_started")
	assert_eq(triggered[0], false, "test_conditions: no flag = no trigger")
	# 设了 flag → 触发
	es.set_flag("ch1_started", true)
	es.trigger("on_flag", "ch1_started")
	assert_true(triggered[0], "test_conditions: flag set = trigger")

func test_flag_set_triggers_on_flag() -> void:
	var es = EventSystem.new()
	var triggered := [false]
	es.register("on_flag_set", "ehto_rescued", func(_ctx): triggered[0] = true)
	es.set_flag("ehto_rescued", true)
	assert_true(triggered[0], "test_flag_set_triggers_on_flag")

func test_multiple_listeners() -> void:
	var es = EventSystem.new()
	var a := [0]
	var b := [0]
	es.register("on_talk", "npc", func(_ctx): a[0] += 1)
	es.register("on_talk", "npc", func(_ctx): b[0] += 1)
	es.trigger("on_talk", "npc")
	assert_eq(a[0], 1, "test_multiple_listeners: a")
	assert_eq(b[0], 1, "test_multiple_listeners: b")
