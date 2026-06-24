class_name WorldPlayer
extends Node3D

## 地图玩家（与 test_player 类似但带交互检测）
## 走格子式移动：方向键 / WASD

@export var speed: float = 4.0
@export var bounds_min: Vector2 = Vector2(-20, -20)
@export var bounds_max: Vector2 = Vector2( 20,  20)

var npc_in_range: Node3D = null
var exit_in_range: Node3D = null

func _process(delta: float) -> void:
	var input := Vector2.ZERO
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input.x += 1.0
	if Input.is_action_pressed("ui_left")  or Input.is_key_pressed(KEY_A):
		input.x -= 1.0
	if Input.is_action_pressed("ui_down")  or Input.is_key_pressed(KEY_S):
		input.y += 1.0
	if Input.is_action_pressed("ui_up")    or Input.is_key_pressed(KEY_W):
		input.y -= 1.0
	if input == Vector2.ZERO:
		return
	input = input.normalized()
	var dx := input.x * speed * delta
	var dz := input.y * speed * delta
	global_position.x = clamp(global_position.x + dx, bounds_min.x, bounds_max.x)
	global_position.z = clamp(global_position.z + dz, bounds_min.y, bounds_max.y)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if npc_in_range and npc_in_range.has_method("on_interact"):
			npc_in_range.on_interact()
		elif exit_in_range and exit_in_range.has_method("on_interact"):
			exit_in_range.on_interact()

func _on_npc_entered(body: Node3D) -> void:
	if body.is_in_group("npc"):
		npc_in_range = body
func _on_npc_exited(body: Node3D) -> void:
	if body == npc_in_range:
		npc_in_range = null
func _on_exit_entered(body: Node3D) -> void:
	if body.is_in_group("exit"):
		exit_in_range = body
func _on_exit_exited(body: Node3D) -> void:
	if body == exit_in_range:
		exit_in_range = null