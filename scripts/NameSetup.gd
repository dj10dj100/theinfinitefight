extends Control

# -----------------------------------------------
# NAME SETUP SCREEN
# Only shown the very first time you play.
# You pick your name (max 10 characters) and
# choose your difficulty.
# -----------------------------------------------

var chosen_difficulty: String = "medium"
var difficulty_buttons: Dictionary = {}

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await show_title_card()

	# If the player already has a name saved, skip straight to the main menu
	if GameManager and GameManager.player_name != "":
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
		return

	build_ui()

# -----------------------------------------------
# TITLE CARD — shows every time the game boots
# -----------------------------------------------
func show_title_card():
	# Full black background for the title
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 1)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Big title text
	var title = Label.new()
	title.text = "THE INFINITE FIGHT"
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	title.set_anchor(SIDE_LEFT,  0.0);  title.set_anchor(SIDE_RIGHT,  1.0)
	title.set_anchor(SIDE_TOP,   0.35); title.set_anchor(SIDE_BOTTOM, 0.6)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	title.modulate.a = 0.0
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	# Fade in the title
	var fade_in = create_tween()
	fade_in.tween_property(title, "modulate:a", 1.0, 1.8)
	await fade_in.finished

	await get_tree().create_timer(0.4).timeout

	# Blood splat explodes from the title!
	_spawn_title_blood_splat()
	SoundManager.play("hit")

	await get_tree().create_timer(1.8).timeout

	# Fade everything out
	var fade_out = create_tween()
	fade_out.tween_property(title, "modulate:a", 0.0, 0.6)
	fade_out.parallel().tween_property(bg, "modulate:a", 0.0, 0.8)
	await fade_out.finished

	title.queue_free()
	bg.queue_free()

func _spawn_title_blood_splat():
	var vp     = get_viewport_rect().size
	var center = Vector2(vp.x * 0.5, vp.y * 0.47)

	# Use a CanvasLayer so positions work as real screen coordinates
	var canvas = CanvasLayer.new()
	canvas.layer = 15
	get_tree().root.add_child(canvas)

	for i in range(22):
		var drop = ColorRect.new()
		var w    = randf_range(10.0, 35.0)
		var h    = randf_range(10.0, 35.0)
		drop.size     = Vector2(w, h)
		drop.color    = Color(randf_range(0.5, 1.0), 0.0, 0.0, 1.0)
		drop.position = center - drop.size * 0.5   # start at centre of title
		drop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(drop)

		# Fire outward in a random direction — far enough to look like an explosion!
		var angle  = randf_range(0.0, TAU)
		var dist   = randf_range(80.0, 280.0)
		var target = center + Vector2(cos(angle), sin(angle)) * dist

		var tw = get_tree().create_tween()
		tw.tween_property(drop, "position", target, 0.3).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.8)
		tw.tween_property(drop, "modulate:a", 0.0, 0.4)
		tw.tween_callback(drop.queue_free)

	# Clean up the canvas layer after everything fades
	var cleanup = get_tree().create_tween()
	cleanup.tween_interval(2.2)
	cleanup.tween_callback(canvas.queue_free)

