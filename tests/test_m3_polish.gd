extends SceneTree

## M3 Steam 美术升级测试

var _passed: int = 0
var _failed: int = 0

func _init() -> void:
	test_asset_loader_fallback()
	test_asset_loader_path_helper()
	test_camera_shake_creation()
	test_camera_shake_decay()
	test_floating_text_creation()
	test_ai_image_generator_url()
	test_world_environment_creation()
	print("\n=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		quit(1)
	else:
		quit(0)

func assert_eq(value, expected, msg: String) -> void:
	if value == expected:
		_passed += 1
		print("PASS: %s" % msg)
	else:
		_failed += 1
		print("FAIL: %s (got %s, expected %s)" % [msg, str(value), str(expected)])

func assert_true(value: bool, msg: String) -> void:
	assert_eq(value, true, msg)

func test_asset_loader_fallback() -> void:
	AssetLoader.clear_cache()
	# 不存在的文件
	var tex = AssetLoader.get_texture("res://assets/nonexistent.png")
	assert_true(tex != null, "fallback returns texture")
	assert_eq(tex.get_width(), 64, "fallback is 64px wide")
	assert_eq(tex.get_height(), 64, "fallback is 64px tall")

func test_asset_loader_path_helper() -> void:
	var path = AssetLoader.sprite_data_to_path("parn")
	assert_eq(path, "res://assets/sprites/parn.jpg", "parn -> parn.jpg path")
	var has = AssetLoader.has_asset("res://assets/nonexistent.png")
	assert_true(not has, "has_asset false for missing")

func test_camera_shake_creation() -> void:
	var cs = CameraShake.new()
	assert_true(cs != null, "CameraShake created")
	assert_eq(cs.trauma, 0.0, "initial trauma 0")
	cs.add_trauma(0.5)
	assert_eq(cs.trauma, 0.5, "trauma set to 0.5")
	cs.add_trauma(0.7)
	assert_eq(cs.trauma, 1.0, "trauma clamped to 1.0")

func test_camera_shake_decay() -> void:
	var cs = CameraShake.new()
	cs.add_trauma(0.5)
	# 模拟时间
	cs._process(0.1)
	assert_true(cs.trauma < 0.5, "trauma decays after 0.1s (got %f)" % cs.trauma)

func test_floating_text_creation() -> void:
	var ft = FloatingText.new()
	assert_true(ft != null, "FloatingText created")
	ft.setup("-25", Color.RED, false)
	assert_eq(ft.text, "-25", "damage text set")
	ft.setup("CRIT! -100", Color.YELLOW, true)
	assert_eq(ft.text, "CRIT! -100", "crit text set")
	assert_eq(ft.float_speed, 100.0, "crit float_speed 100")

func test_ai_image_generator_url() -> void:
	var gen = AIImageGenerator.new()
	assert_true(gen.API_BASE.begins_with("https://"), "API uses https")
	assert_true(gen.API_BASE.ends_with("text_to_image"), "API path correct")
	# prompt 模板
	var char_p = AIImageGenerator.character_prompt("Parn", "young warrior, blue armor, sword")
	assert_true(char_p.find("pixel art") >= 0, "char prompt has pixel art")
	var enemy_p = AIImageGenerator.enemy_prompt("Orc", "orc warrior, brown skin, club")
	assert_true(enemy_p.find("monster") >= 0, "enemy prompt has monster")
	var tile_p = AIImageGenerator.tile_prompt("grass")
	assert_true(tile_p.find("seamless") >= 0, "tile prompt has seamless")

func test_world_environment_creation() -> void:
	var WorldEnv = load("res://scripts/world/world_environment.gd")
	assert_true(WorldEnv != null, "WorldEnvironment script loads")
	var we = WorldEnv.new()
	we.scene_type = "town"
	get_root().add_child(we)
	await process_frame
	assert_true(we.env != null, "env created")
	assert_true(we.env.glow_enabled, "glow enabled")
	assert_true(we.env.ssao_enabled, "SSAO enabled")
	assert_true(we.env.fog_enabled, "fog enabled")