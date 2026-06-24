class_name WorldEnvSetup
extends Node3D

## 自动配置 WorldEnvironment + 后处理管线
## Bloom + Vignette + Tone Mapping + SSAO + Fog

@export var scene_type: String = "town"  # town/forest/cave

var env: Environment
var world_env: WorldEnvironment
var sun: DirectionalLight3D

func _ready() -> void:
	_setup_environment()
	_setup_sun()
	_apply_scene_type()

func _setup_environment() -> void:
	env = Environment.new()
	# 背景
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.15, 0.2, 0.3, 1)
	# 环境光
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.4, 0.5, 0.7, 1)
	env.ambient_light_energy = 0.4
	# 色调映射
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.0
	env.tonemap_white = 6.0
	# Glow / Bloom
	env.glow_enabled = true
	env.glow_intensity = 0.4
	env.glow_strength = 0.8
	env.glow_bloom = 0.2
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	# SSAO
	env.ssao_enabled = true
	env.ssao_radius = 0.5
	env.ssao_intensity = 1.0
	env.ssao_power = 1.5
	env.ssao_detail = 0.5
	# Fog
	env.fog_enabled = true
	env.fog_light_color = Color(0.7, 0.8, 1.0, 1)
	env.fog_density = 0.008
	# WorldEnvironment
	world_env = WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

func _setup_sun() -> void:
	sun = DirectionalLight3D.new()
	sun.rotation = Vector3(-deg_to_rad(45), deg_to_rad(35), 0)
	sun.light_energy = 1.0
	sun.light_color = Color(1, 0.95, 0.9, 1)
	sun.shadow_enabled = true
	sun.shadow_bias = 0.05
	add_child(sun)

func _apply_scene_type() -> void:
	match scene_type:
		"town":
			env.ambient_light_color = Color(0.5, 0.45, 0.4, 1)
			env.ambient_light_energy = 0.6
			env.fog_density = 0.005
			env.glow_intensity = 0.5
			sun.light_color = Color(1, 0.92, 0.8, 1)
			sun.light_energy = 1.0
		"forest":
			env.ambient_light_color = Color(0.35, 0.5, 0.4, 1)
			env.ambient_light_energy = 0.45
			env.fog_color = Color(0.4, 0.5, 0.4, 1)
			env.fog_density = 0.012
			sun.light_color = Color(0.85, 0.95, 0.9, 1)
			sun.light_energy = 0.7
		"cave":
			env.ambient_light_color = Color(0.25, 0.3, 0.45, 1)
			env.ambient_light_energy = 0.3
			env.fog_color = Color(0.3, 0.35, 0.5, 1)
			env.fog_density = 0.025
			sun.light_color = Color(0.6, 0.7, 1.0, 1)
			sun.light_energy = 0.4