func build_ui():
	# Dark background
	var bg = ColorRect.new()
	bg.color = Color(0.06, 0.07, 0.10)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Big game title
	var title = Label.new()
	title.text = "THE INFINITE FIGHT"
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.15))
	title.set_anchor(SIDE_LEFT, 0);   title.set_anchor(SIDE_RIGHT,  1)
	title.set_anchor(SIDE_TOP, 0);    title.set_anchor(SIDE_BOTTOM, 0)
	title.offset_top = 60;            title.offset_bottom = 120
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Commander, what is your name?"
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	subtitle.set_anchor(SIDE_LEFT, 0);   subtitle.set_anchor(SIDE_RIGHT,  1)
	subtitle.set_anchor(SIDE_TOP, 0);    subtitle.set_anchor(SIDE_BOTTOM, 0)
	subtitle.offset_top = 130;           subtitle.offset_bottom = 165
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(subtitle)

	# Name input box
	var name_input = LineEdit.new()
	name_input.name = "NameInput"
	name_input.placeholder_text = "Tap here to type your name..."
	name_input.max_length = 10
	name_input.set_anchor(SIDE_LEFT,  0.25); name_input.set_anchor(SIDE_RIGHT, 0.75)
	name_input.set_anchor(SIDE_TOP,   0);    name_input.set_anchor(SIDE_BOTTOM, 0)
	name_input.offset_top = 175;             name_input.offset_bottom = 215
	name_input.add_theme_font_size_override("font_size", 22)
	name_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	# On mobile, show the on-screen keyboard when this box is tapped
	name_input.virtual_keyboard_enabled = true
	name_input.focus_entered.connect(func():
		DisplayServer.virtual_keyboard_show(name_input.text)
	)
	name_input.focus_exited.connect(func():
		DisplayServer.virtual_keyboard_hide()
	)
	add_child(name_input)

	var char_hint = Label.new()
	char_hint.text = "Maximum 10 characters"
	char_hint.add_theme_font_size_override("font_size", 12)
	char_hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	char_hint.set_anchor(SIDE_LEFT, 0);   char_hint.set_anchor(SIDE_RIGHT,  1)
	char_hint.set_anchor(SIDE_TOP, 0);    char_hint.set_anchor(SIDE_BOTTOM, 0)
	char_hint.offset_top = 218;           char_hint.offset_bottom = 238
	char_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	char_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(char_hint)

	# Difficulty heading
	var diff_label = Label.new()
	diff_label.text = "Choose your difficulty:"
	diff_label.add_theme_font_size_override("font_size", 20)
	diff_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	diff_label.set_anchor(SIDE_LEFT, 0);   diff_label.set_anchor(SIDE_RIGHT,  1)
	diff_label.set_anchor(SIDE_TOP, 0);    diff_label.set_anchor(SIDE_BOTTOM, 0)
	diff_label.offset_top = 265;           diff_label.offset_bottom = 295
	diff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	diff_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(diff_label)

	# Difficulty buttons side by side
	var difficulties = [
		{"key": "easy",         "label": "😊 Easy",        "desc": "Enemies are weak"},
		{"key": "medium",       "label": "😐 Medium",       "desc": "A fair fight"},
		{"key": "hard",         "label": "😤 Hard",         "desc": "Enemies hit harder"},
		{"key": "bloodthirsty", "label": "🩸 Bloodthirsty", "desc": "Pure chaos!"}
	]

	var btn_width  = 170
	var btn_height = 80
	var total_w    = btn_width * 4 + 30  # 4 buttons + 3 gaps of 10
	var start_x_anchor = 0.5 - (float(total_w) / 2.0) / 1280.0  # rough centre

	for i in range(difficulties.items().size() if false else difficulties.size()):
		var d   = difficulties[i]
		var btn = Button.new()
		btn.name = "DiffBtn_" + d["key"]

		var vbox = VBoxContainer.new()
		var lbl1 = Label.new()
		lbl1.text = d["label"]
		lbl1.add_theme_font_size_override("font_size", 15)
		lbl1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var lbl2 = Label.new()
		lbl2.text = d["desc"]
		lbl2.add_theme_font_size_override("font_size", 11)
		lbl2.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
		lbl2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		# Use a plain button with text for simplicity
		btn.text = d["label"] + "\n" + d["desc"]
		btn.custom_minimum_size = Vector2(btn_width, btn_height)
		btn.set_anchor(SIDE_LEFT,  0.5); btn.set_anchor(SIDE_RIGHT, 0.5)
		btn.set_anchor(SIDE_TOP,   0);   btn.set_anchor(SIDE_BOTTOM, 0)
		var offset_x = (i - 1.5) * (btn_width + 10)
		btn.offset_left   = offset_x - btn_width * 0.5
		btn.offset_right  = offset_x + btn_width * 0.5
		btn.offset_top    = 305
		btn.offset_bottom = 305 + btn_height
		btn.pressed.connect(select_difficulty.bind(d["key"], btn))
		add_child(btn)
		difficulty_buttons[d["key"]] = btn

	# Highlight the default (medium)
	select_difficulty("medium", difficulty_buttons["medium"])

	# Error label (shows if name is empty)
	var error_lbl = Label.new()
	error_lbl.name = "ErrorLabel"
	error_lbl.text = ""
	error_lbl.add_theme_font_size_override("font_size", 14)
	error_lbl.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	error_lbl.set_anchor(SIDE_LEFT, 0);   error_lbl.set_anchor(SIDE_RIGHT,  1)
	error_lbl.set_anchor(SIDE_TOP, 0);    error_lbl.set_anchor(SIDE_BOTTOM, 0)
	error_lbl.offset_top = 400;           error_lbl.offset_bottom = 425
	error_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(error_lbl)

	# START button
	var start_btn = Button.new()
	start_btn.text = "🚀  START GAME!"
	start_btn.add_theme_font_size_override("font_size", 26)
	start_btn.set_anchor(SIDE_LEFT,  0.3); start_btn.set_anchor(SIDE_RIGHT, 0.7)
	start_btn.set_anchor(SIDE_TOP,   0);   start_btn.set_anchor(SIDE_BOTTOM, 0)
	start_btn.offset_top = 430;            start_btn.offset_bottom = 490
	start_btn.pressed.connect(_on_start_pressed)
	add_child(start_btn)

func select_difficulty(diff: String, btn: Button):
	chosen_difficulty = diff
	for key in difficulty_buttons:
		difficulty_buttons[key].modulate = Color(1, 1, 1)
	btn.modulate = Color(0.3, 1.0, 0.45)

func _on_start_pressed():
	var name_input = get_node("NameInput") as LineEdit
	var entered_name = name_input.text.strip_edges()

	if entered_name.length() == 0:
		get_node("ErrorLabel").text = "Please enter a name!"
		return
	if entered_name.length() > 10:
		get_node("ErrorLabel").text = "Name must be 10 characters or less!"
		return

	# Save to GameManager
	GameManager.player_name = entered_name
	GameManager.difficulty  = chosen_difficulty
	GameManager.save_player_data()

	print("Welcome, Commander ", entered_name, "! Difficulty: ", chosen_difficulty)
	# Play the intro cutscene the very first time!
	get_tree().change_scene_to_file("res://scenes/IntroCutscene.tscn")
