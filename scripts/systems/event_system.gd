class_name EventSystem
extends RefCounted

## 事件系统
## 支持多种 trigger 类型：on_talk / on_flag_set / on_enter_map / on_battle_end 等
## 支持 conditions（flag、item 等条件）
## 触发回调以 Callable 形式传入

var listeners: Dictionary = {}  # trigger_type -> [{key, callback, conditions}]
var flags: Dictionary = {}
var counters: Dictionary = {}

func register(trigger_type: String, key: String, callback: Callable, conditions: Array = []) -> void:
	if not listeners.has(trigger_type):
		listeners[trigger_type] = []
	listeners[trigger_type].append({
		"key": key,
		"callback": callback,
		"conditions": conditions
	})

func trigger(trigger_type: String, key: String = "", context: Dictionary = {}) -> void:
	if not listeners.has(trigger_type):
		return
	for entry in listeners[trigger_type]:
		if key != "" and entry["key"] != key:
			continue
		if not _check_conditions(entry["conditions"]):
			continue
		entry["callback"].call(context)

func _check_conditions(conditions: Array) -> bool:
	for c in conditions:
		match c.get("type", ""):
			"flag":
				if flags.get(c["key"], null) != c.get("value", null):
					return false
			"not_flag":
				if flags.get(c["key"], null) == c.get("value", null):
					return false
			"item":
				pass  # TODO: 物品条件
	return true

func set_flag(key: String, value) -> void:
	var old = flags.get(key, null)
	flags[key] = value
	# 如果是 false→true 才触发 on_flag_set
	if old != value:
		trigger("on_flag_set", key, {"key": key, "value": value})

func get_flag(key: String):
	return flags.get(key, null)

func has_flag(key: String, value = true) -> bool:
	return flags.get(key, null) == value

## Counter API（用于任务计数等）
func set_counter(key: String, value: int) -> void:
	counters[key] = value

func get_counter(key: String) -> int:
	return int(counters.get(key, 0))

func inc_counter(key: String, amount: int = 1) -> int:
	counters[key] = int(counters.get(key, 0)) + amount
	return counters[key]

func reset() -> void:
	listeners.clear()
	flags.clear()
	counters.clear()