class_name DialogueUI
extends Control

## 对话 UI：底层对话框 + 选项列表
## 程序化构建，监听 DialogueParser 状态

signal dialogue_finished
signal choice_made(choice_index: int)

var parser: DialogueParser = null
var current_node_id: String = ""

# UI 元素
var bg: ColorRect
var name_label: Label
var text_label: RichTextLabel
var choice_box: VBoxContainer
var continue_label: Label

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()

func _build_ui() -> void:
	# 底部对话框背景
	bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1, 0.9)
	bg.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bg.custom_minimum_size = Vector2(0, 200)
	add_child(bg)
	# 说话者名字
	name_label = Label.new()
	name_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	name_label.position = Vector2(30, 30)
	add_theme_font_size_override("font_size", 20)
	add_child(name_label)
	# 对话文本
	text_label = RichTextLabel.new()
	text_label.bbcode_enabled = true
	text_label.fit_content = true
	text_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	text_label.position = Vector2(30, 30)
	text_label.size = Vector2(900, 130)
	add_theme_font_size_override("normal_font_size", 18)
	add_child(text_label)
	# 选项列表
	choice_box = VBoxContainer.new()
	choice_box.set_anchors_preset(Control.PRESET_CENTER)
	choice_box.position = Vector2(400, 100)
	add_child(choice_box)
	# 继续提示
	continue_label = Label.new()
	continue_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	continue_label.position = Vector2(-100, -30)
	continue_label.text = "▶"
	continue_label.visible = false
	add_child(continue_label)

func start_dialogue(parser: DialogueParser) -> void:
	self.parser = parser
	_show_node("start")

func _show_node(node_id: String) -> void:
	if parser == null:
		return
	current_node_id = node_id
	var node = parser.get_node(node_id)
	if parser.is_end(node_id):
		_finish()
		return
	# 名字
	name_label.text = TranslationServer.translate(parser.speaker)
	# 文本
	var text := parser.get_text(node_id)
	text_label.clear()
	text_label.append_text(text)
	# 选项
	_clear_choices()
	if node.has("choices"):
		continue_label.visible = false
		var labels: Array[String] = parser.get_choice_labels(node_id)
		var targets: Array[String] = parser.get_choice_targets(node_id)
		for i in labels.size():
			var btn = Button.new()
			btn.text = "%d. %s" % [i + 1, labels[i]]
			var idx := i
			btn.pressed.connect(_on_choice_pressed.bind(idx, targets[i]))
			choice_box.add_child(btn)
	else:
		continue_label.visible = true

func _on_choice_pressed(idx: int, next_id: String) -> void:
	choice_made.emit(idx)
	_show_node(next_id)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if parser == null:
		return
	if not continue_label.visible:
		return
	# 按 Space/Enter/E 继续
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode in [KEY_SPACE, KEY_ENTER, KEY_E]):
		_show_node(parser.get_next_id(current_node_id))

func _finish() -> void:
	dialogue_finished.emit()
	queue_free()

func _clear_choices() -> void:
	for c in choice_box.get_children():
		c.queue_free()