class_name AudioManager
extends Node

## 音频管理器
## BGM: 程序化生成（无需音频文件）
## SFX: 程序化生成（11 种）
## 自动从 settings.cfg 读取音量

const BGMGeneratorScript = preload("res://scripts/core/bgm_generator.gd")
const SfxGeneratorScript = preload("res://scripts/core/sfx_generator.gd")
const SETTINGS_PATH := "user://settings.cfg"

var music_player: AudioStreamPlayer = null
var sfx_players: Array[AudioStreamPlayer] = []
var music_bus: float = 0.7
var sfx_bus: float = 0.8
var current_music: String = ""
var _bgm_gen: RefCounted = null
var _sfx_gen: RefCounted = null

var _sfx_cache: Dictionary = {}  # sfx_id -> AudioStream

func _init() -> void:
	_bgm_gen = BGMGeneratorScript.new()
	_sfx_gen = SfxGeneratorScript.new()
	_load_volume_from_settings()
	# 创建 BGM player
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	music_player.volume_db = linear_to_db(music_bus)
	add_child(music_player)
	# 创建多个 SFX players（池）
	for i in 4:
		var s = AudioStreamPlayer.new()
		s.bus = "SFX"
		s.volume_db = linear_to_db(sfx_bus)
		sfx_players.append(s)
		add_child(s)

func _load_volume_from_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		music_bus = clamp(float(cfg.get_value("audio", "music_volume", 0.7)), 0.0, 1.0)
		sfx_bus = clamp(float(cfg.get_value("audio", "sfx_volume", 0.8)), 0.0, 1.0)

func play_music(track: String) -> void:
	if current_music == track:
		return
	if music_player.stream != null:
		music_player.stop()
	var stream: AudioStream = null
	match track:
		"town": stream = _bgm_gen.generate_town()
		"forest": stream = _bgm_gen.generate_forest()
		"cave": stream = _bgm_gen.generate_cave()
		"battle": stream = _bgm_gen.generate_battle()
		"boss": stream = _bgm_gen.generate_boss()
	if stream != null:
		music_player.stream = stream
		if music_player.is_inside_tree():
			music_player.play()
		current_music = track
		print("Music: playing %s" % track)

func stop_music() -> void:
	if music_player.is_inside_tree():
		music_player.stop()
	current_music = ""

func play_sfx(sfx_id: String) -> void:
	# 取一个空闲的 player
	for p in sfx_players:
		if not p.playing:
			var stream = _get_sfx_stream(sfx_id)
			if stream == null:
				return
			p.stream = stream
			if p.is_inside_tree():
				p.play()
			return

func _get_sfx_stream(sfx_id: String) -> AudioStream:
	if _sfx_cache.has(sfx_id):
		return _sfx_cache[sfx_id]
	var stream: AudioStream = null
	match sfx_id:
		"click": stream = _sfx_gen.generate_click()
		"hover": stream = _sfx_gen.generate_hover()
		"hit": stream = _sfx_gen.generate_hit()
		"crit": stream = _sfx_gen.generate_crit()
		"heal": stream = _sfx_gen.generate_heal()
		"buy": stream = _sfx_gen.generate_buy()
		"buy_fail": stream = _sfx_gen.generate_buy_fail()
		"victory": stream = _sfx_gen.generate_victory()
		"defeat": stream = _sfx_gen.generate_defeat()
		"levelup": stream = _sfx_gen.generate_levelup()
		"pickup": stream = _sfx_gen.generate_pickup()
		"menu_move": stream = _sfx_gen.generate_menu_move()
		"test": stream = _sfx_gen.generate_test()
	if stream != null:
		_sfx_cache[sfx_id] = stream
	return stream

func set_music_volume(volume: float) -> void:
	music_bus = clamp(volume, 0.0, 1.0)
	if music_player:
		music_player.volume_db = linear_to_db(max(music_bus, 0.001))

func set_sfx_volume(volume: float) -> void:
	sfx_bus = clamp(volume, 0.0, 1.0)
	for p in sfx_players:
		p.volume_db = linear_to_db(max(sfx_bus, 0.001))