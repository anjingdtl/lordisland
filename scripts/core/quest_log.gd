class_name QuestLog
extends RefCounted

## 任务日志
## 跟踪任务进度
## 任务定义在 data/quests.json
## 进度通过 EventSystem 的 flag 跟踪

var quest_data: Dictionary = {}
var active_quests: Array = []  # quest_id
var completed_quests: Array = []

func _init(es: RefCounted) -> void:
	_load_data(es)

func _load_data(_es: RefCounted) -> void:
	var f = FileAccess.open("res://data/quests.json", FileAccess.READ)
	if f == null:
		return
	quest_data = JSON.parse_string(f.get_as_text())

## 接受任务（加入 active）
func accept(quest_id: String) -> bool:
	if quest_id in active_quests or quest_id in completed_quests:
		return false
	if not quest_data.has(quest_id):
		return false
	active_quests.append(quest_id)
	# 触发 accepted flag
	return true

## 完成任务
func complete(quest_id: String) -> bool:
	if quest_id not in active_quests:
		return false
	active_quests.erase(quest_id)
	completed_quests.append(quest_id)
	# TODO: 发奖励
	return true

## 检查任务是否完成（所有 objective flag 都满足）
func is_complete(quest_id: String) -> bool:
	var q = quest_data.get(quest_id, null)
	if q == null:
		return false
	# 检查 complete_flag
	var complete_flag = q.get("complete_flag", "")
	if complete_flag == "":
		return false
	# 这里简化：complete_flag 由外部事件设置
	# 任务在外部 trigger complete 后调用 quest_log.complete()
	return false

## 序列化
func to_dict() -> Dictionary:
	return {
		"active": active_quests,
		"completed": completed_quests
	}

func restore(data: Dictionary) -> void:
	active_quests = data.get("active", []).duplicate()
	completed_quests = data.get("completed", []).duplicate()

func reset() -> void:
	active_quests.clear()
	completed_quests.clear()

## 查询
func is_active(quest_id: String) -> bool:
	return quest_id in active_quests

func is_completed(quest_id: String) -> bool:
	return quest_id in completed_quests

func get_quest(quest_id: String) -> Dictionary:
	return quest_data.get(quest_id, {})
