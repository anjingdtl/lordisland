class_name AudioManager
extends RefCounted

## 音频管理器 stub
## 等 P2 内容后接入真实音频资源
## 设计文档 §6：背景音乐 + 战斗音效 + 移动音效

var music_player: AudioStreamPlayer = null
var sfx_players: Array[AudioStreamPlayer] = []
var music_bus: float = 0.7
var sfx_bus: float = 0.8
var current_music: String = ""

func _init() -> void:
	# 创建 BGM player
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	music_player.volume_db = linear_to_db(music_bus)
	# 创建多个 SFX players（池）
	for i in 4:
		var s = AudioStreamPlayer.new()
		s.bus = "SFX"
		s.volume_db = linear_to_db(sfx_bus)
		sfx_players.append(s)

func play_music(path: String) -> void:
	if current_music == path:
		return
	if music_player.stream != null:
		music_player.stop()
	# 真实场景下加载 AudioStream
	if FileAccess.file_exists(path):
		# TODO: ResourceLoader.load(path)
		print("Music: would play %s" % path)
	current_music = path

func stop_music() -> void:
	music_player.stop()
	current_music = ""

func play_sfx(path: String) -> void:
	for p in sfx_players:
		if not p.playing:
			# TODO: ResourceLoader.load(path)
			print("SFX: would play %s" % path)
			return

func set_music_volume(volume: float) -> void:
	music_bus = clamp(volume, 0.0, 1.0)
	music_player.volume_db = linear_to_db(music_bus)

func set_sfx_volume(volume: float) -> void:
	sfx_bus = clamp(volume, 0.0, 1.0)
	for p in sfx_players:
		p.volume_db = linear_to_db(sfx_bus)