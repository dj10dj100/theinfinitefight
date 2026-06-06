extends Control

# -----------------------------------------------
# MAIN MENU
# The hub between NameSetup and the battlefield.
# Choose your game mode, map, difficulty, then
# hit DEPLOY to place your clones!
# -----------------------------------------------

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	SoundManager.play_music("menu")
	build_ui()

func build_ui():
	# ── Dark background ──
	var bg = ColorRect.new()
	bg.color = Color(0.07, 0.09, 0.13)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# ── Secret Codes button (bottom centre) ──
	var codes_btn = Button.new()
	codes_btn.text = "🔑  Secret Codes"
	codes_btn.add_theme_font_size_override("font_size", 13)
	codes_btn.set_anchor(SIDE_LEFT,  0.5); codes_btn.set_anchor(SIDE_RIGHT,  0.5)
	codes_btn.set_anchor(SIDE_TOP,   1);   codes_btn.set_anchor(SIDE_BOTTOM, 1)
	codes_btn.offset_left   = -90
	codes_btn.offset_right  = 90
	codes_btn.offset_top    = -26
	codes_btn.offset_bottom = -4
	codes_btn.pressed.connect(func():
		SoundManager.play("click")
		_open_codes_panel()
	)
	add_child(codes_btn)

	# ── Title ──
	var title = Label.new()
	title.text = "⚔  THE INFINITE FIGHT  ⚔"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.15))
	title.set_anchor(SIDE_LEFT,  0); title.set_anchor(SIDE_RIGHT,  1)
	title.set_anchor(SIDE_TOP,   0); title.set_anchor(SIDE_BOTTOM, 0)
	title.offset_top    = 18
	title.offset_bottom = 62
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	# ── Three columns ──
	_build_left_column()
	_build_middle_column()
	_build_right_column()

	# ── Bottom bar ──
	_build_bottom_bar()

# ==============================================
# LEFT COLUMN — Stats & Achievements
# ==============================================
func _build_left_column():
	var panel = Panel.new()
	panel.set_anchor(SIDE_LEFT,   0); panel.set_anchor(SIDE_RIGHT,  0)
	panel.set_anchor(SIDE_TOP,    0); panel.set_anchor(SIDE_BOTTOM, 1)
	panel.offset_left   = 10
	panel.offset_right  = 240
	panel.offset_top    = 72
	panel.offset_bottom = -75
	add_child(panel)

	# Heading
	var h = Label.new()
	h.text = "YOUR STATS"
	h.add_theme_font_size_override("font_size", 15)
	h.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
	h.position = Vector2(0, 10)
	h.size     = Vector2(230, 24)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(h)

	# Commander name
	var pname = GameManager.player_name if GameManager else "Commander"
	var squad = GameManager.squad_name  if GameManager and GameManager.squad_name != "" else "No squad name"
	var wins  = GameManager.total_wins  if GameManager else 0

	var stats_lines = [
		"👤 " + pname,
		"🪖 " + squad,
		"🏆 " + str(wins) + " wins",
		"",
		"ACHIEVEMENTS",
	]
	var y = 40
	for line in stats_lines:
		var lbl = Label.new()
		lbl.text = line
		lbl.add_theme_font_size_override("font_size", 13 if line != "ACHIEVEMENTS" else 12)
		lbl.add_theme_color_override("font_color",
			Color(1.0, 0.88, 0.2) if line == "ACHIEVEMENTS" else Color(0.88, 0.88, 0.88))
		lbl.position = Vector2(12, y)
		lbl.size     = Vector2(210, 22)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(lbl)
		y += 22

	# List earned achievements
	var earned = Achievements.earned if Achievements else {}
	var any_shown = false
	for key in Achievements.ALL:
		if earned.get(key, false):
			var info = Achievements.ALL[key]
			var albl = Label.new()
			albl.text = info["icon"] + " " + info["name"]
			albl.add_theme_font_size_override("font_size", 11)
			albl.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
			albl.position = Vector2(12, y)
			albl.size     = Vector2(210, 18)
			albl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			panel.add_child(albl)
			y += 18
			any_shown = true

	if not any_shown:
		var none_lbl = Label.new()
		none_lbl.text = "None yet — keep fighting!"
		none_lbl.add_theme_font_size_override("font_size", 11)
		none_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		none_lbl.position = Vector2(12, y)
		none_lbl.size     = Vector2(210, 18)
		none_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(none_lbl)

