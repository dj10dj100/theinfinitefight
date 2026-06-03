extends Node

# -----------------------------------------------
# VOICE LINES
# Your clones shout funny battle phrases!
# The text pops up as a speech bubble above their
# head, and a little voice-like beep plays.
# -----------------------------------------------

const SHOOT_LINES = [
	"For the Commander!",
	"Take that!",
	"Eat plastic!",
	"Never surrender!",
	"Incoming fire!",
	"I've got you now!",
	"Locked on target!",
	"Stay back!",
	"FOR ARNOLD!",
	"You can't stop us!",
	"Taste my bullets!",
	"I am UNSTOPPABLE!",
	"My trigger finger is ready!",
	"Pew pew pew!",
	"Duck, sucker!",
	"I've been training for THIS!",
	"Nobody beats us!",
	"I skipped lunch for this!",
]

const HIT_LINES = [
	"Ow!",
	"I'm hit!",
	"That stings!",
	"Keep going!",
	"Argh!",
	"Hold the line!",
	"Is that the best you've got?!",
	"RUDE!",
	"My leg! Wait... I don't have legs.",
	"Ouch! Who threw that?!",
	"I'm fine! Totally fine!",
	"That'll leave a mark.",
]

const DEATH_LINES = [
	"Tell the Commander...",
	"Nooooo!",
	"I'll be back... maybe.",
	"It was an honour!",
	"Avenge meeee!",
	"I regret nothing!",
	"Arnold... I'm sorry...",
	"Tell my family... I was plastic.",
	"Was it something I said?!",
	"Worth it. Totally worth it.",
	"Goodbye, cruel battlefield!",
	"I should've stayed in the box.",
]

const VICTORY_LINES = [
	"Victory is ours!",
	"We did it!",
	"FOR THE COMMANDER!",
	"Plastic and proud!",
	"ARNOLD WINS AGAIN!",
	"Nobody can stop us!",
	"That was too easy!",
	"Let's do that again!",
]

# New: lines when throwing special weapons
const GRENADE_LINES = [
	"Catch! 💣",
	"GRENADE OUT!",
	"Don't say I never gave you anything!",
	"Boom present incoming!",
]

const AIRSTRIKE_LINES = [
	"Air support — GO GO GO!",
	"Rain fire from above!",
	"Sorry, can't hear you over the BOMBS!",
	"They'll never see it coming!",
]

const ENEMY_TAUNT_LINES = [
	"You plastic fools!",
	"Give up now!",
	"The Rogue never loses!",
	"Is that your best?!",
	"Your clones are DONE!",
	"Run away, little soldiers!",
	"We outnumber you!",
	"Surrender or be melted!",
	"Ha! Pathetic!",
	"You can't stop us!",
	"Your commander is a joke!",
	"We will crush you!",
	"My grandmother shoots better!",
	"Too slow!",
	"Feel the wrath of The Rogue!",
]

const ENEMY_DEATH_TAUNTS = [
	"This isn't over...",
	"The Rogue will avenge me!",
	"Lucky shot...",
	"I'll be back!",
	"Impossible...",
	"Tell the General... I tried.",
]

# Only say something every so often — otherwise it gets too noisy!
var _shoot_cooldown:  float = 0.0
var _hit_cooldown:    float = 0.0
var _taunt_cooldown:  float = 0.0

func _process(delta):
	_shoot_cooldown = max(_shoot_cooldown - delta, 0.0)
	_hit_cooldown   = max(_hit_cooldown   - delta, 0.0)
	_taunt_cooldown = max(_taunt_cooldown - delta, 0.0)

# -----------------------------------------------
# CALL THESE FROM CLONE.GD
# -----------------------------------------------
func say_shoot(world_pos: Vector3):
	if _shoot_cooldown > 0:
		return
	# Only say something 1 in 4 shots so it doesn't spam
	if randi() % 4 != 0:
		return
	_shoot_cooldown = 2.5
	var line = SHOOT_LINES[randi() % SHOOT_LINES.size()]
	_show_bubble(line, world_pos, Color(0.9, 1.0, 0.9))
	_play_battle_shout()

func say_hit(world_pos: Vector3):
	if _hit_cooldown > 0:
		return
	_hit_cooldown = 1.5
	var line = HIT_LINES[randi() % HIT_LINES.size()]
	_show_bubble(line, world_pos, Color(1.0, 0.85, 0.5))
	_play_pain_grunt()

func say_death(world_pos: Vector3):
	var line = DEATH_LINES[randi() % DEATH_LINES.size()]
	_show_bubble(line, world_pos, Color(1.0, 0.5, 0.5))
	_play_death_moan()

