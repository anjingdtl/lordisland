extends SceneTree

## M3 Steam 美术升级测试

const AIImageGenerator = preload("res://scripts/core/ai_image_generator.gd")
const AssetLoader = preload("res://scripts/core/asset_loader.gd")
const BattleUI = preload("res://scripts/ui/battle_ui.gd")
const CameraShake = preload("res://scripts/core/camera_shake.gd")
const DialogueParser = preload("res://scripts/systems/dialogue_parser.gd")
const DialogueUI = preload("res://scripts/ui/dialogue_ui.gd")
const FloatingText = preload("res://scripts/ui/floating_text.gd")

var _passed: int = 0
var _failed: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	test_asset_loader_fallback()
	test_asset_loader_path_helper()
	test_camera_shake_creation()
	test_camera_shake_decay()
	test_floating_text_creation()
	test_ai_image_generator_url()
	await test_world_environment_creation()
	await test_dialogue_ui_has_portrait_and_typewriter()
	await test_battle_ui_has_visual_status_bars()
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
	ft.free()

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
	we.queue_free()
	await process_frame

func test_dialogue_ui_has_portrait_and_typewriter() -> void:
	var parser = DialogueParser.load_from_file("res://data/dialogues/npc_ehto_intro.json")
	var ui = DialogueUI.new()
	get_root().add_child(ui)
	await process_frame
	ui.start_dialogue(parser)
	await process_frame
	var portrait = ui.find_child("Portrait", true, false)
	var body = ui.find_child("BodyText", true, false)
	assert_true(portrait is TextureRect, "DialogueUI creates Portrait TextureRect")
	assert_true(body is RichTextLabel, "DialogueUI creates BodyText RichTextLabel")
	if portrait is TextureRect and portrait.texture != null:
		assert_eq(portrait.texture.get_width(), 1024, "DialogueUI prefers full character illustration for Ehto")
	if body is RichTextLabel:
		assert_true(body.visible_characters >= 0 and body.visible_characters < body.get_total_character_count(), "DialogueUI starts typewriter with partial text")
	ui.queue_free()
	await process_frame

func test_battle_ui_has_visual_status_bars() -> void:
	var ui = BattleUI.new()
	get_root().add_child(ui)
	await process_frame
	assert_true(ui.has_method("set_party"), "BattleUI exposes set_party")
	assert_true(ui.has_method("set_enemies"), "BattleUI exposes set_enemies")
	if ui.has_method("set_party") and ui.has_method("set_enemies"):
		ui.set_party([
			{"name": "Parn", "hp": 80, "max_hp": 120, "mp": 12, "max_mp": 20},
			{"name": "Ehto", "hp": 60, "max_hp": 80, "mp": 30, "max_mp": 40}
		])
		ui.set_enemies([
			{"name": "Goblin", "hp": 20, "max_hp": 35}
		])
		await process_frame
		var bars = _find_children_by_class(ui, "ProgressBar")
		assert_true(bars.size() >= 5, "BattleUI creates HP/MP progress bars for party and enemies")
	ui.queue_free()
	await process_frame

func _find_children_by_class(node: Node, wanted_class: String) -> Array:
	var result: Array = []
	for child in node.get_children():
		if child.get_class() == wanted_class:
			result.append(child)
		result.append_array(_find_children_by_class(child, wanted_class))
	return result
