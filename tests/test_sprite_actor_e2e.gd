extends SceneTree

const Sprite3DActor = preload("res://scripts/world/sprite3d_actor.gd")

var _passed: int = 0
var _failed: int = 0

func _init() -> void:
	await _run_all()
	print("\n=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		quit(1)
	else:
		quit(0)

func _run_all() -> void:
	await test_actor_has_sprite_child()
	await test_actor_creates_sprite_from_data()
	await test_actor_sprite_has_texture()
	await test_actor_flip_method()

func assert_true(value: bool, msg: String) -> void:
	if value:
		_passed += 1
		print("PASS: %s" % msg)
	else:
		_failed += 1
		print("FAIL: %s" % msg)

func test_actor_has_sprite_child() -> void:
	var actor = Sprite3DActor.new()
	actor.sprite_data = {"body_color": "#2a4d8f", "hair_color": "#f0c419", "skin_color": "#fbcb8a"}
	get_root().add_child(actor)
	await process_frame
	var has_sprite = false
	for child in actor.get_children():
		if child is Sprite3D:
			has_sprite = true
	assert_true(has_sprite, "actor has Sprite3D child")

func test_actor_creates_sprite_from_data() -> void:
	var actor = Sprite3DActor.new()
	actor.sprite_data = {"body_color": "#2a4d8f", "hair_color": "#f0c419", "skin_color": "#fbcb8a"}
	get_root().add_child(actor)
	await process_frame
	var found = false
	for child in actor.get_children():
		if child is Sprite3D and child.texture != null:
			found = true
	assert_true(found, "Sprite3D has valid texture")

func test_actor_sprite_has_texture() -> void:
	var actor = Sprite3DActor.new()
	get_root().add_child(actor)
	await process_frame
	var found = false
	for child in actor.get_children():
		if child is Sprite3D and child.texture != null:
			found = true
	assert_true(found, "default sprite still has texture")

func test_actor_flip_method() -> void:
	var actor = Sprite3DActor.new()
	actor.sprite_data = {"body_color": "#2a4d8f"}
	get_root().add_child(actor)
	await process_frame
	actor.flip_horizontal(true)
	assert_true(actor.facing_right == false, "facing_right updated after flip")
	actor.flip_horizontal(false)
	assert_true(actor.facing_right == true, "facing_right updated back")