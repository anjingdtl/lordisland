class_name ForestDecorator
extends Node3D

## 程序化生成森林装饰（树、石头、灌木）

@export var seed_value: int = 42
@export var tree_count: int = 10
@export var rock_count: int = 5
@export var bush_count: int = 6
@export var bounds_min: Vector2 = Vector2(-20, -20)
@export var bounds_max: Vector2 = Vector2(20, 20)

func _ready() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	_generate_trees(rng)
	_generate_rocks(rng)
	_generate_bushes(rng)

func _generate_trees(rng: RandomNumberGenerator) -> void:
	for i in tree_count:
		var t = MeshInstance3D.new()
		var trunk = CylinderMesh.new()
		trunk.top_radius = 0.2
		trunk.bottom_radius = 0.25
		trunk.height = 1.2
		t.mesh = trunk
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.4, 0.25, 0.15, 1)
		mat.roughness = 0.95
		t.material_override = mat
		var top = MeshInstance3D.new()
		var crown = SphereMesh.new()
		crown.radius = 0.6
		crown.height = 1.2
		top.mesh = crown
		top.position.y = 1.2
		var mat2 = StandardMaterial3D.new()
		mat2.albedo_color = Color(0.2, 0.45, 0.2, 1)
		mat2.roughness = 0.85
		top.material_override = mat2
		var pos = _random_pos(rng)
		t.position = Vector3(pos.x, 0.6, pos.y)
		top.position = Vector3(pos.x, 1.2, pos.y)
		t.add_child(top)
		add_child(t)

func _generate_rocks(rng: RandomNumberGenerator) -> void:
	for i in rock_count:
		var r = MeshInstance3D.new()
		var box = BoxMesh.new()
		var s = rng.randf_range(0.4, 0.8)
		box.size = Vector3(s, s * 0.6, s)
		r.mesh = box
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.5, 0.5, 0.5, 1)
		mat.roughness = 0.95
		r.material_override = mat
		r.rotation.y = rng.randf_range(0, PI)
		var pos = _random_pos(rng)
		r.position = Vector3(pos.x, s * 0.3, pos.y)
		add_child(r)

func _generate_bushes(rng: RandomNumberGenerator) -> void:
	for i in bush_count:
		var b = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.3
		sphere.height = 0.4
		b.mesh = sphere
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 0.5, 0.25, 1)
		mat.roughness = 0.9
		b.material_override = mat
		var pos = _random_pos(rng)
		b.position = Vector3(pos.x, 0.2, pos.y)
		add_child(b)

func _random_pos(rng: RandomNumberGenerator) -> Vector2:
	return Vector2(
		rng.randf_range(bounds_min.x, bounds_max.x),
		rng.randf_range(bounds_min.y, bounds_max.y)
	)