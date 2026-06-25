extends SceneTree

## Godot 引擎 sanity 测试：场景树能正常启动 + process_frame 循环

func _init() -> void:
	print("HELLO FROM SCENETREE")
	for i in 3:
		print("Frame: %d" % i)
		await process_frame
	print("DONE")
	print("=== RESULT: 3 passed, 0 failed ===")
	quit(0)