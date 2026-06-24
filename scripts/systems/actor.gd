class_name Actor
extends RefCounted

## 战斗角色数据模型
## 加载自 data/characters/*.json 或 data/enemies.json
## 所有数值可被 buff 临时修改

var id: String
var name_key: String
var level: int
var max_hp: int
var hp: int
var max_mp: int
var mp: int
var base_str: int
var base_agi: int
var base_int: int
var base_vit: int
var base_cha: int
var skills: Array = []
var sprite_path: String
var exp_reward: int = 0
var is_alive: bool = true
var is_player: bool = false

# 状态效果（key -> {stat: str, amount: int, duration: int}）
var status_effects: Dictionary = {}

func _init(data: Dictionary) -> void:
	id = data.get("id", "")
	name_key = data.get("name_key", "")
	level = data.get("level", 1)
	max_hp = data.get("hp", data.get("max_hp", 100))
	hp = max_hp
	max_mp = data.get("mp", data.get("max_mp", 20))
	mp = max_mp
	base_str = data.get("str", 10)
	base_agi = data.get("agi", 10)
	base_int = data.get("int", 10)
	base_vit = data.get("vit", 10)
	base_cha = data.get("cha", 10)
	skills = data.get("skills", ["attack"])
	sprite_path = data.get("sprite", "")
	exp_reward = data.get("exp_reward", 0)
	is_player = data.get("is_player", false)

## 计算后的属性（含 buff）
func str_total() -> int: return base_str + _buff_total("str")
func agi_total() -> int: return base_agi + _buff_total("agi")
func int_total() -> int: return base_int + _buff_total("int")
func vit_total() -> int: return base_vit + _buff_total("vit")
func cha_total() -> int: return base_cha + _buff_total("cha")

func _buff_total(stat: String) -> int:
	var total := 0
	for key in status_effects:
		var eff = status_effects[key]
		if eff.get("stat", "") == stat:
			total += eff.get("amount", 0)
	return total

## 添加状态效果
func add_status(effect_id: String, stat: String, amount: int, duration: int) -> void:
	status_effects[effect_id] = {"stat": stat, "amount": amount, "duration": duration}

## 移除状态效果
func remove_status(effect_id: String) -> void:
	status_effects.erase(effect_id)

## 回合结束：所有状态效果 duration - 1，duration <= 0 则移除
func tick_status() -> Array[String]:
	var expired: Array[String] = []
	for key in status_effects:
		var eff = status_effects[key]
		eff["duration"] -= 1
		if eff["duration"] <= 0:
			expired.append(key)
	for k in expired:
		remove_status(k)
	return expired

## 受到伤害
func take_damage(amount: int) -> int:
	# 防御减免（已由公式处理），此处只做血量计算
	hp = max(0, hp - amount)
	if hp == 0:
		is_alive = false
	return amount

## 治疗
func heal(amount: int) -> int:
	var before = hp
	hp = min(max_hp, hp + amount)
	return hp - before

## 显示名（用 i18n key）
func display_name() -> String:
	if TranslationServer:
		return TranslationServer.translate(name_key)
	return name_key
