class_name SettingsUI
extends Control

## 设置面板（程序化构建）
## 包含：音乐音量 / SFX 音量 / 语言切换 / 全屏切换 / 返回
## 修改会持久化到 user://settings.cfg
## 通过 signals 与 main_menu 通信

signal closed

const SETTINGS_PATH := "user://settings.cfg"

var _music_slider: HSlider
var _sfx_slider: HSlider
var _language_option: OptionButton
var _fullscreen_check: CheckButton
var _resolution_option: OptionButton

const RESOLUTIONS := [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
]

var _current_resolution: Vector2i = Vector2i(1920, 1080)
var _is_fullscreen: bool = false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_load_settings()
	_build_ui()

func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		# 音量
		var mv = cfg.get_value("audio", "music_volume", 0.7)
		var sv = cfg.get_value("audio", "sfx_volume", 0.8)
		# 语言
		var lang = cfg.get_value("display", "language", "zh")
		# 分辨率
		var res_w = int(cfg.get_value("display", "resolution_width", 1920))
		var res_h = int(cfg.get_value("display", "resolution_height", 1080))
		_current_resolution = Vector2i(res_w, res_h)
		_is_fullscreen = bool(cfg.get_value("display", "fullscreen", false))
		# 应用到 audio manager
		var globals = _get_globals()
		if globals and globals.audio_manager:
			globals.audio_manager.set_music_volume(mv)
			globals.audio_manager.set_sfx_volume(sv)
		# 应用语言
		TranslationServer.set_locale(lang)

func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music_volume", _music_slider.value if _music_slider else 0.7)
	cfg.set_value("audio", "sfx_volume", _sfx_slider.value if _sfx_slider else 0.8)
	cfg.set_value("display", "language", _language_option.get_item_metadata(_language_option.get_selected()) if _language_option else "zh")
	cfg.set_value("display", "resolution_width", _current_resolution.x)
	cfg.set_value("display", "resolution_height", _current_resolution.y)
	cfg.set_value("display", "fullscreen", _is_fullscreen_check())
	cfg.save(SETTINGS_PATH)

func _build_ui() -> void:
	# 半透明背景
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.75)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# 标题
	var title = Label.new()
	title.text = TranslationServer.translate("ui_settings")
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position.y = 30
	title.add_theme_font_size_override("font_size", 36)
	add_child(title)
	# 设置项 VBox
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.position = Vector2(-300, -120)
	vbox.custom_minimum_size = Vector2(600, 0)
	vbox.add_theme_constant_override("separation", 18)
	add_child(vbox)
	# 音乐音量
	_music_slider = _make_slider_row(vbox, "setting_music_volume", 0.0, 1.0, 0.01)
	_music_slider.value_changed.connect(_on_music_changed)
	# SFX 音量
	_sfx_slider = _make_slider_row(vbox, "setting_sfx_volume", 0.0, 1.0, 0.01)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	# 语言
	_language_option = OptionButton.new()
	_language_option.add_item("中文", 0)
	_language_option.set_item_metadata(0, "zh")
	_language_option.add_item("English", 1)
	_language_option.set_item_metadata(1, "en")
	_language_option.add_item("日本語", 2)
	_language_option.set_item_metadata(2, "ja")
	var lang_label = Label.new()
	lang_label.text = TranslationServer.translate("setting_language")
	lang_label.add_theme_font_size_override("font_size", 20)
	var lang_hbox = HBoxContainer.new()
	lang_hbox.add_child(lang_label)
	lang_hbox.add_child(_language_option)
	vbox.add_child(lang_hbox)
	_language_option.item_selected.connect(_on_language_changed)
	# 分辨率
	_resolution_option = OptionButton.new()
	for i in RESOLUTIONS.size():
		var r = RESOLUTIONS[i]
		_resolution_option.add_item("%d × %d" % [r.x, r.y], i)
		_resolution_option.set_item_metadata(i, r)
	var res_label = Label.new()
	res_label.text = TranslationServer.translate("setting_resolution")
	res_label.add_theme_font_size_override("font_size", 20)
	var res_hbox = HBoxContainer.new()
	res_hbox.add_child(res_label)
	res_hbox.add_child(_resolution_option)
	vbox.add_child(res_hbox)
	_resolution_option.item_selected.connect(_on_resolution_changed)
	# 全屏
	_fullscreen_check = CheckButton.new()
	_fullscreen_check.text = TranslationServer.translate("setting_fullscreen")
	_fullscreen_check.add_theme_font_size_override("font_size", 20)
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	vbox.add_child(_fullscreen_check)
	# 初始化当前值
	var globals = _get_globals()
	if globals and globals.audio_manager:
		_music_slider.value = globals.audio_manager.music_bus
		_sfx_slider.value = globals.audio_manager.sfx_bus
	else:
		_music_slider.value = 0.7
		_sfx_slider.value = 0.8
	var cur_lang = TranslationServer.get_locale()
	for i in _language_option.get_item_count():
		if _language_option.get_item_metadata(i) == cur_lang:
			_language_option.selected = i
			break
	for i in RESOLUTIONS.size():
		if RESOLUTIONS[i] == _current_resolution:
			_resolution_option.selected = i
			break
	_fullscreen_check.button_pressed = _is_fullscreen
	# 按钮组
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_hbox)
	var apply = Button.new()
	apply.text = TranslationServer.translate("setting_apply")
	apply.custom_minimum_size = Vector2(160, 44)
	apply.pressed.connect(_on_apply)
	btn_hbox.add_child(apply)
	var close = Button.new()
	close.text = TranslationServer.translate("setting_close")
	close.custom_minimum_size = Vector2(160, 44)
	close.pressed.connect(_on_close_pressed)
	btn_hbox.add_child(close)

func _make_slider_row(parent: Container, label_key: String, min_v: float, max_v: float, step: float) -> HSlider:
	var label = Label.new()
	label.text = TranslationServer.translate(label_key)
	label.add_theme_font_size_override("font_size", 20)
	var slider = HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = step
	slider.custom_minimum_size = Vector2(300, 24)
	var hbox = HBoxContainer.new()
	hbox.add_child(label)
	hbox.add_child(slider)
	parent.add_child(hbox)
	return slider

func _on_music_changed(value: float) -> void:
	var globals = _get_globals()
	if globals and globals.audio_manager:
		globals.audio_manager.set_music_volume(value)

func _on_sfx_changed(value: float) -> void:
	var globals = _get_globals()
	if globals and globals.audio_manager:
		globals.audio_manager.set_sfx_volume(value)
		# 播放测试音效
		globals.audio_manager.play_sfx("test")

func _on_language_changed(idx: int) -> void:
	var lang = _language_option.get_item_metadata(idx)
	TranslationServer.set_locale(lang)

func _on_resolution_changed(idx: int) -> void:
	_current_resolution = RESOLUTIONS[idx]
	_apply_resolution()

func _on_fullscreen_toggled(pressed: bool) -> void:
	_is_fullscreen = pressed
	_apply_resolution()

func _apply_resolution() -> void:
	var win := get_window()
	if win:
		if _is_fullscreen:
			win.mode = Window.MODE_FULLSCREEN
		else:
			win.mode = Window.MODE_WINDOWED
			win.size = _current_resolution

func _is_fullscreen_check() -> bool:
	return _fullscreen_check != null and _fullscreen_check.button_pressed

func _on_apply() -> void:
	_save_settings()

func _on_close_pressed() -> void:
	_save_settings()
	closed.emit()
	queue_free()

func _get_globals() -> Node:
	for child in get_tree().root.get_children():
		if child.name == "GameGlobals":
			return child
	return null