class_name MainMenu
extends Control

## 主菜单：新游戏 / 继续 / 读档 / 设置 / 退出
## 程序化构建 UI

signal new_game_pressed
signal continue_pressed
signal load_pressed
signal settings_pressed
signal quit_pressed

var _has_save: bool = false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_check_save()

func _build_ui() -> void:
	# 背景渐变
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# 标题
	var title = Label.new()
	title.text = "Lordisland"
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position.y = 100
	title.add_theme_font_size_override("font_size", 64)
	add_child(title)
	var subtitle = Label.new()
	subtitle.text = "Record of Lodoss War 2D RPG"
	subtitle.set_anchors_preset(Control.PRESET_TOP_WIDE)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.position.y = 180
	subtitle.add_theme_font_size_override("font_size", 20)
	add_child(subtitle)
	# 按钮容器
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.position = Vector2(-150, 50)
	vbox.custom_minimum_size = Vector2(300, 0)
	add_child(vbox)
	# 按钮
	for label in ["ui_new_game", "ui_continue", "ui_load", "ui_settings", "ui_quit"]:
		var btn = Button.new()
		btn.text = TranslationServer.translate(label)
		btn.custom_minimum_size = Vector2(280, 50)
		btn.add_theme_font_size_override("font_size", 20)
		match label:
			"ui_new_game": btn.pressed.connect(_on_new_game)
			"ui_continue": btn.pressed.connect(_on_continue); btn.name = "BtnContinue"
			"ui_load": btn.pressed.connect(_on_load)
			"ui_settings": btn.pressed.connect(_on_settings)
			"ui_quit": btn.pressed.connect(_on_quit)
		vbox.add_child(btn)

func _check_save() -> void:
	# 检查任意槽位是否有存档
	for i in 10:
		if FileAccess.file_exists("user://saves/save_%d.json" % i):
			_has_save = true
			return
	# 没存档则禁用 Continue 按钮
	var btn = get_node_or_null("BtnContinue")
	if btn:
		btn.disabled = true
		btn.text = TranslationServer.translate("ui_continue") + " (*)"

func _on_new_game() -> void:
	new_game_pressed.emit()
	_start_new_game()

func _on_continue() -> void:
	continue_pressed.emit()
	# 加载最新存档
	for i in range(9, -1, -1):
		if FileAccess.file_exists("user://saves/save_%d.json" % i):
			_load_slot(i)
			return

func _on_load() -> void:
	load_pressed.emit()
	# 弹出存档选择 UI
	var selector_script = load("res://scripts/ui/save_load_ui.gd")
	var selector = selector_script.new()
	add_child(selector)
	selector.slot_selected.connect(_load_slot)
	selector.cancelled.connect(func(): selector.queue_free())

func _on_settings() -> void:
	settings_pressed.emit()
	# TODO: 弹设置

func _on_quit() -> void:
	quit_pressed.emit()
	get_tree().quit()

func _start_new_game() -> void:
	# 重置 GameGlobals
	var globals = _get_globals()
	if globals:
		globals.event_system.reset()
		globals.party_manager.reset() if globals.party_manager.has_method("reset") else null
		# 帕恩初始入队
		globals.party_manager.add_member("parn")
	get_tree().change_scene_to_file("res://scenes/world/loranai_city.tscn")

func _load_slot(slot: int) -> void:
	var globals = _get_globals()
	if not globals:
		return
	if globals.save_system.load_from_slot(slot):
		# 恢复 party
		var members = globals.save_system.get_value("members")
		if members is Array:
			globals.party_manager.restore(members, {})
	get_tree().change_scene_to_file("res://scenes/world/loranai_city.tscn")

func _get_globals() -> Node:
	for child in get_tree().root.get_children():
		if child.name == "GameGlobals":
			return child
	return null