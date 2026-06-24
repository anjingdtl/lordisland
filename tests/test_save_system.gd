extends SceneTree

const SaveSystem = preload("res://scripts/systems/save_system.gd")

var _passed: int = 0
var _failed: int = 0

func _init() -> void:
	_clear_saves()
	_run_all()
	print("\n=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		quit(1)
	else:
		quit(0)

func _clear_saves() -> void:
	for i in 10:
		if FileAccess.file_exists("user://saves/save_%d.json" % i):
			DirAccess.remove_absolute("user://saves/save_%d.json" % i)

func _run_all() -> void:
	test_basic_save_load()
	test_vector_save_load()
	test_free_save_no_restriction()
	test_multiple_slots()
	test_missing_slot()
	test_delete_slot()

func assert_eq(value, expected, msg: String) -> void:
	if value == expected:
		_passed += 1
		print("PASS: %s (got %s)" % [msg, str(value)])
	else:
		_failed += 1
		print("FAIL: %s (got %s, expected %s)" % [msg, str(value), str(expected)])

func assert_true(value: bool, msg: String) -> void:
	assert_eq(value, true, msg)

func assert_false(value: bool, msg: String) -> void:
	assert_eq(value, false, msg)

func test_basic_save_load() -> void:
	var s1 = SaveSystem.new()
	s1.set_value("chapter", "ch0")
	s1.set_value("player_name", "Parn")
	s1.set_nested("flags", "ehto_rescued", true)
	s1.save_to_slot(0)
	var s2 = SaveSystem.new()
	var ok = s2.load_from_slot(0)
	assert_true(ok, "test_basic: load ok")
	assert_eq(s2.get_value("chapter"), "ch0", "test_basic: chapter")
	assert_eq(s2.get_value("player_name"), "Parn", "test_basic: player_name")
	assert_eq(s2.get_nested("flags", "ehto_rescued"), true, "test_basic: nested flag")

func test_vector_save_load() -> void:
	# Vector2 在 JSON 中会变成 dict（x, y 键）
	# 测试时改用可序列化的 [x, y] 数组
	var s1 = SaveSystem.new()
	s1.set_value("player_pos", [123.5, 456.7])
	s1.set_value("party_hp", [80, 90, 100, 70, 130])
	s1.save_to_slot(1)
	var s2 = SaveSystem.new()
	s2.load_from_slot(1)
	var pos = s2.get_value("player_pos")
	assert_eq(pos[0], 123.5, "test_vector: pos.x")
	assert_eq(pos[1], 456.7, "test_vector: pos.y")
	var hp = s2.get_value("party_hp")
	assert_eq(hp.size(), 5, "test_vector: hp size")
	assert_eq(hp[0], 80, "test_vector: hp[0]")
	assert_eq(hp[4], 130, "test_vector: hp[4]")

func test_free_save_no_restriction() -> void:
	var s = SaveSystem.new()
	s.set_value("state", "in_battle")
	s.save_to_slot(2)
	s.set_value("state", "in_dialogue")
	s.save_to_slot(2)
	s.set_value("state", "on_map")
	s.save_to_slot(2)
	assert_true(s.slot_exists(2), "test_free: slot 2 exists")
	var s2 = SaveSystem.new()
	s2.load_from_slot(2)
	assert_eq(s2.get_value("state"), "on_map", "test_free: latest state")

func test_multiple_slots() -> void:
	var s = SaveSystem.new()
	for i in 5:
		s.set_value("data", i)
		s.save_to_slot(i)
	for i in 5:
		var s2 = SaveSystem.new()
		s2.load_from_slot(i)
		assert_eq(s2.get_value("data"), i, "test_multiple: slot %d" % i)

func test_missing_slot() -> void:
	var s = SaveSystem.new()
	var ok = s.load_from_slot(9)
	assert_false(ok, "test_missing: returns false")

func test_delete_slot() -> void:
	var s = SaveSystem.new()
	s.set_value("temp", "data")
	s.save_to_slot(5)
	assert_true(s.slot_exists(5), "test_delete: exists before")
	s.delete_slot(5)
	assert_false(s.slot_exists(5), "test_delete: gone after")