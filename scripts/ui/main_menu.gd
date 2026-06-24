class_name MainMenu
extends Control

## 主菜单（升级版）：logo + 背景 + 按钮
## UI 程序化构建

signal new_game_pressed
signal continue_pressed
signal load_pressed
signal settings_pressed
signal quit_pressed

var _has_save: bool = false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_background()
	_build_logo()
	_build_buttons()
	_check_save()

func _build_background() -> void:
	# 背景图（AI 生成）
	var bg_tex = AssetLoader.get_texture("res://assets/title_bg.jpg")
	if bg_tex != null:
		var bg = TextureRect.new()
		bg.texture = bg_tex
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(bg)
	# 暗色覆盖
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

func _build_logo() -> void:
	# Logo 图
	var logo_tex = AssetLoader.get_texture("res://assets/logo.jpg")
	if logo_tex != null:
		var logo = TextureRect.new()
		logo.texture = logo_tex
		logo.custom_minimum_size = Vector2(600, 600)
		logo.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo.set_anchors_preset(Control.PRESET_TOP_WIDE)
		logo.anchor_top = 0.05
		logo.anchor_bottom = 0.05
		logo.anchor_left = 0.5
		logo.anchor_right = 0.5
		logo.position = Vector2(-300, 0)
		add_child(logo)
	# 标题文字
	var title = Label.new()
	title.text = "罗德岛战记"
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position.y = 620
	title.add_theme_font_size_override("font_size", 56)
	title.modulate = Color(1, 0.85, 0.5, 1)
	add_child(title)
	var subtitle = Label.new()
	subtitle.text = "Record of Lodoss War 2D RPG"
	subtitle.set_anchors_preset(Control.PRESET_TOP_WIDE)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.position.y = 690
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.modulate = Color(0.8, 0.8, 0.9, 1)
	add_child(subtitle)

func _build_buttons() -> void:
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.anchor_left = 0.5
	vbox.anchor_right = 0.5
	vbox.anchor_top = 0.7
	vbox.anchor_bottom = 0.7
	vbox.position = Vector2(-150, 0)
	vbox.custom_minimum_size = Vector2(300, 0)
	vbox.add_theme_constant_override("separation", 12)
	add_child(vbox)
	for label in ["ui_new_game", "ui_continue", "ui_load", "ui_settings", "ui_quit"]:
		var btn = Button.new()
		btn.text = TranslationServer.translate(label)
		btn.custom_minimum_size = Vector2(280, 48)
		btn.add_theme_font_size_override("font_size", 22)
		match label:
			"ui_new_game": btn.pressed.connect(_on_new_game)
			"ui_continue": btn.pressed.connect(_on_continue); btn.name = "BtnContinue"
			"ui_load": btn.pressed.connect(_on_load)
			"ui_settings": btn.pressed.connect(_on_settings)
			"ui_quit": btn.pressed.connect(_on_quit)
		vbox.add_child(btn)
	# 版本号
	var version = Label.new()
	version.text = "v0.3.0 M3"
	version.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	version.position = Vector2(-100, -30)
	version.modulate = Color(0.6, 0.6, 0.6, 1)
	add_child(version)

func _check_save() -> void:
	for i in 10:
		if FileAccess.file_exists("user://saves/save_%d.json" % i):
			_has_save = true
			return
	var btn = get_node_or_null("BtnContinue")
	if btn:
		btn.disabled = true
		btn.text = TranslationServer.translate("ui_continue") + " (*)"
	# 异步找
	if has_node("BtnContinue"):
		var btn2 = get_node("BtnContinue")
		btn2.disabled = true
		btn2.text = TranslationServer.translate("ui_continue") + " (无存档)"

func _on_new_game() -> void:
	new_game_pressed.emit()
	_start_new_game()

func _on_continue() -> void:
	continue_pressed.emit()
	for i in range(9, -1, -1):
		if FileAccess.file_exists("user://saves/save_%d.json" % i):
			_load_slot(i)
			return

func _on_load() -> void:
	load_pressed.emit()
	var selector_script = load("res://scripts/ui/save_load_ui.gd")
	var selector = selector_script.new()
	add_child(selector)
	selector.slot_selected.connect(_load_slot)
	selector.cancelled.connect(func(): selector.queue_free())

func _on_settings() -> void:
	settings_pressed.emit()
	# TODO: 设置

func _on_quit() -> void:
	quit_pressed.emit()
	get_tree().quit()

func _start_new_game() -> void:
	var globals = _get_globals()
	if globals:
		globals.event_system.reset()
		if globals.party_manager.has_method("reset"):
			globals.party_manager.reset()
		globals.party_manager.add_member("parn")
		if globals.inventory.has_method("reset"):
			globals.inventory.reset()
		if globals.quest_log.has_method("reset"):
			globals.quest_log.reset()
	get_tree().change_scene_to_file("res://scenes/world/loranai_city.tscn")

func _load_slot(slot: int) -> void:
	var globals = _get_globals()
	if not globals:
		return
	if globals.save_system.load_from_slot(slot):
		var members = globals.save_system.get_value("members")
		if members is Array:
			globals.party_manager.restore(members, {})
	get_tree().change_scene_to_file("res://scenes/world/loranai_city.tscn")

func _get_globals() -> Node:
	for child in get_tree().root.get_children():
		if child.name == "GameGlobals":
			return child
	return null