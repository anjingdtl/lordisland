class_name PartyManager
extends RefCounted

## 队伍管理
## 维护当前 party、队员 HP/MP、加入/移除

var event_system: EventSystem
var members: Array[String] = []  # 角色 id 列表
var party_data: Dictionary = {}  # character_id -> actor_data（动态更新）

func _init(es: EventSystem) -> void:
	event_system = es

func add_member(character_id: String) -> bool:
	if character_id in members:
		return false
	members.append(character_id)
	# 加载角色数据
	var path = "res://data/characters/%s.json" % character_id
	if FileAccess.file_exists(path):
		var f = FileAccess.open(path, FileAccess.READ)
		party_data[character_id] = JSON.parse_string(f.get_as_text())
	event_system.set_flag("party_has_%s" % character_id, true)
	return true

func remove_member(character_id: String) -> bool:
	var idx = members.find(character_id)
	if idx == -1:
		return false
	members.remove_at(idx)
	party_data.erase(character_id)
	event_system.set_flag("party_has_%s" % character_id, false)
	return true

func has_member(character_id: String) -> bool:
	return character_id in members

func get_member_data(character_id: String) -> Dictionary:
	return party_data.get(character_id, {})

func get_member_ids() -> Array[String]:
	return members.duplicate()

## 从存档恢复
func restore(member_ids: Array, members_data: Dictionary) -> void:
	members = member_ids.duplicate()
	party_data = members_data.duplicate(true)

## 序列化为存档数据
func to_dict() -> Dictionary:
	return {
		"members": members,
		"party_data": party_data
	}

func get_size() -> int:
	return members.size()

func is_empty() -> bool:
	return members.is_empty()

func reset() -> void:
	members.clear()
	party_data.clear()