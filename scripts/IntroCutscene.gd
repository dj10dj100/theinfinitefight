extends Control

# -----------------------------------------------
# INTRO CUTSCENE
# Plays once when you start the game for the
# first time. Shows the Rogue commanders planning
# their attack before the fight begins!
# Press SPACE or click SKIP to jump past it.
# -----------------------------------------------

# Each "beat" in the cutscene is a line of text
# that appears on screen before moving on.
const BEATS = [
	# [text, colour, font_size, pause_after_seconds]
	["...",                                                               "dim",    22, 1.2],
	["Somewhere deep behind enemy lines...",                             "dim",    22, 2.0],
	["A tent. A single lamp. The smell of gunpowder.",                   "dim",    20, 2.5],
	["The Rogue commanders huddle around a map.",                        "dim",    20, 2.0],
	["",                                                                 "dim",    20, 0.5],
	['"Our old allies are weakened."',                                   "rogue",  26, 2.2],
	['"Tonight... we finish them for good."',                            "rogue",  28, 2.5],
	["A fist slams the table.",                                          "dim",    18, 1.5],
	['"Move the entire army at dawn."',                                  "rogue",  26, 2.2],
	["",                                                                 "dim",    20, 0.3],
	["Outside the tent...",                                              "dim",    20, 1.5],
	["...an army stretches into the darkness.",                          "dim",    20, 2.0],
	["Hundreds of them. Armed. Ready.",                                  "dim",    22, 2.5],
	["",                                                                 "dim",    20, 0.5],
	["They think you're finished.",                                      "white",  34, 2.5],
	["Prove them wrong.",                                                "gold",   46, 3.5],
]

var current_beat: int = 0
var skip_requested: bool = false
var typing: bool = false

# UI nodes
var text_label: Label
var scene_label: Label   # small location text top-left
var skip_label: Label
var black_overlay: ColorRect

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	build_ui()
	play_cutscene()

func build_ui():
	# Full black background
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 1)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Location caption (top left — like a movie)
	scene_label = Label.new()
	scene_label.text = "[ Enemy Territory — 02:00 ]"
	scene_label.add_theme_font_size_override("font_size", 14)
	scene_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	scene_label.set_anchor(SIDE_LEFT, 0);  scene_label.set_anchor(SIDE_RIGHT,  0.5)
	scene_label.set_anchor(SIDE_TOP, 0);   scene_label.set_anchor(SIDE_BOTTOM, 0)
	scene_label.offset_left = 30;          scene_label.offset_top = 20
	scene_label.offset_right = 500;        scene_label.offset_bottom = 45
	scene_label.modulate.a = 0.0
	scene_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scene_label)

	# Main story text (centre of screen)
	text_label = Label.new()
	text_label.text = ""
	text_label.add_theme_font_size_override("font_size", 28)
	text_label.add_theme_color_override("font_color", Color(1, 1, 1))
	text_label.set_anchor(SIDE_LEFT,  0.05); text_label.set_anchor(SIDE_RIGHT,  0.95)
	text_label.set_anchor(SIDE_TOP,   0.4);  text_label.set_anchor(SIDE_BOTTOM, 0.65)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(text_label)

	# Skip hint (bottom right)
	skip_label = Label.new()
	skip_label.text = "SPACE / Click to skip"
	skip_label.add_theme_font_size_override("font_size", 13)
	skip_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	skip_label.set_anchor(SIDE_LEFT,  0.7);  skip_label.set_anchor(SIDE_RIGHT,  1.0)
	skip_label.set_anchor(SIDE_TOP,   1.0);  skip_label.set_anchor(SIDE_BOTTOM, 1.0)
	skip_label.offset_top = -35;             skip_label.offset_bottom = -10
	skip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(skip_label)

	# Black overlay for fade transitions
	black_overlay = ColorRect.new()
	black_overlay.color = Color(0, 0, 0, 0)
	black_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(black_overlay)

# -----------------------------------------------
# SKIP on spacebar or click
# -----------------------------------------------
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		finish_cutscene()
	if event is InputEventMouseButton and event.pressed:
		finish_cutscene()

# -----------------------------------------------
# PLAY THROUGH ALL THE BEATS
# -----------------------------------------------
func play_cutscene():
	# Fade in the location label
	var tween = create_tween()
	tween.tween_property(scene_label, "modulate:a", 1.0, 1.5)
	await tween.finished

	for i in range(BEATS.size()):
		if skip_requested:
			break
		current_beat = i
		await show_beat(BEATS[i])
		if skip_requested:
			break

	finish_cutscene()

func show_beat(beat: Array) -> void:
	var full_text:  String = beat[0]
	var style:      String = beat[1]
	var font_size:  int    = beat[2]
	var pause_time: float  = beat[3]

	# Set the colour based on who's speaking / what's happening
	var colour: Color
	match style:
		"rogue":  colour = Color(0.95, 0.25, 0.25)   # Red — the enemy speaking
		"white":  colour = Color(1.00, 1.00, 1.00)   # White — narrator
		"gold":   colour = Color(1.00, 0.85, 0.15)   # Gold — the big motivational line
		_:        colour = Color(0.60, 0.60, 0.65)   # Dim grey — scene description

	text_label.add_theme_font_size_override("font_size", font_size)
	text_label.add_theme_color_override("font_color", colour)
	text_label.modulate.a = 0.0
	text_label.text = full_text

	# Fade in
	var fade_in = create_tween()
	fade_in.tween_property(text_label, "modulate:a", 1.0, 0.6)
	await fade_in.finished

	# Hold for the pause duration
	await get_tree().create_timer(pause_time).timeout

	# Fade out
	if not skip_requested:
		var fade_out = create_tween()
		fade_out.tween_property(text_label, "modulate:a", 0.0, 0.4)
		await fade_out.finished

# -----------------------------------------------
# END THE CUTSCENE — fade to black then move on
# -----------------------------------------------
func finish_cutscene():
	if skip_requested:
		return
	skip_requested = true

	# Fade everything to black
	var fade = create_tween()
	fade.tween_property(black_overlay, "color:a", 1.0, 1.2)
	await fade.finished

	# Mark cutscene as seen so it doesn't play again
	if GameManager:
		GameManager.intro_seen = true
		GameManager.save_player_data()

	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
