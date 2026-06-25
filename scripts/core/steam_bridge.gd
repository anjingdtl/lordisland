extends Node

## Steamworks SDK 集成桩（Godot 4.3）
## 真实环境需 GodotSteam 插件：https://github.com/CoaguCo-Industries/GodotSteam
## 离线/无 Steam 环境：所有调用安全降级到 print log
## Steam 上线前必须：
##   1. 安装 GodotSteam 插件到 addons/godotsteam/
##   2. 在 Project Settings → Plugins 启用
##   3. 把 appid 改成真实 Steam app id

const APP_ID := 480  # 默认测试 app id（Spacewar）

var _is_steam_available: bool = false

func _ready() -> void:
	# 检查 Steam 是否可用（通过 GodotSteam 插件）
	if Engine.has_singleton("Steam"):
		_is_steam_available = true
		print("[Steam] GodotSteam plugin detected")
		_init_steam()
	else:
		print("[Steam] GodotSteam not available, using stub mode")

func _init_steam() -> void:
	var Steam = Engine.get_singleton("Steam")
	if Steam == null:
		_is_steam_available = false
		return
	var init_result = Steam.steamInit()
	if init_result == Steam.STEAM_API_INIT_RESULT_OK:
		print("[Steam] Initialized successfully, AppID=%d" % APP_ID)
	else:
		print("[Steam] Init failed (result=%d), running offline" % init_result)
		_is_steam_available = false

func unlock_achievement(achievement_id: String) -> void:
	if _is_steam_available:
		var Steam = Engine.get_singleton("Steam")
		if Steam:
			Steam.setAchievement(achievement_id)
			Steam.storeStats()
			print("[Steam] Achievement unlocked: %s" % achievement_id)
	else:
		print("[Achievement-STUB] unlocked: %s" % achievement_id)

func reset_achievements() -> void:
	if _is_steam_available:
		var Steam = Engine.get_singleton("Steam")
		if Steam:
			Steam.resetAllStats(true)
			print("[Steam] All achievements reset")

func set_stat(stat_name: String, value: int) -> void:
	if _is_steam_available:
		var Steam = Engine.get_singleton("Steam")
		if Steam:
			Steam.setStat(stat_name, value)

func get_stat(stat_name: String) -> int:
	if _is_steam_available:
		var Steam = Engine.get_singleton("Steam")
		if Steam:
			return Steam.getStatInt(stat_name)
	return 0

func is_achievement_unlocked(achievement_id: String) -> bool:
	if _is_steam_available:
		var Steam = Engine.get_singleton("Steam")
		if Steam:
			return Steam.getAchievement(achievement_id)["achieved"]
	return false

func get_steam_user_name() -> String:
	if _is_steam_available:
		var Steam = Engine.get_singleton("Steam")
		if Steam:
			return Steam.getPersonaName()
	return "Player"

func shutdown() -> void:
	if _is_steam_available:
		var Steam = Engine.get_singleton("Steam")
		if Steam:
			Steam.steamShutdown()

## Steam 成就定义（应在 Steamworks 后台同步）
const ACHIEVEMENTS := {
	"first_battle": "初战告捷 - 赢得第一场战斗",
	"first_join": "志同道合 - 第一位伙伴加入",
	"chapter_0_complete": "序章完成 - 救回艾特",
	"first_purchase": "首次购物 - 在商店购买物品",
	"first_death": "挫折教育 - 队伍全灭一次",
	"boss_troll": "巨魔克星 - 击败巨魔 Boss",
	"explorer": "探索者 - 访问所有 3 个地图",
	"collector": "收藏家 - 收集 10 种物品",
	"save_master": "存档大师 - 进行 10 次存档",
}

func unlock_by_chapter(chapter_id: String) -> void:
	match chapter_id:
		"ch0_rescue_ehto":
			unlock_achievement("chapter_0_complete")
			unlock_achievement("first_join")