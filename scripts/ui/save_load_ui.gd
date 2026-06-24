class_name SaveLoadUI
extends Control

## 存档/读档选择 UI：10 个槽位
## 程序化构建

signal slot_selected(slot: int)
signal cancelled

const SLOT_COUNT := 10

var mode: String = "load"  # "load" or "save"
var slot_buttons: Array[Button] = []

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_refresh_slots()

func _build_ui() -> void:
	# 半透明背景
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# 标题
	var title = Label.new()
	title.text = "读档" if mode == "load" else "存档"
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position.y = 30
	title.add_theme_font_size_override("font_size", 32)
	add_child(title)
	# 槽位列表（2 列 5 行）
	var grid = GridContainer.new()
	grid.columns = 2
	grid.set_anchors_preset(Control.PRESET_CENTER)
	grid.position = Vector2(-400, 0)
	grid.custom_minimum_size = Vector2(800, 500)
	add_child(grid)
	for i in SLOT_COUNT:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(380, 80)
		btn.text = "Slot %d: <empty>" % (i + 1)
		btn.pressed.connect(_on_slot_pressed.bind(i))
		grid.add_child(btn)
		slot_buttons.append(btn)
	# 取消按钮
	var cancel = Button.new()
	cancel.text = TranslationServer.translate("ui_quit")  # 复用退出翻译
	cancel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	cancel.position = Vector2(-150, -60)
	cancel.custom_minimum_size = Vector2(120, 40)
	cancel.pressed.connect(_on_cancel_pressed)
	add_child(cancel)

func _refresh_slots() -> void:
	for i in SLOT_COUNT:
		var path = "user://saves/save_%d.json" % i
		if FileAccess.file_exists(path):
			var f = FileAccess.open(path, FileAccess.READ)
			var data = JSON.parse_string(f.get_as_text())
			var chapter = data.get("chapter", "?")
			var timestamp = data.get("_timestamp", "?")
			slot_buttons[i].text = "[%d] %s - %s" % [i + 1, chapter, timestamp]
		else:
			slot_buttons[i].text = TranslationServer.translate("ui_empty_slot") % (i + 1)

func _on_slot_pressed(idx: int) -> void:
	slot_selected.emit(idx)
	queue_free()

func _on_cancel_pressed() -> void:
	cancelled.emit()
	queue_free()