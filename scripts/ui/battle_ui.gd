class_name BattleUI
extends Control

## 战斗 UI 控件（程序化构建，无 .tscn 资源）
## 监听 BattleController 信号更新显示

const FloatingTextScript = preload("res://scripts/ui/floating_text.gd")
const STATE_PLAYER_TURN := 1
const STATE_ANIMATING := 3
const STATE_ENDED := 4

var controller: Object
var root: Node

# UI 元素
var action_menu: VBoxContainer
var target_menu: VBoxContainer
var info_label: Label
var party_panel: HBoxContainer
var enemy_panel: HBoxContainer
var log_panel: VBoxContainer

# 当前选中的 skill_id / target
var _pending_skill: String = ""
var _pending_target_idx: int = -1

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()

func bind(battle_controller: Object) -> void:
	controller = battle_controller
	controller.turn_started.connect(_on_turn_started)
	controller.ui_state_changed.connect(_on_state_changed)
	controller.actor_acted.connect(_on_actor_acted)
	controller.actor_damaged.connect(_on_actor_damaged)
	controller.actor_healed.connect(_on_actor_healed)
	controller.battle_ended.connect(_on_battle_ended)

func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.name = "BattleOverlay"
	bg.color = Color(0.02, 0.03, 0.05, 0.45)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	info_label = Label.new()
	info_label.name = "TurnInfo"
	info_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	info_label.offset_top = 12
	info_label.offset_bottom = 52
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 24)
	add_child(info_label)

	party_panel = HBoxContainer.new()
	party_panel.name = "PartyStatus"
	party_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	party_panel.offset_left = 32
	party_panel.offset_right = -32
	party_panel.offset_top = 64
	party_panel.offset_bottom = 146
	party_panel.add_theme_constant_override("separation", 12)
	add_child(party_panel)

	enemy_panel = HBoxContainer.new()
	enemy_panel.name = "EnemyStatus"
	enemy_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	enemy_panel.offset_left = 32
	enemy_panel.offset_right = -360
	enemy_panel.offset_top = -132
	enemy_panel.offset_bottom = -40
	enemy_panel.add_theme_constant_override("separation", 12)
	add_child(enemy_panel)

	action_menu = VBoxContainer.new()
	action_menu.name = "ActionMenu"
	action_menu.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	action_menu.offset_left = -280
	action_menu.offset_right = -32
	action_menu.offset_top = 180
	action_menu.offset_bottom = 520
	action_menu.add_theme_constant_override("separation", 10)
	add_child(action_menu)

	target_menu = VBoxContainer.new()
	target_menu.name = "TargetMenu"
	target_menu.set_anchors_preset(Control.PRESET_CENTER)
	target_menu.custom_minimum_size = Vector2(260, 220)
	target_menu.visible = false
	add_child(target_menu)

	log_panel = VBoxContainer.new()
	log_panel.name = "LogPanel"
	log_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	log_panel.offset_left = 32
	log_panel.offset_right = 500
	log_panel.offset_top = -280
	log_panel.offset_bottom = -150
	add_child(log_panel)

func _on_state_changed(state: int) -> void:
	if state == STATE_PLAYER_TURN:
		_show_action_menu()
	elif state == STATE_ANIMATING:
		action_menu.visible = false
		target_menu.visible = false
	elif state == STATE_ENDED:
		action_menu.visible = false
		target_menu.visible = false

func _on_turn_started(actor: Object) -> void:
	info_label.text = "%s 的回合" % actor.display_name()
	_refresh_status_panel()

func _on_actor_acted(_actor: Object, _action: String, _targets: Array, _results: Array) -> void:
	_refresh_status_panel()

func _on_actor_damaged(target: Object, amount: int, _is_crit: bool) -> void:
	info_label.text += "  -%d HP" % amount
	show_damage(Vector2(960, 420), amount, _is_crit)
	_refresh_status_panel()

func _on_actor_healed(target: Object, amount: int) -> void:
	info_label.text += "  +%d HP" % amount
	_refresh_status_panel()

func _on_battle_ended(victory: bool, exp: int) -> void:
	if victory:
		info_label.text = "胜利！获得 %d 经验" % exp
	else:
		info_label.text = "失败..."

func set_party(actors: Array) -> void:
	_build_actor_slots(party_panel, actors, true)

func set_enemies(actors: Array) -> void:
	_build_actor_slots(enemy_panel, actors, false)

func update_hp(actor_idx: int, hp: int, max_hp: int) -> void:
	var slots = party_panel.get_children()
	if actor_idx < 0 or actor_idx >= slots.size():
		return
	var hp_bar = slots[actor_idx].find_child("HPBar", true, false)
	if hp_bar is ProgressBar:
		hp_bar.max_value = max_hp
		hp_bar.value = hp

func show_damage(pos: Vector2, amount: int, is_crit: bool = false) -> void:
	var ft = FloatingTextScript.new()
	var label = "CRIT! -%d" % amount if is_crit else "-%d" % amount
	ft.setup(label, Color(1.0, 0.25, 0.18, 1.0), is_crit)
	ft.show_at(self, pos)

