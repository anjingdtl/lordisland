class_name CameraShake
extends Node

## 相机震屏
## 用 trauma 0-1 模型

@export var max_offset: Vector3 = Vector3(0.4, 0.4, 0)
@export var max_rotation: float = 0.05
@export var decay: float = 1.5

var trauma: float = 0.0
var _original_position: Vector3 = Vector3.ZERO
var _original_rotation: Vector3 = Vector3.ZERO
var _target: Node3D = null

func _ready() -> void:
	_target = get_parent() as Node3D
	if _target:
		_original_position = _target.position
		_original_rotation = _target.rotation

func add_trauma(amount: float) -> void:
	trauma = clamp(trauma + amount, 0.0, 1.0)

func _process(delta: float) -> void:
	if trauma <= 0.0:
		return
	trauma = max(0.0, trauma - decay * delta)
	if _target == null:
		return
	var shake = trauma * trauma  # 平方曲线
	var offset = Vector3(
		randf_range(-max_offset.x, max_offset.x),
		randf_range(-max_offset.y, max_offset.y),
		0
	) * shake
	_target.position = _original_position + offset
	var rot = Vector3(
		randf_range(-max_rotation, max_rotation),
		randf_range(-max_rotation, max_rotation),
		0
	) * shake
	_target.rotation = _original_rotation + rot

func reset() -> void:
	trauma = 0.0
	if _target:
		_target.position = _original_position
		_target.rotation = _original_rotation