extends SceneTree

const SpriteGenerator = preload("res://scripts/core/sprite_generator.gd")

var _passed: int = 0
var _failed: int = 0

func _init() -> void:
	test_generate_returns_texture()
	test_walk_strip_dimensions()
	test_walk_frames_distinct()
	test_palette_used()
	test_empty_data_returns_texture()
	test_partial_data_uses_defaults()
	print("\n=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		quit(1)
	else:
		quit(0)

func assert_true(value: bool, msg: String) -> void:
	if value:
		_passed += 1
		print("PASS: %s" % msg)
	else:
		_failed += 1
		print("FAIL: %s" % msg)

func test_generate_returns_texture() -> void:
	var gen = SpriteGenerator.new()
	var data = {"body_color": "#2a4d8f", "hair_color": "#f0c419", "skin_color": "#fbcb8a", "weapon": "sword"}
	var tex = gen.generate_static(data)
	assert_true(tex != null, "generate_static returns non-null")
	assert_true(tex is ImageTexture, "result is ImageTexture")

func test_walk_strip_dimensions() -> void:
	var gen = SpriteGenerator.new()
	var data = {"body_color": "#2a4d8f", "hair_color": "#f0c419", "skin_color": "#fbcb8a"}
	var tex = gen.generate_walk_strip(data)
	var img = tex.get_image()
	assert_true(img.get_width() == 128, "strip width = 128, got %d" % img.get_width())
	assert_true(img.get_height() == 48, "strip height = 48, got %d" % img.get_height())

func test_walk_frames_distinct() -> void:
	var gen = SpriteGenerator.new()
	var data = {"body_color": "#2a4d8f", "hair_color": "#f0c419", "skin_color": "#fbcb8a"}
	var tex = gen.generate_walk_strip(data)
	var img = tex.get_image()
	# 帧 1 (strip x 32-63) 在 (42, 40) = (10, 40) in frame: 有腿
	# 帧 2 (strip x 64-95) 在 (74, 40) = (10, 40) in frame: 无腿
	var px1 = img.get_pixel(42, 40)
	var px2 = img.get_pixel(74, 40)
	assert_true(px1 != px2, "frame 1 and 2 differ at (10,40) (px1=%s px2=%s)" % [str(px1), str(px2)])

func test_palette_used() -> void:
	var gen = SpriteGenerator.new()
	var data = {"body_color": "#2a4d8f", "hair_color": "#f0c419", "skin_color": "#fbcb8a"}
	var tex = gen.generate_static(data)
	var img = tex.get_image()
	var found_blue = false
	var found_yellow = false
	for y in 48:
		for x in 32:
			var px = img.get_pixel(x, y)
			if px.b > 0.4 and px.r < 0.3:
				found_blue = true
			if px.r > 0.8 and px.g > 0.6 and px.b < 0.3:
				found_yellow = true
	assert_true(found_blue, "body color (blue) used")
	assert_true(found_yellow, "hair color (yellow) used")

func test_empty_data_returns_texture() -> void:
	var gen = SpriteGenerator.new()
	var tex = gen.generate_static({})
	assert_true(tex != null, "empty data still returns texture")

func test_partial_data_uses_defaults() -> void:
	var gen = SpriteGenerator.new()
	var tex = gen.generate_static({"hair_color": "#ff0000"})
	var img = tex.get_image()
	var found_blue = false
	for y in 48:
		for x in 32:
			var px = img.get_pixel(x, y)
			if px.b > 0.4 and px.r < 0.3:
				found_blue = true
	assert_true(found_blue, "default body color used when data partial")