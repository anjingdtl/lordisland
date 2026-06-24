class_name AudioManager
extends RefCounted

## 音频管理器
## BGM: 程序化生成（无需音频文件）
## SFX: 桩（无文件）

var music_player: AudioStreamPlayer = null
var sfx_players: Array[AudioStreamPlayer] = []
var music_bus: float = 0.7
var sfx_bus: float = 0.8
var current_music: String = ""
var _bgm_gen: BGMGenerator = null

func _init() -> void:
	_bgm_gen = BGMGenerator.new()
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

func play_music(track: String) -> void:
	# track 是 BGM 风格名：town, forest, cave, battle, boss
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
		music_player.play()
		current_music = track
		print("Music: playing %s" % track)

func stop_music() -> void:
	music_player.stop()
	current_music = ""

func play_sfx(sfx_id: String) -> void:
	for p in sfx_players:
		if not p.playing:
			print("SFX: %s" % sfx_id)
			return

func set_music_volume(volume: float) -> void:
	music_bus = clamp(volume, 0.0, 1.0)
	music_player.volume_db = linear_to_db(music_bus)

func set_sfx_volume(volume: float) -> void:
	sfx_bus = clamp(volume, 0.0, 1.0)
	for p in sfx_players:
		p.volume_db = linear_to_db(sfx_bus)