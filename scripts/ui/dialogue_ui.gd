class_name DialogueUI
extends Control

## 对话 UI：立绘 + 底部对话框 + 打字机 + 选项列表
## 程序化构建，监听 DialogueParser 状态

signal dialogue_finished
signal choice_made(choice_index: int)

const AssetLoader = preload("res://scripts/core/asset_loader.gd")

var parser: RefCounted = null
var current_node_id: String = ""
var typewriter_speed: float = 38.0
var _typewriter_accum: float = 0.0
var _is_typing: bool = false
var _pending_choice_labels: Array[String] = []
var _pending_choice_targets: Array[String] = []

# UI 元素
var bg: ColorRect
var panel: PanelContainer
var content_row: HBoxContainer
var portrait: TextureRect
var name_label: Label
var text_label: RichTextLabel
var choice_box: VBoxContainer
var continue_label: Label

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()

func _process(delta: float) -> void:
	if not _is_typing or text_label == null:
		return
	_typewriter_accum += delta * typewriter_speed
	text_label.visible_characters = min(text_label.get_total_character_count(), int(_typewriter_accum))
	if text_label.visible_characters >= text_label.get_total_character_count():
		_finish_typewriter()

func _build_ui() -> void:
	bg = ColorRect.new()
	bg.name = "DialogueShade"
	bg.color = Color(0.0, 0.0, 0.0, 0.22)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	panel = PanelContainer.new()
	panel.name = "DialoguePanel"
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 96
	panel.offset_right = -96
	panel.offset_top = -310
	panel.offset_bottom = -48
	add_child(panel)

	content_row = HBoxContainer.new()
	content_row.name = "DialogueContent"
	content_row.add_theme_constant_override("separation", 24)
	panel.add_child(content_row)

	portrait = TextureRect.new()
	portrait.name = "Portrait"
	portrait.custom_minimum_size = Vector2(180, 240)
	portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	content_row.add_child(portrait)

	var text_column = VBoxContainer.new()
	text_column.name = "TextColumn"
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.add_theme_constant_override("separation", 10)
	content_row.add_child(text_column)

	name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.add_theme_font_size_override("font_size", 24)
	text_column.add_child(name_label)

	text_label = RichTextLabel.new()
	text_label.name = "BodyText"
	text_label.bbcode_enabled = true
	text_label.fit_content = true
	text_label.custom_minimum_size = Vector2(860, 120)
	text_label.add_theme_font_size_override("normal_font_size", 22)
	text_column.add_child(text_label)

	choice_box = VBoxContainer.new()
	choice_box.name = "Choices"
	choice_box.add_theme_constant_override("separation", 8)
	text_column.add_child(choice_box)

	continue_label = Label.new()
	continue_label.name = "Continue"
	continue_label.text = "▶"
	continue_label.visible = false
	text_column.add_child(continue_label)

func start_dialogue(dialogue_parser: RefCounted) -> void:
	parser = dialogue_parser
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
	_update_portrait()
	# 文本
	var text: String = parser.get_text(node_id)
	text_label.clear()
	text_label.append_text(text)
	text_label.visible_characters = 0
	_typewriter_accum = 0.0
	_is_typing = true
	# 选项
	_clear_choices()
	_pending_choice_labels.clear()
	_pending_choice_targets.clear()
	if node.has("choices"):
		continue_label.visible = false
		_pending_choice_labels = parser.get_choice_labels(node_id)
		_pending_choice_targets = parser.get_choice_targets(node_id)
	else:
		continue_label.visible = false

func _on_choice_pressed(idx: int, next_id: String) -> void:
	choice_made.emit(idx)
	_show_node(next_id)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if parser == null:
		return
	if _is_typing:
		text_label.visible_characters = text_label.get_total_character_count()
		_finish_typewriter()
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

func _finish_typewriter() -> void:
	_is_typing = false
	text_label.visible_characters = text_label.get_total_character_count()
	if not _pending_choice_labels.is_empty():
		for i in _pending_choice_labels.size():
			var btn = Button.new()
			btn.text = "%d. %s" % [i + 1, _pending_choice_labels[i]]
			var idx := i
			btn.pressed.connect(_on_choice_pressed.bind(idx, _pending_choice_targets[i]))
			choice_box.add_child(btn)
	else:
		continue_label.visible = true

func _update_portrait() -> void:
	if portrait == null or parser == null:
		return
	var actor_id := _portrait_to_actor_id(parser.portrait, parser.speaker)
	var portrait_path := _portrait_to_texture_path(actor_id)
	portrait.texture = AssetLoader.get_texture(portrait_path)

func _portrait_to_actor_id(portrait_id: String, speaker_id: String) -> String:
	var raw := portrait_id
	if raw == "":
		raw = speaker_id
	raw = raw.replace("char_", "").replace("npc_", "")
	raw = raw.replace("_name", "").replace("_neutral", "")
	if raw == "town_chief":
		return "parn"
	return raw

func _portrait_to_texture_path(actor_id: String) -> String:
	var illustration_paths := {
		"parn": "res://illustration/parn.png",
		"ehto": "res://illustration/Etoh.png",
		"slayn": "res://illustration/Slayn.png",
		"ghim": "res://illustration/Ghim.png",
		"tike": "res://illustration/deeplit.png",
		"woodchuck": "res://illustration/Woodchuck.png"
	}
	var path: String = illustration_paths.get(actor_id, "")
	if path != "" and AssetLoader.has_asset(path):
		return path
	return AssetLoader.sprite_data_to_path(actor_id)