# ==============================================
# MIDDLE COLUMN — Game Mode + Difficulty
# ==============================================
func _build_middle_column():
	var panel = Panel.new()
	panel.set_anchor(SIDE_LEFT,   0); panel.set_anchor(SIDE_RIGHT,  1)
	panel.set_anchor(SIDE_TOP,    0); panel.set_anchor(SIDE_BOTTOM, 1)
	panel.offset_left   = 250
	panel.offset_right  = -250
	panel.offset_top    = 72
	panel.offset_bottom = -75
	add_child(panel)

	# ── GAME MODE heading ──
	var gm_h = Label.new()
	gm_h.text = "GAME MODE"
	gm_h.add_theme_font_size_override("font_size", 15)
	gm_h.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
	gm_h.set_anchor(SIDE_LEFT,  0); gm_h.set_anchor(SIDE_RIGHT, 1)
	gm_h.offset_top    = 10
	gm_h.offset_bottom = 34
	gm_h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gm_h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(gm_h)

	# Two big mode buttons
	var modes = [
		{
			"key":   "normal",
			"title": "⚔  NORMAL BATTLE",
			"desc":  "Defeat all the enemies\nto win the round!",
			"wave":  false,
		},
		{
			"key":   "waves",
			"title": "🌊  WAVE MODE",
			"desc":  "Survive endless waves.\nHow long can you last?",
			"wave":  true,
		},
	]

	var mode_btns: Array = []
	for i in modes.size():
		var m = modes[i]
		var btn = Button.new()
		btn.text = m["title"] + "\n" + m["desc"]
		btn.add_theme_font_size_override("font_size", 15)
		btn.set_anchor(SIDE_LEFT,   0); btn.set_anchor(SIDE_RIGHT,  1)
		btn.offset_left   = 15
		btn.offset_right  = -15
		btn.offset_top    = 44 + i * 100
		btn.offset_bottom = 134 + i * 100
		# Highlight selected mode
		var is_wave = GameManager.wave_mode if GameManager else false
		var selected = (m["wave"] == is_wave)
		btn.modulate = Color(0.3, 1.0, 0.5) if selected else Color(1, 1, 1)
		var wave_val = m["wave"]
		btn.pressed.connect(func():
			if GameManager:
				GameManager.wave_mode = wave_val
			SoundManager.play("click")
			# Update highlights
			for b in mode_btns:
				b.modulate = Color(1, 1, 1)
			btn.modulate = Color(0.3, 1.0, 0.5)
		)
		panel.add_child(btn)
		mode_btns.append(btn)


	# ── DIFFICULTY heading ──
	var diff_h = Label.new()
	diff_h.text = "DIFFICULTY"
	diff_h.add_theme_font_size_override("font_size", 15)
	diff_h.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
	diff_h.set_anchor(SIDE_LEFT,  0); diff_h.set_anchor(SIDE_RIGHT, 1)
	diff_h.offset_top    = 298
	diff_h.offset_bottom = 322
	diff_h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	diff_h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(diff_h)

	var difficulties = [
		{"key": "easy",         "label": "😊 Easy",         "colour": Color(0.3, 1.0, 0.4)},
		{"key": "medium",       "label": "😐 Medium",       "colour": Color(1.0, 0.85, 0.2)},
		{"key": "hard",         "label": "😤 Hard",         "colour": Color(1.0, 0.5, 0.1)},
		{"key": "bloodthirsty", "label": "💀 Bloodthirsty", "colour": Color(1.0, 0.15, 0.15)},
	]

	var diff_btns: Array = []
	var current_diff = GameManager.difficulty if GameManager else "easy"
	var btn_w = 130
	var btn_gap = 8
	var total_w = difficulties.size() * btn_w + (difficulties.size() - 1) * btn_gap
	# Centre them
	var start_x = 0  # We use anchors so let's do equal offsets

	for i in difficulties.size():
		var d = difficulties[i]
		var db = Button.new()
		db.text = d["label"]
		db.add_theme_font_size_override("font_size", 13)
		db.set_anchor(SIDE_LEFT,  0); db.set_anchor(SIDE_RIGHT, 0)
		db.offset_left   = 15 + i * (btn_w + btn_gap)
		db.offset_right  = 15 + i * (btn_w + btn_gap) + btn_w
		db.offset_top    = 328
		db.offset_bottom = 364
		var is_sel = (d["key"] == current_diff)
		db.modulate = d["colour"] if is_sel else Color(0.6, 0.6, 0.6)
		var diff_key = d["key"]
		var diff_col = d["colour"]
		db.pressed.connect(func():
			if GameManager:
				GameManager.difficulty = diff_key
			SoundManager.play("click")
			for b in diff_btns:
				b.modulate = Color(0.6, 0.6, 0.6)
			db.modulate = diff_col
		)
		panel.add_child(db)
		diff_btns.append(db)