func show_message(text: String) -> void:
	if log_panel == null:
		return
	var row = Label.new()
	row.text = text
	log_panel.add_child(row)
	if log_panel.get_child_count() > 5:
		log_panel.get_child(0).queue_free()

func show_menu(menu_type: String) -> void:
	action_menu.visible = menu_type == "action"
	target_menu.visible = menu_type == "target"

func _show_action_menu() -> void:
	action_menu.visible = true
	_clear_children(action_menu)
	if controller.current_actor == null:
		return
	var cmds: Array = controller.get_player_command()
	if cmds.is_empty():
		# 没 MP 了，加防御按钮
		var defend_btn = Button.new()
		defend_btn.text = "防御"
		defend_btn.pressed.connect(_on_defend_pressed)
		action_menu.add_child(defend_btn)
		return
	for cmd in cmds:
		var skill = controller._skills_cache.get(cmd, {})
		var btn = Button.new()
		btn.text = TranslationServer.translate(skill.get("name_key", cmd))
		btn.pressed.connect(_on_skill_selected.bind(cmd))
		action_menu.add_child(btn)
	# 加防御和逃跑
	var defend_btn = Button.new()
	defend_btn.text = "防御"
	defend_btn.pressed.connect(_on_defend_pressed)
	action_menu.add_child(defend_btn)
	var run_btn = Button.new()
	run_btn.text = "逃跑"
	run_btn.pressed.connect(_on_run_pressed)
	action_menu.add_child(run_btn)

func _on_skill_selected(skill_id: String) -> void:
	_pending_skill = skill_id
	var skill = controller._skills_cache.get(skill_id, {})
	match skill.get("target", ""):
		"single_enemy":
			_show_target_menu("enemies")
		"single_ally":
			_show_target_menu("party")
		"self":
			controller.player_action(skill_id, controller.party.find(controller.current_actor))
		"all_enemies", "all_allies":
			controller.player_action(skill_id, 0)
		_:
			controller.player_action(skill_id, 0)

func _show_target_menu(group: String) -> void:
	target_menu.visible = true
	_clear_children(target_menu)
	var list: Array = controller.enemies if group == "enemies" else controller.party
	for i in list.size():
		var a = list[i]
		if not a.is_alive:
			continue
		var btn = Button.new()
		btn.text = "%s (HP %d/%d)" % [a.display_name(), a.hp, a.max_hp]
		btn.pressed.connect(_on_target_selected.bind(i))
		target_menu.add_child(btn)

func _on_target_selected(idx: int) -> void:
	controller.player_action(_pending_skill, idx)
	_pending_skill = ""
	_pending_target_idx = -1
	target_menu.visible = false

func _on_defend_pressed() -> void:
	controller.player_defend()

func _on_run_pressed() -> void:
	controller.player_run_away()

func _refresh_status_panel() -> void:
	if party_panel == null or controller == null:
		return
	set_party(_actors_to_rows(controller.party))
	set_enemies(_actors_to_rows(controller.enemies))

func _clear_children(node: Node) -> void:
	for c in node.get_children():
		c.queue_free()

func _actors_to_rows(actors: Array) -> Array:
	var rows: Array = []
	for a in actors:
		rows.append({
			"name": a.display_name(),
			"hp": a.hp,
			"max_hp": a.max_hp,
			"mp": a.mp,
			"max_mp": a.max_mp
		})
	return rows

func _build_actor_slots(container: Container, actors: Array, include_mp: bool) -> void:
	if container == null:
		return
	_clear_children(container)
	for data in actors:
		var slot = VBoxContainer.new()
		slot.name = "ActorSlot"
		slot.custom_minimum_size = Vector2(210, 72)
		var name = Label.new()
		name.name = "Name"
		name.text = _actor_value(data, "name", "???")
		slot.add_child(name)
		var hp = _make_bar("HPBar", int(_actor_value(data, "hp", 1)), int(_actor_value(data, "max_hp", 1)), Color(0.85, 0.12, 0.12, 1))
		slot.add_child(hp)
		if include_mp:
			var mp = _make_bar("MPBar", int(_actor_value(data, "mp", 0)), int(_actor_value(data, "max_mp", 1)), Color(0.15, 0.35, 0.9, 1))
			slot.add_child(mp)
		container.add_child(slot)

func _make_bar(node_name: String, value: int, max_value: int, fill_color: Color) -> ProgressBar:
	var bar = ProgressBar.new()
	bar.name = node_name
	bar.max_value = max(1, max_value)
	bar.value = clamp(value, 0, max_value)
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(190, 14)
	var fill = StyleBoxFlat.new()
	fill.bg_color = fill_color
	bar.add_theme_stylebox_override("fill", fill)
	return bar

func _actor_value(actor, key: String, fallback):
	if actor is Dictionary:
		return actor.get(key, fallback)
	if actor == null:
		return fallback
	return actor.get(key) if actor.get(key) != null else fallback
