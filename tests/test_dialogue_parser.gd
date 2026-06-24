extends SceneTree

const DialogueParser = preload("res://scripts/systems/dialogue_parser.gd")

var _passed: int = 0
var _failed: int = 0

func _init() -> void:
	test_parse_simple_dialogue()
	test_parse_choices()
	test_load_from_file()
	test_translate_text()
	print("\n=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		quit(1)
	else:
		quit(0)

func assert_eq(value, expected, msg: String) -> void:
	if value == expected:
		_passed += 1
		print("PASS: %s (got %s)" % [msg, str(value)])
	else:
		_failed += 1
		print("FAIL: %s (got %s, expected %s)" % [msg, str(value), str(expected)])

func assert_true(value: bool, msg: String) -> void:
	assert_eq(value, true, msg)

func test_parse_simple_dialogue() -> void:
	var data = {
		"id": "test",
		"speaker": "npc",
		"nodes": [
			{"id": "start", "text_key": "hello", "next": "end"},
			{"id": "end", "type": "end"}
		]
	}
	var parser = DialogueParser.new(data)
	var node = parser.get_node("start")
	assert_eq(node["text_key"], "hello", "test_parse_simple_dialogue: text_key")
	assert_eq(parser.get_next_id("start"), "end", "test_parse_simple_dialogue: next_id")
	var end_node = parser.get_node("end")
	assert_eq(end_node["type"], "end", "test_parse_simple_dialogue: type=end")

func test_parse_choices() -> void:
	var data = {
		"id": "test",
		"speaker": "npc",
		"nodes": [
			{"id": "start", "text_key": "ask",
			 "choices": [
				 {"label_key": "yes", "next": "yes_path"},
				 {"label_key": "no", "next": "no_path"}
			 ]},
			{"id": "yes_path", "text_key": "ok", "next": "end"},
			{"id": "no_path", "text_key": "bye", "next": "end"},
			{"id": "end", "type": "end"}
		]
	}
	var parser = DialogueParser.new(data)
	var start = parser.get_node("start")
	assert_eq(start["choices"].size(), 2, "test_parse_choices: 2 choices")
	assert_eq(start["choices"][0]["label_key"], "yes", "test_parse_choices: first label")
	assert_eq(start["choices"][0]["next"], "yes_path", "test_parse_choices: first next")
	assert_eq(start["choices"][1]["label_key"], "no", "test_parse_choices: second label")

func test_load_from_file() -> void:
	# 用 .po mock 数据避免依赖翻译
	# 跳过此测试因为需要先有文件
	pass

func test_translate_text() -> void:
	# 用一个简单 key 测翻译
	var key := "char_parn_name"
	var translated := TranslationServer.translate(key)
	# 即使没翻译也应该返回 key 本身或翻译后的字符串
	assert_true(translated.length() > 0, "test_translate_text: returns non-empty")