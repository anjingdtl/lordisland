extends RefCounted

## 程序化 SFX 生成器
## 用 AudioStreamWAV 一次性生成 PCM 数据（headless 兼容）
## 11 种音效：UI 点击 / 命中 / 暴击 / 治疗 / 购买 / 胜利 / 升级 / 拾取 / 等

class_name SfxGenerator

const SAMPLE_RATE := 22050  # 头less 模式友好

func generate_click() -> AudioStream:
	# 短促高频 sine 点击
	return _generate_sine_burst(880.0, 0.05, 0.4)

func generate_hover() -> AudioStream:
	return _generate_sine_burst(660.0, 0.03, 0.2)

func generate_hit() -> AudioStream:
	return _generate_noise_burst(0.08, 0.6)

func generate_crit() -> AudioStream:
	# 双击 noise
	var duration := 0.18
	var samples := _alloc(duration)
	var total := int(duration * SAMPLE_RATE)
	for i in total:
		var t := float(i) / SAMPLE_RATE
		var sample: float = 0.0
		if t < 0.05:
			var env = 1.0 - (t / 0.05)
			sample = (_rand() * 2.0 - 1.0) * env * 0.7
		elif t >= 0.07 and t < 0.13:
			var t2 = t - 0.07
			var env = 1.0 - (t2 / 0.06)
			sample = (_rand() * 2.0 - 1.0) * env * 0.9
		samples[i * 2] = sample
		samples[i * 2 + 1] = sample
	return _build_stream(samples)

func generate_heal() -> AudioStream:
	# 上扬 sine
	return _generate_sweep(440.0, 880.0, 0.25, 0.4)

func generate_buy() -> AudioStream:
	# 金币音效：3 短击
	var duration := 0.3
	var samples := _alloc(duration)
	var total := int(duration * SAMPLE_RATE)
	for i in total:
		var t := float(i) / SAMPLE_RATE
		var sample: float = 0.0
		for beat in 3:
			var bt := t - beat * 0.08
			if bt >= 0.0 and bt < 0.05:
				var env = 1.0 - (bt / 0.05)
				var freq = 1200.0 + beat * 200.0
				sample += sin(bt * freq * TAU) * env * 0.5
		samples[i * 2] = sample
		samples[i * 2 + 1] = sample
	return _build_stream(samples)

func generate_buy_fail() -> AudioStream:
	# 失败：低沉两声
	var duration := 0.25
	var samples := _alloc(duration)
	var total := int(duration * SAMPLE_RATE)
	for i in total:
		var t := float(i) / SAMPLE_RATE
		var sample: float = 0.0
		var beat := t / 0.12
		var beat_idx := int(beat)
		var bt := beat - beat_idx
		if beat_idx < 2 and bt < 0.08:
			var env = 1.0 - (bt / 0.08)
			sample = sin(bt * 200.0 * TAU) * env * 0.4
		samples[i * 2] = sample
		samples[i * 2 + 1] = sample
	return _build_stream(samples)

func generate_victory() -> AudioStream:
	# 上行 C-E-G-C 大三和弦琶音
	var duration := 0.6
	var samples := _alloc(duration)
	var total := int(duration * SAMPLE_RATE)
	var notes = [261.63, 329.63, 392.00, 523.25]  # C4 E4 G4 C5
	for i in total:
		var t := float(i) / SAMPLE_RATE
		var sample: float = 0.0
		for n in notes.size():
			var nt := t - n * 0.12
			if nt >= 0.0 and nt < 0.3:
				var env = 1.0 - (nt / 0.3)
				sample += sin(nt * notes[n] * TAU) * env * 0.25
		samples[i * 2] = sample
		samples[i * 2 + 1] = sample
	return _build_stream(samples)

func generate_defeat() -> AudioStream:
	return _generate_sweep(440.0, 110.0, 0.5, 0.5)