# ==============================================
# RIGHT COLUMN — Map Picker
# ==============================================
func _build_right_column():
	var panel = Panel.new()
	panel.set_anchor(SIDE_LEFT,   1); panel.set_anchor(SIDE_RIGHT,  1)
	panel.set_anchor(SIDE_TOP,    0); panel.set_anchor(SIDE_BOTTOM, 1)
	panel.offset_left   = -240
	panel.offset_right  = -10
	panel.offset_top    = 72
	panel.offset_bottom = -75
	add_child(panel)

	var h = Label.new()
	h.text = "CHOOSE MAP"
	h.add_theme_font_size_override("font_size", 15)
	h.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
	h.set_anchor(SIDE_LEFT,  0); h.set_anchor(SIDE_RIGHT, 1)
	h.offset_top    = 10
	h.offset_bottom = 34
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(h)

	var maps = [
		{"key": "grassland", "icon": "🌿", "name": "Grassland",  "desc": "Open fields,\nclear skies"},
		{"key": "jungle",    "icon": "🌴", "name": "Jungle",     "desc": "Dense trees,\nheavy rain"},
		{"key": "city",      "icon": "🏙", "name": "City",       "desc": "Urban streets,\nconcrete cover"},
		{"key": "snow",      "icon": "❄️", "name": "Snow",       "desc": "Blizzard winds,\nslippery ground"},
		{"key": "night",     "icon": "🌙", "name": "Night Ops",  "desc": "Pitch dark,\ncampfire light"},
	]

	var map_btns: Dictionary = {}
	var current_map = GameManager.selected_map if GameManager else "grassland"

	for i in maps.size():
		var m = maps[i]
		var btn = Button.new()
		btn.text = m["icon"] + "  " + m["name"] + "\n" + m["desc"]
		btn.add_theme_font_size_override("font_size", 14)
		btn.set_anchor(SIDE_LEFT,   0); btn.set_anchor(SIDE_RIGHT,  1)
		btn.offset_left   = 10
		btn.offset_right  = -10
		btn.offset_top    = 44 + i * 72
		btn.offset_bottom = 110 + i * 72
		var selected = (m["key"] == current_map)
		btn.modulate = Color(0.3, 1.0, 0.5) if selected else Color(1, 1, 1)
		map_btns[m["key"]] = btn
		var map_key = m["key"]
		btn.pressed.connect(func():
			if GameManager:
				GameManager.selected_map = map_key
			SoundManager.play("click")
			for k in map_btns:
				map_btns[k].modulate = Color(1, 1, 1)
			btn.modulate = Color(0.3, 1.0, 0.5)
		)
		panel.add_child(btn)

