class_name BattleUI
extends Control

## 战斗 UI 控件（程序化构建，无 .tscn 资源）
## 监听 BattleController 信号更新显示

var controller: BattleController
var root: Node

# UI 元素
var action_menu: VBoxContainer
var target_menu: VBoxContainer
var info_label: Label
var status_panel: VBoxContainer

# 当前选中的 skill_id / target
var _pending_skill: String = ""
var _pending_target_idx: int = -1

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()

func bind(controller: BattleController) -> void:
	self.controller = controller
	controller.turn_started.connect(_on_turn_started)
	controller.ui_state_changed.connect(_on_state_changed)
	controller.actor_acted.connect(_on_actor_acted)
	controller.actor_damaged.connect(_on_actor_damaged)
	controller.actor_healed.connect(_on_actor_healed)
	controller.battle_ended.connect(_on_battle_ended)

func _build_ui() -> void:
	# 顶部信息条
	info_label = Label.new()
	info_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	info_label.position.y = 10
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(info_label)
	# 右侧命令菜单
	action_menu = VBoxContainer.new()
	action_menu.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	action_menu.position = Vector2(-220, 100)
	action_menu.custom_minimum_size = Vector2(200, 300)
	add_child(action_menu)
	# 中央目标菜单（弹出式）
	target_menu = VBoxContainer.new()
	target_menu.set_anchors_preset(Control.PRESET_CENTER)
	target_menu.position = Vector2(100, 100)
	target_menu.visible = false
	add_child(target_menu)
	# 左侧状态面板（玩家队伍 HP/MP）
	status_panel = VBoxContainer.new()
	status_panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	status_panel.position = Vector2(20, 80)
	add_child(status_panel)

func _on_state_changed(state: int) -> void:
	if state == BattleController.State.PLAYER_TURN:
		_show_action_menu()
	elif state == BattleController.State.ANIMATING:
		action_menu.visible = false
		target_menu.visible = false
	elif state == BattleController.State.ENDED:
		action_menu.visible = false
		target_menu.visible = false

func _on_turn_started(actor: Actor) -> void:
	info_label.text = "%s 的回合" % actor.display_name()
	_refresh_status_panel()

func _on_actor_acted(_actor: Actor, _action: String, _targets: Array, _results: Array) -> void:
	_refresh_status_panel()

func _on_actor_damaged(target: Actor, amount: int, _is_crit: bool) -> void:
	info_label.text += "  -%d HP" % amount
	_refresh_status_panel()

func _on_actor_healed(target: Actor, amount: int) -> void:
	info_label.text += "  +%d HP" % amount
	_refresh_status_panel()

func _on_battle_ended(victory: bool, exp: int) -> void:
	if victory:
		info_label.text = "胜利！获得 %d 经验" % exp
	else:
		info_label.text = "失败..."

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
	if status_panel == null or controller == null:
		return
	_clear_children(status_panel)
	for a in controller.party:
		var row = Label.new()
		row.text = "%s  HP:%d/%d MP:%d/%d" % [a.display_name(), a.hp, a.max_hp, a.mp, a.max_mp]
		status_panel.add_child(row)

func _clear_children(node: Node) -> void:
	for c in node.get_children():
		c.queue_free()