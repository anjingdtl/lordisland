class_name BGMGenerator
extends RefCounted

## 程序化生成 BGM（不用外部音频文件）
## 简单 4-8 音节循环，16-bit PCM
## 不同场景不同风格：
##   town: 大调，舒缓
##   forest: 5 度下行，神秘
##   cave: 小调，紧张
##   battle: 快节奏 4/4
##   boss: 低音 + 鼓点

const SAMPLE_RATE := 22050

## 生成 town 风格 BGM
func generate_town() -> AudioStreamWAV:
	return _generate_loop([
		[262, 1.0],  # C4
		[330, 1.0],  # E4
		[392, 1.0],  # G4
		[523, 1.5],  # C5
		[392, 0.5],  # G4
		[330, 1.0],  # E4
	], 2.0, "sine", 0.15)

## 生成 forest 风格
func generate_forest() -> AudioStreamWAV:
	return _generate_loop([
		[330, 1.5],  # E4
		[294, 0.5],  # D4
		[262, 1.0],  # C4
		[247, 1.0],  # B3
		[220, 1.5],  # A3
		[196, 0.5],  # G3
	], 1.5, "triangle", 0.12)

## 生成 cave 风格（小调）
func generate_cave() -> AudioStreamWAV:
	return _generate_loop([
		[220, 0.8],  # A3
		[247, 0.4],  # B3
		[262, 0.8],  # C4
		[220, 0.6],  # A3
		[196, 0.6],  # G3
		[165, 0.8],  # E3
	], 1.2, "square", 0.10)

## 生成 battle 风格
func generate_battle() -> AudioStreamWAV:
	return _generate_loop([
		[196, 0.25],  # G3
		[262, 0.25],  # C4
		[330, 0.25],  # E4
		[262, 0.25],  # C4
		[196, 0.25],
		[262, 0.25],
		[330, 0.25],
		[392, 0.25],  # G4
	], 0.5, "sawtooth", 0.18)

## 生成 boss 风格
func generate_boss() -> AudioStreamWAV:
	return _generate_loop([
		[98, 1.0],   # G2
		[110, 0.5],  # A2
		[123, 0.5],  # B2
		[98, 1.0],
		[82, 1.0],   # E2
		[73, 0.5],   # D2
		[65, 0.5],   # C2
		[82, 1.0],
	], 1.5, "square", 0.20)

## 通用循环生成器
func _generate_loop(notes: Array, beat_duration: float, wave_type: String, volume: float) -> AudioStreamWAV:
	var total_samples := int(notes.size() * beat_duration * SAMPLE_RATE)
	var data := PackedByteArray()
	data.resize(total_samples * 2)  # 16-bit mono
	for i in total_samples:
		# 当前是哪个音符
		var note_idx := int(float(i) / (beat_duration * SAMPLE_RATE))
		note_idx = clamp(note_idx, 0, notes.size() - 1)
		var freq = notes[note_idx][0]
		var t = float(i) / SAMPLE_RATE
		# 局部时间（在当前音符内）
		var local_t = fmod(t, beat_duration)
		var attack = 0.05
		var release = beat_duration * 0.3
		var env = 1.0
		if local_t < attack:
			env = local_t / attack
		elif local_t > beat_duration - release:
			env = max(0.0, (beat_duration - local_t) / release)
		# 波形
		var phase = t * freq
		var sample = 0.0
		match wave_type:
			"sine":
				sample = sin(phase * TAU)
			"triangle":
				var p = fmod(phase, 1.0)
				sample = 4.0 * abs(p - 0.5) - 1.0
			"square":
				var p = fmod(phase, 1.0)
				sample = 1.0 if p < 0.5 else -1.0
			"sawtooth":
				var p = fmod(phase, 1.0)
				sample = 2.0 * p - 1.0
		sample *= volume * env
		# 16-bit PCM
		var pcm = int(clamp(sample, -1.0, 1.0) * 32767)
		# 小端序
		var lo = pcm & 0xff
		var hi = (pcm >> 8) & 0xff
		data[i * 2] = lo
		data[i * 2 + 1] = hi
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = total_samples
	stream.data = data
	return stream