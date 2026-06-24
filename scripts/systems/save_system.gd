class_name SaveSystem
extends RefCounted

## 存档系统
## 设计文档 §7：完全自由存档，无时机/次数限制
## 10 个槽位，JSON 序列化
## user:// 目录下（Godot 自动管理）

const SAVE_DIR := "user://saves/"

var data: Dictionary = {}

## 设置顶级字段
func set_value(key: String, value) -> void:
	data[key] = value

## 获取顶级字段
func get_value(key: String):
	return data.get(key, null)

## 设置嵌套字段（dict.list[idx].field）
func set_nested(path: String, key: String, value) -> void:
	if not data.has(path):
		data[path] = {}
	if data[path] is Dictionary:
		data[path][key] = value

## 获取嵌套字段
func get_nested(path: String, key: String):
	var d = data.get(path, null)
	if d is Dictionary:
		return d.get(key, null)
	return null

## 保存到指定槽
func save_to_slot(slot: int) -> bool:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		var err = DirAccess.make_dir_recursive_absolute(SAVE_DIR)
		if err != OK:
			push_error("Cannot create save dir: %s" % SAVE_DIR)
			return false
	var path = "%ssave_%d.json" % [SAVE_DIR, slot]
	var f = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("Cannot open save file: %s" % path)
		return false
	var stamp = Time.get_datetime_string_from_system()
	var payload = data.duplicate(true)
	payload["_timestamp"] = stamp
	payload["_version"] = "1.0"
	f.store_string(JSON.stringify(payload))
	f.close()
	return true

## 从指定槽加载
func load_from_slot(slot: int) -> bool:
	var path = "%ssave_%d.json" % [SAVE_DIR, slot]
	if not FileAccess.file_exists(path):
		return false
	var f = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var text = f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if parsed == null:
		push_error("Save file corrupted: %s" % path)
		return false
	data = parsed
	return true

func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists("%ssave_%d.json" % [SAVE_DIR, slot])

func delete_slot(slot: int) -> bool:
	var path = "%ssave_%d.json" % [SAVE_DIR, slot]
	if not FileAccess.file_exists(path):
		return false
	return DirAccess.remove_absolute(path) == OK

func get_slot_info(slot: int) -> Dictionary:
	var path = "%ssave_%d.json" % [SAVE_DIR, slot]
	if not FileAccess.file_exists(path):
		return {"exists": false}
	var f = FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text())
	return {
		"exists": true,
		"timestamp": parsed.get("_timestamp", "?"),
		"chapter": parsed.get("chapter", "?"),
		"player_pos": parsed.get("player_pos", Vector2.ZERO)
	}

func reset() -> void:
	data.clear()