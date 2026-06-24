class_name SpriteGenerator
extends RefCounted

## 程序化生成像素 sprite
## 输出: ImageTexture (32x48 默认，walk strip 128x48 = 4 帧)

const FRAME_W := 32
const FRAME_H := 48
const WALK_FRAMES := 4

var _cache: Dictionary = {}

## 单帧 sprite
func generate_static(sprite_data: Dictionary) -> ImageTexture:
	return ImageTexture.create_from_image(_build_sprite(sprite_data, 0))

## 4 帧 walk 横向 strip
func generate_walk_strip(sprite_data: Dictionary) -> ImageTexture:
	var strip = Image.create(FRAME_W * WALK_FRAMES, FRAME_H, false, Image.FORMAT_RGBA8)
	strip.fill(Color(0, 0, 0, 0))
	for i in WALK_FRAMES:
		var frame = _build_sprite(sprite_data, i)
		strip.blit_rect(frame, Rect2i(0, 0, FRAME_W, FRAME_H), Vector2i(i * FRAME_W, 0))
	return ImageTexture.create_from_image(strip)

func clear_cache() -> void:
	_cache.clear()

func _build_sprite(data: Dictionary, frame: int) -> Image:
	var img = Image.create(FRAME_W, FRAME_H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var p = _build_palette(data)
	_draw_head(img, p, frame)
	_draw_body(img, p, frame)
	_draw_legs(img, p, frame)
	_draw_weapon(img, p, data.get("weapon", "none"), frame)
	return img

func _build_palette(data: Dictionary) -> Dictionary:
	return {
		"hair": _parse_color(data.get("hair_color", "#f0c419")),
		"skin": _parse_color(data.get("skin_color", "#fbcb8a")),
		"body": _parse_color(data.get("body_color", "#2a4d8f")),
		"armor": _parse_color(data.get("armor_color", "#cccccc")),
		"outline": _parse_color(data.get("outline_color", "#1a1a1a"))
	}

func _parse_color(s) -> Color:
	if s is Color:
		return s
	if s is String and s.begins_with("#"):
		return Color(s)
	return Color("#888888")

func _draw_head(img: Image, p: Dictionary, frame: int) -> void:
	# 头发 (y 0-10, x 8-24)
	for y in range(0, 10):
		for x in range(8, 24):
			img.set_pixel(x, y, p.hair)
	# 脸 (y 10-18, x 10-22)
	for y in range(10, 18):
		for x in range(10, 22):
			img.set_pixel(x, y, p.skin)
	# 眼睛
	img.set_pixel(13, 13, p.outline)
	img.set_pixel(19, 13, p.outline)
	# 头轮廓
	for x in range(8, 24):
		img.set_pixel(x, 0, p.outline)
	for y in range(0, 18):
		img.set_pixel(8, y, p.outline)
		img.set_pixel(23, y, p.outline)
	img.set_pixel(8, 17, p.outline)
	img.set_pixel(23, 17, p.outline)

func _draw_body(img: Image, p: Dictionary, frame: int) -> void:
	# 胸部 (y 18-30, x 10-22)
	for y in range(18, 30):
		for x in range(10, 22):
			img.set_pixel(x, y, p.body)
	# 阴影（底部 1 行）
	for x in range(10, 22):
		img.set_pixel(x, 29, p.body.darkened(0.2))
	# 胸甲中线（x=15, 16 是中央）
	for y in range(20, 28):
		img.set_pixel(15, y, p.armor)
		img.set_pixel(16, y, p.armor)
	# 身体轮廓
	for x in range(10, 22):
		img.set_pixel(x, 18, p.outline)
	for y in range(18, 30):
		img.set_pixel(9, y, p.outline)
		img.set_pixel(22, y, p.outline)

func _draw_legs(img: Image, p: Dictionary, frame: int) -> void:
	# 4 帧走路动画: 腿偏移
	var leg_offsets: Array = [
		[0, 0],    # 帧 0 站立
		[-1, 1],   # 帧 1 左脚前
		[0, 0],    # 帧 2 站立
		[1, -1]    # 帧 3 右脚前
	]
	var left = leg_offsets[frame][0]
	var right = leg_offsets[frame][1]
	# 左腿 (y 30-48, x 12+offset)
	for y in range(30, 48):
		img.set_pixel(11 + left, y, p.body)
		img.set_pixel(12 + left, y, p.body)
	# 右腿
	for y in range(30, 48):
		img.set_pixel(19 + right, y, p.body)
		img.set_pixel(20 + right, y, p.body)
	# 鞋
	for x in range(10, 14):
		img.set_pixel(x + left, 47, p.outline)
	for x in range(18, 22):
		img.set_pixel(x + right, 47, p.outline)

func _draw_weapon(img: Image, p: Dictionary, weapon: String, frame: int) -> void:
	match weapon:
		"sword":
			# 剑柄
			for y in range(26, 30):
				img.set_pixel(24, y, p.armor)
			# 剑刃
			for y in range(16, 26):
				img.set_pixel(24, y, Color("#cccccc"))
				img.set_pixel(25, y, Color("#ffffff"))
				img.set_pixel(24, y - 1 if y > 16 else y, p.outline)
		"staff":
			for y in range(10, 30):
				img.set_pixel(24, y, p.body.darkened(0.3))
			# 顶球
			img.set_pixel(24, 9, Color("#aaccff"))
			img.set_pixel(23, 10, Color("#aaccff"))
			img.set_pixel(25, 10, Color("#aaccff"))
		"dagger":
			for y in range(20, 28):
				img.set_pixel(24, y, Color("#cccccc"))
			img.set_pixel(24, 19, p.outline)
		"bow":
			# 弓
			for y in range(14, 30):
				img.set_pixel(24, y, p.body)
			img.set_pixel(24, 14, p.outline)
			img.set_pixel(25, 14, p.outline)
		"axe":
			# 斧柄
			for y in range(20, 30):
				img.set_pixel(24, y, p.body)
			# 斧头
			img.set_pixel(25, 22, p.armor)
			img.set_pixel(26, 22, p.armor)
			img.set_pixel(27, 22, p.outline)
			img.set_pixel(25, 23, p.armor)
			img.set_pixel(26, 23, p.outline)
			img.set_pixel(27, 23, p.outline)
		"spear":
			for y in range(8, 30):
				img.set_pixel(24, y, p.body)
			# 矛头
			img.set_pixel(24, 7, Color("#aaaaaa"))
			img.set_pixel(23, 8, Color("#cccccc"))
			img.set_pixel(25, 8, Color("#cccccc"))
		"club":
			img.set_pixel(23, 26, p.outline)
			img.set_pixel(24, 26, p.outline)
			img.set_pixel(25, 26, p.outline)
			img.set_pixel(23, 27, p.body.darkened(0.4))
			img.set_pixel(24, 27, p.body.darkened(0.4))
			img.set_pixel(25, 27, p.body.darkened(0.4))
		_:
			pass