class_name AIImageGenerator
extends RefCounted

## AI 生图系统
## 调用 trae-api-cn.mchost.guru API 生成 sprite 资产
## 同步 HTTP 请求（依赖 Godot 4.3 HTTPRequest）

const API_BASE := "https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image"
const SAVE_DIR := "res://assets/sprites/"
const TIMEOUT := 30.0

## 生成并保存（同步）
## Returns res:// path 或 ""
func generate_and_save(prompt: String, save_name: String, size: String = "square_hd") -> String:
	var url = API_BASE + "?prompt=" + _url_encode(prompt) + "&image_size=" + size
	var save_path = SAVE_DIR + save_name + ".png"
	# 跳过已存在
	if FileAccess.file_exists(save_path):
		return save_path
	# 同步 HTTP
	var http = HTTPRequest.new()
	var err = http.request(url)
	if err != OK:
		return ""
	# 等待完成
	var elapsed = 0.0
	var dt = 0.1
	while http.get_http_client_status() == HTTPClient.STATUS_REQUESTING and elapsed < TIMEOUT:
		OS.delay_msec(int(dt * 1000))
		elapsed += dt
	if elapsed >= TIMEOUT:
		return ""
	if http.get_response_code() != 200:
		return ""
	var data = http.get_data()
	if data.size() < 1024:
		return ""
	# 保存
	var dir_path = SAVE_DIR.replace("res://", "")
	DirAccess.make_dir_recursive_absolute("res://" + dir_path)
	var f = FileAccess.open(save_path, FileAccess.WRITE)
	if f == null:
		return ""
	f.store_buffer(data)
	f.close()
	return save_path

## URL 编码
func _url_encode(s: String) -> String:
	return s.uri_encode()

## 批量生成
func generate_batch(specs: Array) -> Array[String]:
	var results: Array[String] = []
	for spec in specs:
		var path = generate_and_save(
			spec.get("prompt", ""),
			spec.get("name", ""),
			spec.get("size", "square_hd")
		)
		results.append(path)
	return results

## 主角 prompt 模板
static func character_prompt(name: String, desc: String) -> String:
	return "pixel art, 16-bit JRPG, anime style, full body character, " + desc + ", standing, transparent background, sprite sheet 4 frames, 96x96 each frame, high quality"

## 敌人 prompt 模板
static func enemy_prompt(name: String, desc: String) -> String:
	return "pixel art, 16-bit JRPG, fantasy monster, " + desc + ", full body, transparent background, 96x96, single pose, high quality"

## Tile prompt
static func tile_prompt(tile_type: String) -> String:
	return "pixel art, top-down RPG tile, 64x64, " + tile_type + ", seamless, RPG Maker style, top-down view"

## UI prompt
static func ui_prompt(ui_type: String) -> String:
	return "pixel art, UI element, " + ui_type + ", transparent background, 256x256, high quality, clean lines"