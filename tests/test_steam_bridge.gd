extends SceneTree

## Steamworks 集成测试
## 验证 SteamBridge 在没有 GodotSteam 插件时的 stub 模式安全

const SB_PATH := "res://scripts/core/steam_bridge.gd"

var passed := 0
var failed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== Steam 集成测试 ===")
	# 加载并实例化
	var script = load(SB_PATH)
	if script == null:
		print("[FAIL] script load")
		failed += 1
		quit(1)
		return
	var bridge = script.new()
	root.add_child(bridge)
	await process_frame
	# 验证降级：play offline
	bridge.unlock_achievement("test_ach")
	bridge.set_stat("test_stat", 42)
	bridge.unlock_by_chapter("ch0_rescue_ehto")
	print("[PASS] SteamBridge stub mode works")
	passed += 1
	# 验证 ACHIEVEMENTS 常量
	if bridge.ACHIEVEMENTS.size() >= 5:
		print("[PASS] ACHIEVEMENTS has >=5 entries (got %d)" % bridge.ACHIEVEMENTS.size())
		passed += 1
	else:
		print("[FAIL] ACHIEVEMENTS too few")
		failed += 1
	# 验证 get_steam_user_name 安全返回
	var name = bridge.get_steam_user_name()
	if name == "Player":
		print("[PASS] get_steam_user_name safe default")
		passed += 1
	else:
		print("[FAIL] get_steam_user_name unexpected: %s" % name)
		failed += 1
	bridge.shutdown()
	bridge.queue_free()
	print("=== RESULT: %d passed, %d failed ===" % [passed, failed])
	quit(failed)