extends SceneTree

## 对话 + 翻译 端到端测试
## 加载对话 JSON，验证中英翻译

const LOG_PATH := "user://dialogue_test.log"

var _passed: int = 0
var _failed: int = 0

func _init() -> void:
	var f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	f.store_string("")
	f.close()
	# 手动加载翻译（autoload 在 -s 模式下不跑）
	_load_translation("res://locale/zh.po", "zh")
	_load_translation("res://locale/en.po", "en")
	_log("=== Dialogue E2E test ===")
	test_load_chinese()
	test_load_english()
	test_full_dialogue_flow()
	print("\n=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		quit(1)
	else:
		quit(0)

func _load_translation(path: String, locale: String) -> void:
	var t = ResourceLoader.load(path, "Translation")
	if t is Translation:
		TranslationServer.add_translation(t)
		print("  Loaded: %s" % locale)

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
		_log("PASS: %s (got %s)" % [msg, str(value)])
	else:
		_failed += 1
		_log("FAIL: %s (got %s, expected %s)" % [msg, str(value), str(expected)])

func assert_true(value: bool, msg: String) -> void:
	assert_eq(value, true, msg)

func test_load_chinese() -> void:
	TranslationServer.set_locale("zh")
	var parser = DialogueParser.load_from_file("res://data/dialogues/npc_town_chief_intro.json")
	var text = parser.get_text("start")
	assert_true(text.contains("勇者") or text.contains("帕恩") or text.contains("洞窟"), "test_load_chinese: text contains Chinese")
	_log("  zh start: %s" % text)

func test_load_english() -> void:
	TranslationServer.set_locale("en")
	var parser = DialogueParser.load_from_file("res://data/dialogues/npc_town_chief_intro.json")
	var text = parser.get_text("start")
	assert_true(text.contains("Brave") or text.contains("monsters") or text.contains("cave"), "test_load_english: text contains English")
	_log("  en start: %s" % text)

func test_full_dialogue_flow() -> void:
	TranslationServer.set_locale("zh")
	var parser = DialogueParser.load_from_file("res://data/dialogues/npc_town_chief_intro.json")
	# 遍历节点
	assert_eq(parser.id, "npc_town_chief_intro", "test_full: id")
	assert_eq(parser.speaker, "npc_town_chief", "test_full: speaker")
	assert_eq(parser.get_node("start")["text_key"], "tc_intro_1", "test_full: start text_key")
	assert_eq(parser.get_next_id("start"), "ask", "test_full: start.next=ask")
	var ask = parser.get_node("ask")
	assert_eq(ask["choices"].size(), 2, "test_full: 2 choices")
	# end 节点
	assert_true(parser.is_end("end"), "test_full: end is_end")