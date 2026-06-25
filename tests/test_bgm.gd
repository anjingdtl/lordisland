extends SceneTree

## BGM 系统测试

const AudioManager = preload("res://scripts/core/audio_manager.gd")
const BGMGenerator = preload("res://scripts/core/bgm_generator.gd")

var _passed: int = 0
var _failed: int = 0

func _init() -> void:
	test_bgm_generator_creates_streams()
	test_town_stream()
	test_forest_stream()
	test_cave_stream()
	test_battle_stream()
	test_boss_stream()
	test_audio_manager_creation()
	test_play_music_changes_track()
	print("\n=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		quit(1)
	else:
		quit(0)

func assert_eq(value, expected, msg: String) -> void:
	if value == expected:
		_passed += 1
		print("PASS: %s" % msg)
	else:
		_failed += 1
		print("FAIL: %s (got %s, expected %s)" % [msg, str(value), str(expected)])

func assert_true(value: bool, msg: String) -> void:
	assert_eq(value, true, msg)

func test_bgm_generator_creates_streams() -> void:
	var gen = BGMGenerator.new()
	assert_true(gen != null, "BGMGenerator instantiated")
	var stream = gen.generate_town()
	assert_true(stream != null, "town stream created")
	assert_true(stream is AudioStreamWAV, "stream is AudioStreamWAV")
	assert_eq(stream.mix_rate, 22050, "sample rate 22050")
	assert_eq(stream.format, 1, "16-bit format (1)")

func test_town_stream() -> void:
	var gen = BGMGenerator.new()
	var stream = gen.generate_town()
	assert_true(stream.data.size() > 0, "town has data")
	assert_eq(stream.loop_mode, 1, "town loops forward")

func test_forest_stream() -> void:
	var gen = BGMGenerator.new()
	var stream = gen.generate_forest()
	assert_true(stream.data.size() > 0, "forest has data")

func test_cave_stream() -> void:
	var gen = BGMGenerator.new()
	var stream = gen.generate_cave()
	assert_true(stream.data.size() > 0, "cave has data")

func test_battle_stream() -> void:
	var gen = BGMGenerator.new()
	var stream = gen.generate_battle()
	assert_true(stream.data.size() > 0, "battle has data")

func test_boss_stream() -> void:
	var gen = BGMGenerator.new()
	var stream = gen.generate_boss()
	assert_true(stream.data.size() > 0, "boss has data")

func test_audio_manager_creation() -> void:
	var am = AudioManager.new()
	assert_true(am != null, "AudioManager instantiated")
	assert_eq(am.current_music, "", "no music initially")
	assert_eq(am.sfx_players.size(), 4, "4 sfx players")

func test_play_music_changes_track() -> void:
	var am = AudioManager.new()
	am.play_music("town")
	assert_eq(am.current_music, "town", "current_music = town")
	am.play_music("forest")
	assert_eq(am.current_music, "forest", "current_music = forest")
	# 重复设置不重置
	am.play_music("forest")
	assert_eq(am.current_music, "forest", "duplicate no change")