func say_enemy_taunt(world_pos: Vector3):
	if _taunt_cooldown > 0:
		return
	if randi() % 5 != 0:   # Only 1 in 5 shots — not too spammy
		return
	_taunt_cooldown = 4.0
	var line = ENEMY_TAUNT_LINES[randi() % ENEMY_TAUNT_LINES.size()]
	_show_bubble(line, world_pos, Color(1.0, 0.4, 0.4))
	_play_battle_shout()

func say_enemy_death(world_pos: Vector3):
	var line = ENEMY_DEATH_TAUNTS[randi() % ENEMY_DEATH_TAUNTS.size()]
	_show_bubble(line, world_pos, Color(0.9, 0.5, 0.5))
	_play_death_moan()

func say_grenade(world_pos: Vector3):
	var line = GRENADE_LINES[randi() % GRENADE_LINES.size()]
	_show_bubble(line, world_pos, Color(1.0, 0.75, 0.2))
	_play_battle_shout()

func say_airstrike(world_pos: Vector3):
	var line = AIRSTRIKE_LINES[randi() % AIRSTRIKE_LINES.size()]
	_show_bubble(line, world_pos, Color(0.5, 0.8, 1.0))
	_play_battle_shout()

func say_victory():
	var line = VICTORY_LINES[randi() % VICTORY_LINES.size()]
	# Show in the middle of the screen
	_show_screen_text(line, Color(1.0, 0.9, 0.2))
	_play_battle_shout()

# -----------------------------------------------
# SHOW A SPEECH BUBBLE AT A WORLD POSITION
# The bubble appears as a label floating in a
# CanvasLayer (so it always faces the camera)
# -----------------------------------------------
func _show_bubble(text: String, world_pos: Vector3, colour: Color):
	# We'll project the 3D position to 2D screen space
	var canvas = CanvasLayer.new()
	var label = Label.new()
	label.text = "💬 " + text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", colour)

	# Dark background pill
	var bg = ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.72)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var container = PanelContainer.new()
	container.add_child(bg)
	container.add_child(label)

	# Try to find a camera and project the position
	var camera = _find_camera()
	var screen_pos = Vector2(randf_range(200, 800), randf_range(100, 400))
	if camera:
		screen_pos = camera.unproject_position(world_pos + Vector3(0, 2.0, 0))

	container.position = screen_pos - Vector2(80, 20)
	canvas.add_child(container)
	get_tree().root.add_child(canvas)

	# Float upward and fade out
	var tween = get_tree().create_tween()
	tween.tween_property(container, "position:y", container.position.y - 55, 2.2)
	tween.parallel().tween_interval(1.4)
	tween.tween_property(container, "modulate:a", 0.0, 0.8)
	tween.tween_callback(canvas.queue_free)

func _show_screen_text(text: String, colour: Color):
	var canvas = CanvasLayer.new()
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", colour)
	label.set_anchor(SIDE_LEFT, 0.5)
	label.set_anchor(SIDE_RIGHT, 0.5)
	label.set_anchor(SIDE_TOP, 0)
	label.set_anchor(SIDE_BOTTOM, 0)
	label.offset_left   = -200
	label.offset_right  =  200
	label.offset_top    =  120
	label.offset_bottom =  165
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	canvas.add_child(label)
	get_tree().root.add_child(canvas)

	var tween = get_tree().create_tween()
	tween.tween_property(label, "position:y", label.position.y - 40, 2.5)
	tween.parallel().tween_interval(1.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.7)
	tween.tween_callback(canvas.queue_free)

# -----------------------------------------------
# VOICE SOUNDS
# Three different voices depending on what happened!
# All made from maths — no audio files needed.
# -----------------------------------------------

# Battle shout — fast excited "Ah-HAH!" rising yell
func _play_battle_shout():
	var sample_rate = 22050
	# Two syllables: short rising then short falling
	var duration = 0.32
	var samples  = int(sample_rate * duration)
	var data     = PackedByteArray()
	data.resize(samples * 2)

	# Each clone gets a slightly different pitch so they don't all sound the same
	var pitch_shift = randf_range(0.85, 1.15)

	for i in range(samples):
		var t        = float(i) / sample_rate
		var progress = float(i) / samples

		# Two-syllable shape: first syllable 0→0.45, second 0.5→1.0
		var envelope = 0.0
		var freq     = 220.0 * pitch_shift
		if progress < 0.45:
			# First syllable — rises up
			var p = progress / 0.45
			envelope = sin(PI * p) * 0.55
			freq = lerp(180.0, 320.0, p) * pitch_shift
		elif progress > 0.55:
			# Second syllable — punchy and short
			var p = (progress - 0.55) / 0.45
			envelope = sin(PI * p) * 0.70
			freq = lerp(360.0, 240.0, p) * pitch_shift

		# Voice = fundamental + harmonics + buzz (like vocal cords)
		var voice = sin(2.0 * PI * freq * t)
		voice    += sin(2.0 * PI * freq * 2.0 * t) * 0.35
		voice    += sin(2.0 * PI * freq * 3.0 * t) * 0.18
		voice    += sin(2.0 * PI * freq * 4.0 * t) * 0.08
		# Slight buzz — rough vocal cord texture
		voice    += sin(2.0 * PI * freq * 1.5 * t) * 0.12

		var s = clamp(voice * envelope * 0.4, -1.0, 1.0)
		var pcm = int(s * 32767)
		data[i * 2]     = pcm & 0xFF
		data[i * 2 + 1] = (pcm >> 8) & 0xFF

	_play_wav_data(data, sample_rate, -4.0)

