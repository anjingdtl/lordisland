class_name AssetLoader
extends RefCounted

## 资源加载器
## 优先从 res://assets/ 加载，失败 fallback 到程序化生成

static var _cache: Dictionary = {}

static func get_texture(asset_path: String) -> ImageTexture:
	if _cache.has(asset_path):
		return _cache[asset_path]
	if not FileAccess.file_exists(asset_path):
		_cache[asset_path] = _fallback_texture()
		return _cache[asset_path]
	var img = Image.new()
	var err = img.load(asset_path)
	if err != OK:
		_cache[asset_path] = _fallback_texture()
		return _cache[asset_path]
	var tex = ImageTexture.create_from_image(img)
	_cache[asset_path] = tex
	return tex

static func has_asset(asset_path: String) -> bool:
	return FileAccess.file_exists(asset_path)

static func sprite_data_to_path(actor_id: String) -> String:
	return "res://assets/sprites/" + actor_id + ".jpg"

static func clear_cache() -> void:
	_cache.clear()

static func _fallback_texture() -> ImageTexture:
	# 64x64 灰色 placeholder
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.5, 0.5, 0.5, 1.0))
	# 边框
	for i in 64:
		img.set_pixel(0, i, Color(0, 0, 0, 1))
		img.set_pixel(63, i, Color(0, 0, 0, 1))
		img.set_pixel(i, 0, Color(0, 0, 0, 1))
		img.set_pixel(i, 63, Color(0, 0, 0, 1))
	return ImageTexture.create_from_image(img)