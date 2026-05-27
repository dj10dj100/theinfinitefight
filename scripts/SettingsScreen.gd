extends Control

# -----------------------------------------------
# SETTINGS SCREEN
# Change your difficulty at any time from here.
# Your choice is saved straight away!
# -----------------------------------------------

var chosen_difficulty: String = "medium"
var difficulty_buttons: Dictionary = {}

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Start with whatever difficulty is already saved
	if GameManager:
		chosen_difficulty = GameManager.difficulty

	build_ui()

func build_ui():
	# Dark background
	var bg = ColorRect.new()
	bg.color = Color(0.07, 0.08, 0.11)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Title
	var title = Label.new()
	title.text = "⚙  SETTINGS"
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	title.set_anchor(SIDE_LEFT, 0);   title.set_anchor(SIDE_RIGHT,  1)
	title.set_anchor(SIDE_TOP, 0);    title.set_anchor(SIDE_BOTTOM, 0)
	title.offset_top = 40;            title.offset_bottom = 95
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	# Current difficulty label
	var current_lbl = Label.new()
	current_lbl.name = "CurrentLabel"
	current_lbl.text = "Current difficulty:  " + chosen_difficulty.capitalize()
	current_lbl.add_theme_font_size_override("font_size", 18)
	current_lbl.add_theme_color_override("font_color", Color(0.5, 1.0, 0.6))
	current_lbl.set_anchor(SIDE_LEFT, 0);   current_lbl.set_anchor(SIDE_RIGHT,  1)
	current_lbl.set_anchor(SIDE_TOP, 0);    current_lbl.set_anchor(SIDE_BOTTOM, 0)
	current_lbl.offset_top = 105;           current_lbl.offset_bottom = 132
	current_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	current_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(current_lbl)

	# Section heading
	var heading = Label.new()
	heading.text = "Choose a new difficulty:"
	heading.add_theme_font_size_override("font_size", 20)
	heading.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	heading.set_anchor(SIDE_LEFT, 0);   heading.set_anchor(SIDE_RIGHT,  1)
	heading.set_anchor(SIDE_TOP, 0);    heading.set_anchor(SIDE_BOTTOM, 0)
	heading.offset_top = 150;           heading.offset_bottom = 180
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(heading)

	# Difficulty options
	var difficulties = [
		{
			"key":   "easy",
			"label": "😊  Easy",
			"desc":  "Enemies are weak\nUnlocks come quickly"
		},
		{
			"key":   "medium",
			"label": "😐  Medium",
			"desc":  "A fair fight\nGood for learning"
		},
		{
			"key":   "hard",
			"label": "😤  Hard",
			"desc":  "Enemies hit harder\nUnlocks are slower"
		},
		{
			"key":   "bloodthirsty",
			"label": "🩸  Bloodthirsty",
			"desc":  "Pure brutal chaos\nOnly for the brave!"
		},
	]

	var btn_w = 190
	var btn_h = 100
	var gap   = 16
	var total_w = (btn_w * 4) + (gap * 3)

	for i in range(difficulties.size()):
		var d   = difficulties[i]
		var btn = Button.new()
		btn.text = d["label"] + "\n\n" + d["desc"]
		btn.custom_minimum_size = Vector2(btn_w, btn_h)

		# Position side by side in the centre
		btn.set_anchor(SIDE_LEFT,  0.5)
		btn.set_anchor(SIDE_RIGHT, 0.5)
		btn.set_anchor(SIDE_TOP,   0)
		btn.set_anchor(SIDE_BOTTOM, 0)
		var offset_x = (i - 1.5) * (btn_w + gap)
		btn.offset_left   = offset_x - btn_w * 0.5
		btn.offset_right  = offset_x + btn_w * 0.5
		btn.offset_top    = 195
		btn.offset_bottom = 195 + btn_h

		btn.pressed.connect(select_difficulty.bind(d["key"], btn))
		add_child(btn)
		difficulty_buttons[d["key"]] = btn

	# Highlight the current difficulty straight away
	if difficulty_buttons.has(chosen_difficulty):
		difficulty_buttons[chosen_difficulty].modulate = Color(0.3, 1.0, 0.45)

	# What changes with difficulty — info box
	var info = Label.new()
	info.text = "Higher difficulty = tougher enemies but more exciting battles!\nYou can change this again any time from the Deploy Screen."
	info.add_theme_font_size_override("font_size", 14)
	info.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	info.set_anchor(SIDE_LEFT, 0.1);  info.set_anchor(SIDE_RIGHT,  0.9)
	info.set_anchor(SIDE_TOP, 0);     info.set_anchor(SIDE_BOTTOM, 0)
	info.offset_top = 310;            info.offset_bottom = 360
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(info)

	# Save button
	var save_btn = Button.new()
	save_btn.text = "✅  Save & Go Back"
	save_btn.add_theme_font_size_override("font_size", 22)
	save_btn.set_anchor(SIDE_LEFT,  0.3)
	save_btn.set_anchor(SIDE_RIGHT, 0.7)
	save_btn.set_anchor(SIDE_TOP,   0)
	save_btn.set_anchor(SIDE_BOTTOM, 0)
	save_btn.offset_top    = 375
	save_btn.offset_bottom = 430
	save_btn.pressed.connect(_on_save_pressed)
	add_child(save_btn)

	# Back without saving
	var back_btn = Button.new()
	back_btn.text = "← Back without saving"
	back_btn.add_theme_font_size_override("font_size", 14)
	back_btn.set_anchor(SIDE_LEFT,  0.35)
	back_btn.set_anchor(SIDE_RIGHT, 0.65)
	back_btn.set_anchor(SIDE_TOP,   0)
	back_btn.set_anchor(SIDE_BOTTOM, 0)
	back_btn.offset_top    = 438
	back_btn.offset_bottom = 468
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/DeployScreen.tscn"))
	add_child(back_btn)

func select_difficulty(diff: String, btn: Button):
	chosen_difficulty = diff
	# Highlight selected, dim the rest
	for key in difficulty_buttons:
		difficulty_buttons[key].modulate = Color(1, 1, 1)
	btn.modulate = Color(0.3, 1.0, 0.45)

func _on_save_pressed():
	if GameManager:
		GameManager.difficulty = chosen_difficulty
		GameManager.save_player_data()
		print("Difficulty changed to: ", chosen_difficulty)

	get_tree().change_scene_to_file("res://scenes/DeployScreen.tscn")