# Pain grunt — short sharp "Ngh!" or "Ugh!"
func _play_pain_grunt():
	var sample_rate = 22050
	var duration    = 0.20
	var samples     = int(sample_rate * duration)
	var data        = PackedByteArray()
	data.resize(samples * 2)

	var pitch_shift = randf_range(0.80, 1.10)

	for i in range(samples):
		var t        = float(i) / sample_rate
		var progress = float(i) / samples

		# Short stab — fast attack, quick decay
		var envelope = pow(1.0 - progress, 1.8) * min(progress * 12.0, 1.0) * 0.65

		# Starts mid-pitch, drops down (pain makes pitch fall)
		var freq = lerp(280.0, 140.0, progress) * pitch_shift

		var voice = sin(2.0 * PI * freq * t)
		voice    += sin(2.0 * PI * freq * 2.0 * t) * 0.40
		voice    += sin(2.0 * PI * freq * 3.0 * t) * 0.20
		# Breathy noise mixed in — adds "grunt" texture
		voice    += randf_range(-1.0, 1.0) * 0.15

		var s = clamp(voice * envelope, -1.0, 1.0)
		var pcm = int(s * 32767)
		data[i * 2]     = pcm & 0xFF
		data[i * 2 + 1] = (pcm >> 8) & 0xFF

	_play_wav_data(data, sample_rate, -5.0)

# Death moan — slow falling "Nooooo..." trailing off
func _play_death_moan():
	var sample_rate = 22050
	var duration    = 0.55
	var samples     = int(sample_rate * duration)
	var data        = PackedByteArray()
	data.resize(samples * 2)

	var pitch_shift = randf_range(0.75, 1.05)

	for i in range(samples):
		var t        = float(i) / sample_rate
		var progress = float(i) / samples

		# Long drawn-out fade — rises slightly then slowly fades away
		var envelope = min(progress * 5.0, 1.0) * pow(1.0 - progress, 0.7) * 0.60

		# Pitch starts normal and slowly drops — like a sad moan
		var freq = lerp(240.0, 90.0, progress) * pitch_shift

		# Add vibrato — slight wobble in pitch (like real singing/moaning)
		var vibrato = sin(t * 11.0) * 12.0 * progress
		freq += vibrato

		var voice = sin(2.0 * PI * freq * t)
		voice    += sin(2.0 * PI * freq * 2.0 * t) * 0.45
		voice    += sin(2.0 * PI * freq * 3.0 * t) * 0.22
		voice    += sin(2.0 * PI * freq * 0.5 * t) * 0.15  # Sub-harmonic (depth)
		# Small breathy noise at the end
		voice    += randf_range(-1.0, 1.0) * 0.08 * progress

		var s = clamp(voice * envelope, -1.0, 1.0)
		var pcm = int(s * 32767)
		data[i * 2]     = pcm & 0xFF
		data[i * 2 + 1] = (pcm >> 8) & 0xFF

	_play_wav_data(data, sample_rate, -3.0)

# Shared helper — builds a WAV and plays it
func _play_wav_data(data: PackedByteArray, sample_rate: int, volume_db: float):
	var wav = AudioStreamWAV.new()
	wav.data     = data
	wav.format   = 1   # FORMAT_16_BIT
	wav.mix_rate = sample_rate
	wav.stereo   = false

	var player = AudioStreamPlayer.new()
	player.stream    = wav
	player.volume_db = volume_db
	get_tree().root.add_child(player)
	player.play()
	await player.finished
	player.queue_free()

# -----------------------------------------------
# FIND THE ACTIVE CAMERA
# -----------------------------------------------
func _find_camera() -> Camera3D:
	var cameras = get_tree().get_nodes_in_group("active_camera")
	if cameras.size() > 0:
		return cameras[0]
	# Fallback — find any current camera
	var all = get_tree().root.find_children("*", "Camera3D", true, false)
	for c in all:
		if c is Camera3D and c.current:
			return c
	return null
