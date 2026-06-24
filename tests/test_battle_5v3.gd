extends SceneTree

## 5v3 战斗测试：用 main loop 驱动战斗异步进行

const LOG_PATH := "user://battle_test.log"

func _init() -> void:
	# 清空日志
	var f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	f.store_string("")
	f.close()
	_log("=== Battle test start ===")
	var driver_script = preload("res://scripts/systems/battle_driver.gd")
	var driver = driver_script.new()
	get_root().add_child(driver)
	driver.run()
	# 等待 driver 内部 quit 自己
	# 设超时保护：30 秒后强制退出
	var t = Timer.new()
	t.wait_time = 30.0
	t.one_shot = true
	t.autostart = true
	t.timeout.connect(func():
		_log("=== TIMEOUT ===")
		quit(2)
	)
	get_root().add_child(t)

func _log(msg: String) -> void:
	print(msg)
	var f = FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
	if f == null:
		return
	f.seek_end()
	f.store_line(msg)
	f.close()