# ==============================================
# BOTTOM BAR — Shop, Customise, Deploy
# ==============================================
func _build_bottom_bar():
	# Shop button
	var shop_btn = Button.new()
	shop_btn.text = "🛒  Shop"
	shop_btn.add_theme_font_size_override("font_size", 18)
	shop_btn.set_anchor(SIDE_LEFT,   0); shop_btn.set_anchor(SIDE_RIGHT,  0)
	shop_btn.set_anchor(SIDE_TOP,    1); shop_btn.set_anchor(SIDE_BOTTOM, 1)
	shop_btn.offset_left   = 10
	shop_btn.offset_right  = 200
	shop_btn.offset_top    = -65
	shop_btn.offset_bottom = -10
	shop_btn.pressed.connect(func():
		SoundManager.play("click")
		get_tree().change_scene_to_file("res://scenes/UpgradeShop.tscn")
	)
	add_child(shop_btn)

	# Customise button
	var custom_btn = Button.new()
	custom_btn.text = "🎨  Customise"
	custom_btn.add_theme_font_size_override("font_size", 18)
	custom_btn.set_anchor(SIDE_LEFT,   0); custom_btn.set_anchor(SIDE_RIGHT,  0)
	custom_btn.set_anchor(SIDE_TOP,    1); custom_btn.set_anchor(SIDE_BOTTOM, 1)
	custom_btn.offset_left   = 210
	custom_btn.offset_right  = 420
	custom_btn.offset_top    = -65
	custom_btn.offset_bottom = -10
	custom_btn.pressed.connect(func():
		SoundManager.play("click")
		get_tree().change_scene_to_file("res://scenes/CloneCustomise.tscn")
	)
	add_child(custom_btn)

	# Leaderboard button
	var lb_btn = Button.new()
	lb_btn.text = "🏆  Scores"
	lb_btn.add_theme_font_size_override("font_size", 18)
	lb_btn.set_anchor(SIDE_LEFT,   0); lb_btn.set_anchor(SIDE_RIGHT,  0)
	lb_btn.set_anchor(SIDE_TOP,    1); lb_btn.set_anchor(SIDE_BOTTOM, 1)
	lb_btn.offset_left   = 430
	lb_btn.offset_right  = 620
	lb_btn.offset_top    = -65
	lb_btn.offset_bottom = -10
	lb_btn.pressed.connect(func():
		SoundManager.play("click")
		get_tree().change_scene_to_file("res://scenes/Leaderboard.tscn")
	)
	add_child(lb_btn)

	# Settings button
	var settings_btn = Button.new()
	settings_btn.text = "⚙  Settings"
	settings_btn.add_theme_font_size_override("font_size", 18)
	settings_btn.set_anchor(SIDE_LEFT,   0); settings_btn.set_anchor(SIDE_RIGHT,  0)
	settings_btn.set_anchor(SIDE_TOP,    1); settings_btn.set_anchor(SIDE_BOTTOM, 1)
	settings_btn.offset_left   = 630
	settings_btn.offset_right  = 820
	settings_btn.offset_top    = -65
	settings_btn.offset_bottom = -10
	settings_btn.pressed.connect(func():
		SoundManager.play("click")
		get_tree().change_scene_to_file("res://scenes/SettingsScreen.tscn")
	)
	add_child(settings_btn)

	# Level Editor button
	var editor_btn = Button.new()
	editor_btn.text = "🛠  Level Editor"
	editor_btn.add_theme_font_size_override("font_size", 18)
	editor_btn.set_anchor(SIDE_LEFT,   1); editor_btn.set_anchor(SIDE_RIGHT,  1)
	editor_btn.set_anchor(SIDE_TOP,    1); editor_btn.set_anchor(SIDE_BOTTOM, 1)
	editor_btn.offset_left   = -380
	editor_btn.offset_right  = -200
	editor_btn.offset_top    = -65
	editor_btn.offset_bottom = -10
	editor_btn.pressed.connect(func():
		SoundManager.play("click")
		get_tree().change_scene_to_file("res://scenes/LevelEditor.tscn")
	)
	add_child(editor_btn)

	# Big DEPLOY button on the right
	var deploy_btn = Button.new()
	deploy_btn.text = "🗺  DEPLOY  ➜"
	deploy_btn.add_theme_font_size_override("font_size", 24)
	deploy_btn.set_anchor(SIDE_LEFT,   1); deploy_btn.set_anchor(SIDE_RIGHT,  1)
	deploy_btn.set_anchor(SIDE_TOP,    1); deploy_btn.set_anchor(SIDE_BOTTOM, 1)
	deploy_btn.offset_left   = -195
	deploy_btn.offset_right  = -10
	deploy_btn.offset_top    = -65
	deploy_btn.offset_bottom = -10
	deploy_btn.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	deploy_btn.pressed.connect(func():
		SoundManager.play("click")
		get_tree().change_scene_to_file("res://scenes/DeployScreen.tscn")
	)
	add_child(deploy_btn)