func generate_levelup() -> AudioStream:
	var duration := 0.8
	var samples := _alloc(duration)
	var total := int(duration * SAMPLE_RATE)
	var notes = [392.00, 493.88, 587.33, 783.99]  # G4 B4 D5 G5
	for i in total:
		var t := float(i) / SAMPLE_RATE
		var sample: float = 0.0
		for n in notes.size():
			var nt := t - n * 0.1
			if nt >= 0.0 and nt < 0.4:
				var env = 1.0 - (nt / 0.4)
				sample += sin(nt * notes[n] * TAU) * env * 0.3
		samples[i * 2] = sample
		samples[i * 2 + 1] = sample
	return _build_stream(samples)

func generate_pickup() -> AudioStream:
	# 短促双音
	var duration := 0.15
	var samples := _alloc(duration)
	var total := int(duration * SAMPLE_RATE)
	for i in total:
		var t := float(i) / SAMPLE_RATE
		var sample: float = 0.0
		if t < 0.05:
			var env = 1.0 - (t / 0.05)
			sample = sin(t * 880.0 * TAU) * env * 0.4
		elif t >= 0.07 and t < 0.13:
			var t2 = t - 0.07
			var env = 1.0 - (t2 / 0.06)
			sample = sin(t2 * 1320.0 * TAU) * env * 0.4
		samples[i * 2] = sample
		samples[i * 2 + 1] = sample
	return _build_stream(samples)

func generate_menu_move() -> AudioStream:
	return _generate_sine_burst(440.0, 0.025, 0.15)

func generate_test() -> AudioStream:
	return _generate_sine_burst(880.0, 0.08, 0.4)

# ============== 内部 ==============

func _rand() -> float:
	return randf()

func _alloc(duration: float) -> PackedByteArray:
	var total_samples := int(duration * SAMPLE_RATE)
	var bytes := PackedByteArray()
	bytes.resize(total_samples * 2 * 2)  # stereo 16-bit
	return bytes

func _generate_sine_burst(freq: float, duration: float, volume: float) -> AudioStream:
	var samples := _alloc(duration)
	var total := int(duration * SAMPLE_RATE)
	for i in total:
		var t := float(i) / SAMPLE_RATE
		var envelope = 1.0 - (t / duration)
		var sample = sin(t * freq * TAU) * envelope * volume
		var v16 := int(sample * 32767.0)
		samples[i * 4] = v16 & 0xFF
		samples[i * 4 + 1] = (v16 >> 8) & 0xFF
		samples[i * 4 + 2] = v16 & 0xFF
		samples[i * 4 + 3] = (v16 >> 8) & 0xFF
	return _build_stream(samples)

func _generate_noise_burst(duration: float, volume: float) -> AudioStream:
	var samples := _alloc(duration)
	var total := int(duration * SAMPLE_RATE)
	for i in total:
		var t := float(i) / SAMPLE_RATE
		var envelope = 1.0 - (t / duration)
		var sample = (_rand() * 2.0 - 1.0) * envelope * volume
		var v16 := int(sample * 32767.0)
		samples[i * 4] = v16 & 0xFF
		samples[i * 4 + 1] = (v16 >> 8) & 0xFF
		samples[i * 4 + 2] = v16 & 0xFF
		samples[i * 4 + 3] = (v16 >> 8) & 0xFF
	return _build_stream(samples)

func _generate_sweep(start_freq: float, end_freq: float, duration: float, volume: float) -> AudioStream:
	var samples := _alloc(duration)
	var total := int(duration * SAMPLE_RATE)
	for i in total:
		var t := float(i) / SAMPLE_RATE
		var envelope = 1.0 - (t / duration)
		var phase = (start_freq + (end_freq - start_freq) * (t / duration)) * t
		var sample = sin(phase * TAU) * envelope * volume
		var v16 := int(sample * 32767.0)
		samples[i * 4] = v16 & 0xFF
		samples[i * 4 + 1] = (v16 >> 8) & 0xFF
		samples[i * 4 + 2] = v16 & 0xFF
		samples[i * 4 + 3] = (v16 >> 8) & 0xFF
	return _build_stream(samples)

func _build_stream(data: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = true
	stream.data = data
	return stream