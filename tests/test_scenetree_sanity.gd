extends SceneTree

func _init() -> void:
	print("HELLO FROM SCENETREE")
	# 测试 process 循环
	for i in 3:
		print("Frame: %d" % i)
		await process_frame
	print("DONE")
	quit(0)
