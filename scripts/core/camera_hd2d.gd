class_name HD2DCamera
extends Camera3D

## HD-2D 透视相机：
## 固定斜角俯视（约 45°），跟随 target Node3D 移动
## 适合 Octopath Traveler / Triangle Strategy 风格的 2.5D RPG

@export var target: Node3D
@export var height: float = 12.0
@export var distance: float = 16.0
@export var angle_deg: float = 50.0  # 与水平面夹角
@export var follow_speed: float = 8.0
@export var offset: Vector3 = Vector3.ZERO

var _target_pos: Vector3

func _ready() -> void:
	# 启动时定位到 target
	if target:
		_target_pos = target.global_position + offset
	_update_camera_immediate()

func _process(delta: float) -> void:
	if not target:
		return
	# 平滑跟随
	_target_pos = target.global_position + offset
	global_position = global_position.lerp(_target_pos, follow_speed * delta)
	# 固定朝向（斜俯视）
	rotation_degrees = Vector3(-angle_deg, 0, 0)

func _update_camera_immediate() -> void:
	if not target:
		return
	global_position = target.global_position + offset
	rotation_degrees = Vector3(-angle_deg, 0, 0)