# -----------------------------------------------
# SECRET CODES PANEL
# -----------------------------------------------
func _open_codes_panel():
	var canvas = CanvasLayer.new()
	canvas.layer = 25
	get_tree().root.add_child(canvas)

	# Dark overlay behind the panel
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.72)
	overlay.set_anchor(SIDE_LEFT, 0); overlay.set_anchor(SIDE_RIGHT,  1)
	overlay.set_anchor(SIDE_TOP,  0); overlay.set_anchor(SIDE_BOTTOM, 1)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(overlay)

	# Panel box
	var panel = PanelContainer.new()
	panel.set_anchor(SIDE_LEFT,  0.5); panel.set_anchor(SIDE_RIGHT,  0.5)
	panel.set_anchor(SIDE_TOP,   0.5); panel.set_anchor(SIDE_BOTTOM, 0.5)
	panel.offset_left   = -260; panel.offset_right  = 260
	panel.offset_top    = -140; panel.offset_bottom = 140
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.12, 0.97)
	style.border_color = Color(0.8, 0.2, 0.1)
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", style)
	canvas.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	# Title
	var title_lbl = Label.new()
	title_lbl.text = "🔑  SECRET CODES"
	title_lbl.add_theme_font_size_override("font_size", 26)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_lbl)

	# Separator
	var sep = HSeparator.new()
	vbox.add_child(sep)

	# "Type a code:" label
	var type_lbl = Label.new()
	type_lbl.text = "Type a code below and press ENTER:"
	type_lbl.add_theme_font_size_override("font_size", 14)
	type_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(type_lbl)

	# Text input row
	var input_row = HBoxContainer.new()
	input_row.add_theme_constant_override("separation", 8)
	input_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(input_row)

	var line_edit = LineEdit.new()
	line_edit.placeholder_text = "Enter code here..."
	line_edit.custom_minimum_size = Vector2(220, 36)
	line_edit.add_theme_font_size_override("font_size", 16)
	line_edit.secret = true
	input_row.add_child(line_edit)
	line_edit.grab_focus()

	var submit_btn = Button.new()
	submit_btn.text = "✅ GO!"
	submit_btn.add_theme_font_size_override("font_size", 15)
	input_row.add_child(submit_btn)

	var _submit = func():
		var code = line_edit.text.strip_edges().to_upper()
		if code != "":
			SecretCodes._typed = code
			SecretCodes._check_codes()
			line_edit.text = ""
			line_edit.placeholder_text = "Code entered! ✅"

	submit_btn.pressed.connect(_submit)
	line_edit.text_submitted.connect(func(_t): _submit.call())

	# Close button
	var close_btn = Button.new()
	close_btn.text = "✖  Close"
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.pressed.connect(func():
		SoundManager.play("click")
		canvas.queue_free()
	)
	vbox.add_child(close_btn)

	# Also close on overlay click
	overlay.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			canvas.queue_free()
	)
