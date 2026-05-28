extends Node

# -----------------------------------------------
# SOUND MANAGER
# This plays all the sounds in the game!
# It uses Godot's AudioStreamGenerator to make
# sounds from scratch — no audio files needed!
#
# To play a sound anywhere in the game, just write:
#   SoundManager.play("shoot_pistol")
#   SoundManager.play("hit")
#   SoundManager.play("victory")
# -----------------------------------------------

# Master volume (0.0 = silent, 1.0 = full)
var master_volume: float = 0.8
var sfx_on: bool = true
var music_on: bool = true

# We keep a pool of AudioStreamPlayer nodes for sound effects
# so multiple sounds can play at the same time
const POOL_SIZE = 8
var _sfx_pool: Array = []
var _pool_index: int = 0

# Separate player for background music (loops)
var _music_player: AudioStreamPlayer = null
var _current_music: String = ""

# -----------------------------------------------
# SET UP
# -----------------------------------------------
func _ready():
	# Create the pool of sound players
	for i in range(POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_sfx_pool.append(player)

	# Create the music player
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	add_child(_music_player)

	print("SoundManager ready! 🔊")

# -----------------------------------------------
# PLAY A SOUND EFFECT
# Call this from anywhere: SoundManager.play("hit")
# -----------------------------------------------
func play(sound_name: String, volume_db: float = 0.0):
	if not sfx_on:
		return

	# Grab the next player from the pool
	var player = _sfx_pool[_pool_index]
	_pool_index = (_pool_index + 1) % POOL_SIZE

	# Stop whatever it was doing and play the new sound
	player.stop()
	player.volume_db = volume_db + linear_to_db(master_volume)

	var stream = _make_sound(sound_name)
	if stream:
		player.stream = stream
		player.play()

# -----------------------------------------------
# PLAY BACKGROUND MUSIC (loops until stopped)
# -----------------------------------------------
func play_music(music_name: String):
	if not music_on:
		return
	if _current_music == music_name:
		return  # Already playing this one!

	_current_music = music_name
	var stream = _make_music(music_name)
	if stream:
		_music_player.stop()
		_music_player.stream = stream
		_music_player.volume_db = linear_to_db(master_volume * 0.4)
		_music_player.play()

func stop_music():
	_current_music = ""
	_music_player.stop()

# -----------------------------------------------
# SET VOLUME  (0.0 to 1.0)
# -----------------------------------------------
func set_volume(vol: float):
	master_volume = clamp(vol, 0.0, 1.0)

# -----------------------------------------------
# BUILD SOUNDS USING AUDIOSTREAMGENERATOR
# Each sound is made by filling an audio buffer
# with carefully chosen wave shapes.
# -----------------------------------------------
func _make_sound(name: String) -> AudioStream:
	match name:
		"shoot_pistol":
			return _gen_shoot(0.12, 800.0, 200.0, 0.85)
		"shoot_revolver":
			return _gen_shoot(0.16, 600.0, 150.0, 0.95)
		"shoot_shotgun":
			return _gen_shotgun()
		"shoot_assault_rifle":
			return _gen_shoot(0.08, 900.0, 300.0, 0.75)
		"shoot_machine_gun":
			return _gen_shoot(0.06, 1000.0, 350.0, 0.70)
		"shoot_sniper":
			return _gen_shoot(0.25, 400.0, 80.0, 1.0)
		"hit":
			return _gen_hit()
		"death":
			return _gen_death()
		"click":
			return _gen_click()
		"victory_sting":
			return _gen_victory_sting()
		"defeat_sting":
			return _gen_defeat_sting()
		"last_stand":
			return _gen_last_stand()
		"place_clone":
			return _gen_place_clone()
	return null

func _make_music(name: String) -> AudioStream:
	match name:
		"battle":
			return _gen_battle_music()
		"menu":
			return _gen_menu_music()
	return null

# -----------------------------------------------
# SOUND GENERATORS
# These fill an audio buffer with wave data.
# Think of it like drawing a squiggly line that
# becomes sound when played really fast!
# -----------------------------------------------

# Generic gunshot: sharp crack with frequency sweep
func _gen_shoot(duration: float, freq_start: float, freq_end: float, amp: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t = float(i) / sample_rate
		var progress = float(i) / samples
		# Frequency sweeps down (crack → rumble)
		var freq = lerp(freq_start, freq_end, progress)
		# Volume fades out
		var envelope = amp * pow(1.0 - progress, 1.5)
		# Mix a sine wave with noise for that "gun crack" texture
		var sine = sin(2.0 * PI * freq * t)
		var noise = randf_range(-1.0, 1.0)
		var sample = clamp((sine * 0.6 + noise * 0.4) * envelope, -1.0, 1.0)
		var pcm = int(sample * 32767)
		data[i * 2]     = pcm & 0xFF
		data[i * 2 + 1] = (pcm >> 8) & 0xFF

	return _bytes_to_wav(data, sample_rate)

# Shotgun: several overlapping "shots" all at once
func _gen_shotgun() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.28
	var samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t = float(i) / sample_rate
		var progress = float(i) / samples
		var envelope = pow(1.0 - progress, 1.2)
		# Lots of noise = that wide boom
		var noise = randf_range(-1.0, 1.0)
		var low = sin(2.0 * PI * 120.0 * t)
		var sample = clamp((noise * 0.7 + low * 0.3) * envelope, -1.0, 1.0)
		var pcm = int(sample * 32767)
		data[i * 2]     = pcm & 0xFF
		data[i * 2 + 1] = (pcm >> 8) & 0xFF

	return _bytes_to_wav(data, sample_rate)

# Hit sound: a short dull thud
func _gen_hit() -> AudioStreamWAV:
	var sample_rate = 22050
	var samples = int(sample_rate * 0.08)
	var data = PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var progress = float(i) / samples
		var envelope = pow(1.0 - progress, 2.0) * 0.7
		var thud = sin(2.0 * PI * 180.0 * float(i) / sample_rate)
		var noise = randf_range(-1.0, 1.0) * 0.3
		var sample = clamp((thud + noise) * envelope, -1.0, 1.0)
		var pcm = int(sample * 32767)
		data[i * 2]     = pcm & 0xFF
		data[i * 2 + 1] = (pcm >> 8) & 0xFF

	return _bytes_to_wav(data, sample_rate)

# Death sound: low boom + descending tone
func _gen_death() -> AudioStreamWAV:
	var sample_rate = 22050
	var samples = int(sample_rate * 0.4)
	var data = PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t = float(i) / sample_rate
		var progress = float(i) / samples
		var envelope = pow(1.0 - progress, 0.8) * 0.9
		var freq = lerp(300.0, 60.0, progress)
		var tone = sin(2.0 * PI * freq * t)
		var noise = randf_range(-1.0, 1.0) * 0.25
		var sample = clamp((tone * 0.75 + noise) * envelope, -1.0, 1.0)
		var pcm = int(sample * 32767)
		data[i * 2]     = pcm & 0xFF
		data[i * 2 + 1] = (pcm >> 8) & 0xFF

	return _bytes_to_wav(data, sample_rate)

# UI click: a short crisp tick
func _gen_click() -> AudioStreamWAV:
	var sample_rate = 22050
	var samples = int(sample_rate * 0.04)
	var data = PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var progress = float(i) / samples
		var envelope = pow(1.0 - progress, 3.0)
		var tone = sin(2.0 * PI * 1200.0 * float(i) / sample_rate)
		var sample = clamp(tone * envelope * 0.6, -1.0, 1.0)
		var pcm = int(sample * 32767)
		data[i * 2]     = pcm & 0xFF
		data[i * 2 + 1] = (pcm >> 8) & 0xFF

	return _bytes_to_wav(data, sample_rate)

# Victory sting: three rising happy notes
func _gen_victory_sting() -> AudioStreamWAV:
	var sample_rate = 22050
	var note_dur = 0.18
	var notes = [523.25, 659.25, 783.99, 1046.50]  # C5 E5 G5 C6
	var total = int(sample_rate * note_dur * notes.size())
	var data = PackedByteArray()
	data.resize(total * 2)

	for n in range(notes.size()):
		var freq = notes[n]
		var start = int(n * sample_rate * note_dur)
		for i in range(int(sample_rate * note_dur)):
			var progress = float(i) / (sample_rate * note_dur)
			var envelope = sin(PI * progress)  # smooth bell shape
			var t = float(i) / sample_rate
			var tone = sin(2.0 * PI * freq * t) + sin(2.0 * PI * freq * 2.0 * t) * 0.3
			var sample = clamp(tone * envelope * 0.6, -1.0, 1.0)
			var pcm = int(sample * 32767)
			var idx = (start + i) * 2
			if idx + 1 < data.size():
				data[idx]     = pcm & 0xFF
				data[idx + 1] = (pcm >> 8) & 0xFF

	return _bytes_to_wav(data, sample_rate)

# Defeat sting: three falling sad notes
func _gen_defeat_sting() -> AudioStreamWAV:
	var sample_rate = 22050
	var note_dur = 0.22
	var notes = [392.00, 311.13, 261.63]  # G4 Eb4 C4 — sad minor drop
	var total = int(sample_rate * note_dur * notes.size())
	var data = PackedByteArray()
	data.resize(total * 2)

	for n in range(notes.size()):
		var freq = notes[n]
		var start = int(n * sample_rate * note_dur)
		for i in range(int(sample_rate * note_dur)):
			var progress = float(i) / (sample_rate * note_dur)
			var envelope = sin(PI * progress) * 0.5
			var t = float(i) / sample_rate
			var tone = sin(2.0 * PI * freq * t)
			var sample = clamp(tone * envelope, -1.0, 1.0)
			var pcm = int(sample * 32767)
			var idx = (start + i) * 2
			if idx + 1 < data.size():
				data[idx]     = pcm & 0xFF
				data[idx + 1] = (pcm >> 8) & 0xFF

	return _bytes_to_wav(data, sample_rate)

# Last Stand: dramatic low rising tone
func _gen_last_stand() -> AudioStreamWAV:
	var sample_rate = 22050
	var samples = int(sample_rate * 0.6)
	var data = PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t = float(i) / sample_rate
		var progress = float(i) / samples
		var freq = lerp(80.0, 220.0, progress)
		var envelope = progress * (1.0 - progress * 0.3)
		var tone = sin(2.0 * PI * freq * t) + sin(2.0 * PI * freq * 1.5 * t) * 0.4
		var noise = randf_range(-1.0, 1.0) * 0.1
		var sample = clamp((tone + noise) * envelope * 0.7, -1.0, 1.0)
		var pcm = int(sample * 32767)
		data[i * 2]     = pcm & 0xFF
		data[i * 2 + 1] = (pcm >> 8) & 0xFF

	return _bytes_to_wav(data, sample_rate)

# Clone placement sound: a soft satisfying "plop"
func _gen_place_clone() -> AudioStreamWAV:
	var sample_rate = 22050
	var samples = int(sample_rate * 0.1)
	var data = PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t = float(i) / sample_rate
		var progress = float(i) / samples
		var envelope = pow(1.0 - progress, 2.5) * 0.65
		var freq = lerp(500.0, 200.0, progress)
		var tone = sin(2.0 * PI * freq * t)
		var sample = clamp(tone * envelope, -1.0, 1.0)
		var pcm = int(sample * 32767)
		data[i * 2]     = pcm & 0xFF
		data[i * 2 + 1] = (pcm >> 8) & 0xFF

	return _bytes_to_wav(data, sample_rate)

# -----------------------------------------------
# BACKGROUND MUSIC GENERATORS
# These make simple looping tunes using notes.
# -----------------------------------------------

func _gen_battle_music() -> AudioStreamWAV:
	# Tense, repeating low-note pattern
	var sample_rate = 22050
	var bpm = 140.0
	var beat = 60.0 / bpm
	# Pattern: 8 beats, 2 bars
	var pattern = [110.0, 0.0, 110.0, 0.0, 138.6, 0.0, 110.0, 0.0,
				   98.0,  0.0,  98.0, 0.0, 123.5, 0.0,  98.0, 0.0]
	var total_samples = int(sample_rate * beat * pattern.size())
	var data = PackedByteArray()
	data.resize(total_samples * 2)

	for n in range(pattern.size()):
		var freq = pattern[n]
		var start = int(n * sample_rate * beat)
		var note_samples = int(sample_rate * beat * 0.85)
		for i in range(note_samples):
			if freq == 0.0:
				continue
			var t = float(i) / sample_rate
			var progress = float(i) / note_samples
			var envelope = min(progress * 8.0, 1.0) * pow(1.0 - progress, 0.5)
			var tone = sin(2.0 * PI * freq * t) * 0.5
			tone += sin(2.0 * PI * freq * 2.0 * t) * 0.2
			tone += sin(2.0 * PI * freq * 3.0 * t) * 0.1
			var sample = clamp(tone * envelope * 0.4, -1.0, 1.0)
			var pcm = int(sample * 32767)
			var idx = (start + i) * 2
			if idx + 1 < data.size():
				data[idx]     = pcm & 0xFF
				data[idx + 1] = (pcm >> 8) & 0xFF

	var wav = _bytes_to_wav(data, sample_rate)
	wav.loop_mode = 1  # 1 = LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = total_samples
	return wav

func _gen_menu_music() -> AudioStreamWAV:
	# Gentle, slower tune for the deploy/menu screens
	var sample_rate = 22050
	var bpm = 90.0
	var beat = 60.0 / bpm
	var pattern = [261.63, 329.63, 392.00, 523.25,
				   392.00, 349.23, 329.63, 261.63]
	var total_samples = int(sample_rate * beat * pattern.size())
	var data = PackedByteArray()
	data.resize(total_samples * 2)

	for n in range(pattern.size()):
		var freq = pattern[n]
		var start = int(n * sample_rate * beat)
		var note_samples = int(sample_rate * beat * 0.75)
		for i in range(note_samples):
			var t = float(i) / sample_rate
			var progress = float(i) / note_samples
			var envelope = sin(PI * progress) * 0.35
			var tone = sin(2.0 * PI * freq * t)
			tone += sin(2.0 * PI * freq * 2.0 * t) * 0.15
			var sample = clamp(tone * envelope, -1.0, 1.0)
			var pcm = int(sample * 32767)
			var idx = (start + i) * 2
			if idx + 1 < data.size():
				data[idx]     = pcm & 0xFF
				data[idx + 1] = (pcm >> 8) & 0xFF

	var wav = _bytes_to_wav(data, sample_rate)
	wav.loop_mode = 1  # 1 = LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = total_samples
	return wav

# -----------------------------------------------
# HELPER: turn raw PCM bytes into a playable WAV
# -----------------------------------------------
func _bytes_to_wav(data: PackedByteArray, sample_rate: int) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.data = data
	wav.format = 1  # 1 = 16-bit PCM (FORMAT_16_BIT)
	wav.mix_rate = sample_rate
	wav.stereo = false
	return wav
