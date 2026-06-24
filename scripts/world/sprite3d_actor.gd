class_name Sprite3DActor
extends Node3D

## 3D 场景中的 sprite 节点
## 程序化生成 sprite, billboard 朝向相机, 走路动画

@export var sprite_data: Dictionary = {}
@export var actor_id: String = ""
@export var use_walk_animation: bool = true
@export var pixel_size: float = 0.05  # 32px sprite 渲染为 1.6 单位

var sprite: Sprite3D = null
var anim: AnimationPlayer = null
var facing_right: bool = true
var is_walking: bool = false

func _ready() -> void:
	_build_visual()

func set_sprite_data(data: Dictionary) -> void:
	sprite_data = data
	if is_inside_tree() and sprite:
		_build_visual()

func _build_visual() -> void:
	# 清理旧的
	for child in get_children():
		child.queue_free()
	sprite = null
	anim = null
	# 默认数据
	var data = sprite_data
	if data.is_empty():
		data = {"body_color": "#888888", "hair_color": "#444444", "skin_color": "#cccccc", "armor_color": "#888888", "weapon": "none"}
	# 生成 sprite
	var gen = SpriteGenerator.new()
	var tex = gen.generate_walk_strip(data)
	# 创建 Sprite3D
	sprite = Sprite3D.new()
	sprite.texture = tex
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.pixel_size = pixel_size
	sprite.position.y = 0.7  # 中心点抬到地面以上
	sprite.centered = true
	sprite.hframes = 4  # 4 帧
	add_child(sprite)
	# 动画
	if use_walk_animation:
		_setup_animation()
	# 阴影
	_add_shadow()

func _setup_animation() -> void:
	anim = AnimationPlayer.new()
	add_child(anim)
	var anim_res = Animation.new()
	anim_res.length = 0.4
	anim_res.loop_mode = Animation.LOOP_LINEAR
	var track_idx = anim_res.add_track(Animation.TYPE_VALUE)
	anim_res.track_set_path(track_idx, "Sprite3D:frame")
	anim_res.track_insert_key(track_idx, 0.0, 0)
	anim_res.track_insert_key(track_idx, 0.1, 1)
	anim_res.track_insert_key(track_idx, 0.2, 2)
	anim_res.track_insert_key(track_idx, 0.3, 3)
	anim_res.track_insert_key(track_idx, 0.4, 0)
	var lib = AnimationLibrary.new()
	lib.add_animation("walk", anim_res)
	anim.add_animation_library("", lib)
	anim.play("walk")

func _add_shadow() -> void:
	# 简单圆形阴影
	var shadow_mesh = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(0.6, 0.6)
	shadow_mesh.mesh = plane
	shadow_mesh.rotation.x = -PI / 2
	shadow_mesh.position.y = 0.01
	var shadow_mat = StandardMaterial3D.new()
	shadow_mat.albedo_color = Color(0, 0, 0, 0.4)
	shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow_mesh.material_override = shadow_mat
	add_child(shadow_mesh)

func play_walk() -> void:
	is_walking = true
	if anim and anim.has_animation("walk"):
		anim.play("walk")

func play_idle() -> void:
	is_walking = false
	if anim:
		anim.stop()
	if sprite:
		sprite.frame = 0

func flip_horizontal(flip: bool) -> void:
	facing_right = not flip
	if sprite:
		sprite.flip_h = flip

func _process(_delta: float) -> void:
	# 根据相机方向自动 flip
	if sprite and is_instance_valid(sprite):
		var vp = get_viewport()
		if vp == null:
			return
		var camera = vp.get_camera_3d()
		if camera == null:
			return
		var to_cam = camera.global_position - global_position
		var flip = to_cam.x < 0
		if facing_right != (not flip):
			facing_right = not flip
			sprite.flip_h = flip