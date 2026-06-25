class_name DialogueParser
extends RefCounted

## 对话 JSON 解析器
## JSON 格式：
## {
##   "id": "npc_ehto_intro",
##   "speaker": "ehto",
##   "portrait": "ehto_neutral",
##   "nodes": [
##     { "id": "start", "text_key": "hello", "next": "end" },
##     { "id": "end", "type": "end" }
##   ]
## }

var id: String = ""
var speaker: String = ""
var portrait: String = ""
var nodes: Dictionary = {}  # node_id -> node_dict

func _init(data: Dictionary) -> void:
	id = data.get("id", "")
	speaker = data.get("speaker", "")
	portrait = data.get("portrait", "")
	var raw_nodes = data.get("nodes", [])
	if raw_nodes is Array:
		# 旧格式: [{id: "x", ...}, ...]
		for n in raw_nodes:
			if n.has("id"):
				nodes[n["id"]] = n
	elif raw_nodes is Dictionary:
		# 新格式: {x: {...}, y: {...}}
		for key in raw_nodes:
			nodes[key] = raw_nodes[key]

func get_node(node_id: String) -> Dictionary:
	return nodes.get(node_id, {})

func get_next_id(node_id: String) -> String:
	var n = nodes.get(node_id, {})
	return n.get("next", "")

func is_end(node_id: String) -> bool:
	var n = nodes.get(node_id, {})
	return n.get("type", "") == "end"

func get_text(node_id: String) -> String:
	var n = nodes.get(node_id, {})
	var key = n.get("text_key", "")
	if key == "":
		return ""
	return TranslationServer.translate(key)

func get_choice_labels(node_id: String) -> Array[String]:
	var n = nodes.get(node_id, {})
	var result: Array[String] = []
	for c in n.get("choices", []):
		var key = c.get("label_key", "")
		result.append(TranslationServer.translate(key))
	return result

func get_choice_targets(node_id: String) -> Array[String]:
	var n = nodes.get(node_id, {})
	var result: Array[String] = []
	for c in n.get("choices", []):
		result.append(c.get("next", ""))
	return result

static func load_from_file(path: String) -> RefCounted:
	var self_script = load("res://scripts/systems/dialogue_parser.gd")
	if not FileAccess.file_exists(path):
		push_error("Dialogue file not found: %s" % path)
		return self_script.new({})
	var f = FileAccess.open(path, FileAccess.READ)
	var text = f.get_as_text()
	var data = JSON.parse_string(text)
	if data == null:
		push_error("Dialogue JSON parse error: %s" % path)
		return self_script.new({})
	return self_script.new(data)
