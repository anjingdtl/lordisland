class_name TestPlayer
extends Node3D

## 2D 平面移动（xz），输入用方向键 / WASD
## 用在 HD-2D 场景中：角色在地面上、相机斜俯视

@export var speed: float = 4.0
@export var bounds_min: Vector2 = Vector2(-20, -20)
@export var bounds_max: Vector2 = Vector2( 20,  20)

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
	# xz 平面移动
	var dx := input.x * speed * delta
	var dz := input.y * speed * delta
	global_position.x = clamp(global_position.x + dx, bounds_min.x, bounds_max.x)
	global_position.z = clamp(global_position.z + dz, bounds_min.y, bounds_max.y)
