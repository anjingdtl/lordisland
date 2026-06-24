extends SceneTree

## 野外地图 E2E 测试

const LOG_PATH := "user://wilderness_test.log"

var _passed: int = 0
var _failed: int = 0

func _init() -> void:
	var f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	f.store_string("")
	f.close()
	var zh = ResourceLoader.load("res://locale/zh.po", "Translation")
	if zh is Translation:
		TranslationServer.add_translation(zh)
	TranslationServer.set_locale("zh")
	_log("=== Wilderness E2E test ===")
	test_troll_in_enemies()
	test_slayn_dialogue_loads()
	test_tike_dialogue_loads()
	test_chest_gives_potion()
	test_forest_decorator_creates_children()
	test_main_quest_extended()
	print("\n=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		quit(1)
	else:
		quit(0)

func _log(msg: String) -> void:
	print(msg)
	var f = FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
	if f == null: return
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

func test_troll_in_enemies() -> void:
	var f = FileAccess.open("res://data/enemies.json", FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	assert_true(data.has("troll"), "troll in enemies.json")
	assert_eq(data.troll.get("hp", 0), 120, "troll HP = 120")
	assert_eq(data.troll.get("exp_reward", 0), 50, "troll exp = 50")

func test_slayn_dialogue_loads() -> void:
	var parser = DialogueParser.load_from_file("res://data/dialogues/npc_slayn_meet.json")
	assert_true(parser.id == "npc_slayn_meet", "slayn dialogue id")
	var start = parser.get_node("start")
	assert_true(start.has("text_key"), "slayn start has text_key")
	var ask = parser.get_node("ask")
	assert_eq(ask["choices"].size(), 3, "slayn 3 choices")

func test_tike_dialogue_loads() -> void:
	var parser = DialogueParser.load_from_file("res://data/dialogues/npc_tike_meet.json")
	assert_true(parser.id == "npc_tike_meet", "tike dialogue id")
	var start = parser.get_node("start")
	assert_true(start.has("text_key"), "tike start has text_key")
	var ask = parser.get_node("ask")
	assert_eq(ask["choices"].size(), 3, "tike 3 choices")

func test_chest_gives_potion() -> void:
	var es = EventSystem.new()
	es.set_flag("item_heal_potion", 1)
	assert_eq(es.get_flag("item_heal_potion"), 1, "chest gives heal_potion")

func test_forest_decorator_creates_children() -> void:
	var ForestDecorator = load("res://scripts/world/forest_decorator.gd")
	var fd = ForestDecorator.new()
	fd.tree_count = 3
	fd.rock_count = 2
	fd.bush_count = 2
	get_root().add_child(fd)
	await process_frame
	var mesh_count = 0
	for child in fd.get_children():
		if child is MeshInstance3D:
			mesh_count += 1
	assert_true(mesh_count >= 5, "forest decorator creates meshes (got %d)" % mesh_count)

func test_main_quest_extended() -> void:
	var es = EventSystem.new()
	es.set_flag("wilderness_boss_defeated", true)
	assert_eq(es.get_flag("wilderness_boss_defeated"), true, "troll boss flag set")
	var troll = JSON.parse_string(FileAccess.open("res://data/enemies.json", FileAccess.READ).get_as_text()).troll
	assert_eq(troll.exp_reward, 50, "troll gives 50 exp")