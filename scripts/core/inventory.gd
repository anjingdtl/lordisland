class_name Inventory
extends RefCounted

## 物品库存 + 金币管理
## 全局单例，由 EventSystem 持久化

var items: Dictionary = {}  # item_id -> count
var gold: int = 100

## 加物品（堆叠）
func add_item(item_id: String, count: int = 1) -> void:
	items[item_id] = items.get(item_id, 0) + count

## 移除物品
func remove_item(item_id: String, count: int = 1) -> bool:
	var cur = items.get(item_id, 0)
	if cur < count:
		return false
	items[item_id] = cur - count
	if items[item_id] <= 0:
		items.erase(item_id)
	return true

## 查询数量
func has_item(item_id: String) -> bool:
	return items.get(item_id, 0) > 0

func count_item(item_id: String) -> int:
	return items.get(item_id, 0)

## 金币
func add_gold(amount: int) -> void:
	gold += amount

func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	return true

## 序列化（存档）
func to_dict() -> Dictionary:
	return {"items": items, "gold": gold}

## 从存档恢复
func restore(data: Dictionary) -> void:
	items = data.get("items", {}).duplicate(true)
	gold = data.get("gold", 100)

## 重置
func reset() -> void:
	items.clear()
	gold = 100

## 物品转字符串
func list_items() -> Array:
	var result: Array = []
	for id in items:
		if items[id] > 0:
			result.append({"id": id, "count": items[id]})
	return result