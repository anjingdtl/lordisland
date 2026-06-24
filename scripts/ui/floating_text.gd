class_name FloatingText
extends Label

## 飘字：战斗伤害/治疗数字

var lifetime: float = 1.5
var float_speed: float = 60.0
var fade_start: float = 0.7
var _elapsed: float = 0.0
var _direction: Vector2 = Vector2(0, -1)

func setup(text: String, color: Color, is_crit: bool = false) -> void:
	self.text = text
	modulate = color
	if is_crit:
		add_theme_font_size_override("font_size", 48)
		# 飘字更远
		float_speed = 100.0
		_direction = Vector2(randf_range(-0.4, 0.4), -1).normalized()
	else:
		add_theme_font_size_override("font_size", 28)
		_direction = Vector2(randf_range(-0.2, 0.2), -1).normalized()

func _process(delta: float) -> void:
	_elapsed += delta
	position += _direction * float_speed * delta
	if _elapsed > fade_start:
		var fade = 1.0 - (_elapsed - fade_start) / (lifetime - fade_start)
		modulate.a = clamp(fade, 0.0, 1.0)
	if _elapsed >= lifetime:
		queue_free()

func show_at(parent: Node, pos: Vector2) -> void:
	parent.add_child(self)
	position = pos
	_elapsed = 0.0