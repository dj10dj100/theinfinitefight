extends Control

# -----------------------------------------------
# DEPLOY SCREEN
# Before every battle, you choose which clones to
# send in and where to put them on the field.
# Click a clone type on the left, then click your
# half of the field to place them. Max 10 clones!
# Press FIGHT when you're ready!
# -----------------------------------------------

const MAX_CLONES = 10

# 3D positions for YOUR half of the battlefield
const FIELD_X_MIN = -17.0
const FIELD_X_MAX =  17.0
const FIELD_Z_MIN = -12.0
const FIELD_Z_MAX =  -1.0

var selected_weapon: String = ""
var placed_clones: Array = []       # [{weapon, position}]
var weapon_buttons: Dictionary = {} # weapon name → Button node

# Key UI nodes (created in build_ui)
var count_label: Label
var battlefield_area: Control
var buttons_container: VBoxContainer

# -----------------------------------------------
# BUILD THE WHOLE SCREEN
# -----------------------------------------------
func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	build_ui()
	SoundManager.play_music("menu")

func build_ui():
	# Dark background
	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.10, 0.14)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Player info strip (top right)
	var player_info = Label.new()
	var pname = GameManager.player_name if GameManager else "Commander"
	var pwins = str(GameManager.total_wins) if GameManager else "0"
	player_info.text = "Commander: " + pname + "   |   Wins: " + pwins
	player_info.add_theme_font_size_override("font_size", 13)
	player_info.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	player_info.set_anchor(SIDE_LEFT, 0.5);  player_info.set_anchor(SIDE_RIGHT,  1)
	player_info.set_anchor(SIDE_TOP, 0);     player_info.set_anchor(SIDE_BOTTOM, 0)
	player_info.offset_top = 14;             player_info.offset_right = -15
	player_info.offset_bottom = 38
	player_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	player_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(player_info)

	# Title at the top
	var title = Label.new()
	title.text = "⚔  DEPLOY YOUR ARMY  ⚔"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	title.set_anchor(SIDE_LEFT,   0); title.set_anchor(SIDE_RIGHT,  1)
	title.set_anchor(SIDE_TOP,    0); title.set_anchor(SIDE_BOTTOM, 0)
	title.offset_bottom = 50
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	build_left_panel()
	build_field_panel()
	build_fight_button()

# -----------------------------------------------
# LEFT PANEL — clone type selection
# -----------------------------------------------
func build_left_panel():
	var panel = Panel.new()
	panel.set_anchor(SIDE_LEFT,   0); panel.set_anchor(SIDE_RIGHT,  0)
	panel.set_anchor(SIDE_TOP,    0); panel.set_anchor(SIDE_BOTTOM, 1)
	panel.offset_left = 10; panel.offset_right  = 230
	panel.offset_top  = 55; panel.offset_bottom = -10
	add_child(panel)

	# "YOUR CLONES" heading
	var heading = Label.new()
	heading.text = "YOUR CLONES"
	heading.add_theme_font_size_override("font_size", 16)
	heading.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
	heading.position = Vector2(0, 8)
	heading.size = Vector2(220, 28)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(heading)

	# Small hint text
	var hint = Label.new()
	hint.text = "1. Click a clone below\n2. Click the green field\n    to place them"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	hint.position = Vector2(10, 38)
	hint.size = Vector2(200, 60)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(hint)

	# Clone buttons (one per unlocked weapon)
	buttons_container = VBoxContainer.new()
	buttons_container.position = Vector2(10, 105)
	buttons_container.size = Vector2(200, 380)
	buttons_container.add_theme_constant_override("separation", 8)
	panel.add_child(buttons_container)
	build_weapon_buttons()

	# "X / 10 placed" counter
	count_label = Label.new()
	count_label.text = "0 / 10 clones placed"
	count_label.add_theme_font_size_override("font_size", 13)
	count_label.add_theme_color_override("font_color", Color(1, 1, 1))
	count_label.set_anchor(SIDE_TOP, 1); count_label.set_anchor(SIDE_BOTTOM, 1)
	count_label.offset_top = -75; count_label.offset_bottom = -48
	count_label.offset_left = 0;  count_label.offset_right  = 220
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(count_label)

	# Clear all button
	var clear_btn = Button.new()
	clear_btn.text = "🗑  Clear All"
	clear_btn.set_anchor(SIDE_TOP, 1); clear_btn.set_anchor(SIDE_BOTTOM, 1)
	clear_btn.offset_top = -42; clear_btn.offset_bottom = -8
	clear_btn.offset_left = 15; clear_btn.offset_right  = 205
	clear_btn.pressed.connect(clear_all_clones)
	panel.add_child(clear_btn)

func build_weapon_buttons():
	for child in buttons_container.get_children():
		child.queue_free()
	weapon_buttons.clear()

	var unlocked = GameManager.unlocked_weapons if GameManager else ["pistol"]
	var labels = {
		"pistol":        "🔫  Pistol Clone",
		"revolver":      "🔫  Revolver Clone",
		"shotgun":       "💥  Shotgun Clone",
		"assault_rifle": "⚡  Assault Rifle",
		"machine_gun":   "🔥  Machine Gun",
		"sniper":        "🎯  Sniper Clone"
	}
	for weapon in unlocked:
		var btn = Button.new()
		btn.text = labels.get(weapon, weapon.capitalize())
		btn.custom_minimum_size = Vector2(190, 42)
		btn.pressed.connect(select_weapon.bind(weapon, btn))
		buttons_container.add_child(btn)
		weapon_buttons[weapon] = btn

# -----------------------------------------------
# FIELD PANEL — the clickable battlefield preview
# -----------------------------------------------
func build_field_panel():
	var panel = Panel.new()
	panel.set_anchor(SIDE_LEFT,   0); panel.set_anchor(SIDE_RIGHT,  1)
	panel.set_anchor(SIDE_TOP,    0); panel.set_anchor(SIDE_BOTTOM, 1)
	panel.offset_left = 240; panel.offset_right  = -10
	panel.offset_top  = 55;  panel.offset_bottom = -60
	add_child(panel)

	# Enemy zone (top half — red tint, not clickable)
	var enemy_bg = ColorRect.new()
	enemy_bg.color = Color(0.5, 0.1, 0.1, 0.35)
	enemy_bg.set_anchor(SIDE_LEFT,   0); enemy_bg.set_anchor(SIDE_RIGHT,  1)
	enemy_bg.set_anchor(SIDE_TOP,    0); enemy_bg.set_anchor(SIDE_BOTTOM, 0.5)
	enemy_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(enemy_bg)

	var enemy_lbl = Label.new()
	enemy_lbl.text = "ENEMY ZONE  🔴"
	enemy_lbl.add_theme_font_size_override("font_size", 20)
	enemy_lbl.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 0.55))
	enemy_lbl.set_anchor(SIDE_LEFT,   0); enemy_lbl.set_anchor(SIDE_RIGHT,  1)
	enemy_lbl.set_anchor(SIDE_TOP,    0); enemy_lbl.set_anchor(SIDE_BOTTOM, 0.5)
	enemy_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	enemy_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(enemy_lbl)

	# Middle divider line
	var divider = ColorRect.new()
	divider.color = Color(1.0, 0.9, 0.2, 0.7)
	divider.set_anchor(SIDE_LEFT,   0); divider.set_anchor(SIDE_RIGHT,  1)
	divider.set_anchor(SIDE_TOP, 0.5); divider.set_anchor(SIDE_BOTTOM, 0.5)
	divider.offset_bottom = 2
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(divider)

	# Clickable YOUR zone (bottom half)
	battlefield_area = Control.new()
	battlefield_area.set_anchor(SIDE_LEFT,   0); battlefield_area.set_anchor(SIDE_RIGHT,  1)
	battlefield_area.set_anchor(SIDE_TOP, 0.5); battlefield_area.set_anchor(SIDE_BOTTOM, 1)
	battlefield_area.offset_top = 3
	battlefield_area.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_child(battlefield_area)

	# Green background for your zone
	var your_bg = ColorRect.new()
	your_bg.color = Color(0.1, 0.28, 0.1, 0.85)
	your_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	your_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battlefield_area.add_child(your_bg)

	# Hint text inside the zone
	var your_lbl = Label.new()
	your_lbl.text = "YOUR ZONE  🟢\n(click here to place clones)"
	your_lbl.add_theme_font_size_override("font_size", 16)
	your_lbl.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5, 0.45))
	your_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	your_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	your_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	your_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battlefield_area.add_child(your_lbl)

# -----------------------------------------------
# FIGHT BUTTON
# -----------------------------------------------
func build_fight_button():
	# Friends button (bottom left)
	var friends_btn = Button.new()
	friends_btn.text = "👥  Friends"
	friends_btn.add_theme_font_size_override("font_size", 14)
	friends_btn.set_anchor(SIDE_LEFT,   0); friends_btn.set_anchor(SIDE_RIGHT,  0)
	friends_btn.set_anchor(SIDE_TOP,    1); friends_btn.set_anchor(SIDE_BOTTOM, 1)
	friends_btn.offset_left = 10;  friends_btn.offset_right  = 108
	friends_btn.offset_top  = -55; friends_btn.offset_bottom = -30
	friends_btn.pressed.connect(func():
		SoundManager.play("click")
		get_tree().change_scene_to_file("res://scenes/FriendSystem.tscn")
	)
	add_child(friends_btn)

	# Settings button
	var settings_btn = Button.new()
	settings_btn.text = "⚙  Settings"
	settings_btn.add_theme_font_size_override("font_size", 14)
	settings_btn.set_anchor(SIDE_LEFT,   0); settings_btn.set_anchor(SIDE_RIGHT,  0)
	settings_btn.set_anchor(SIDE_TOP,    1); settings_btn.set_anchor(SIDE_BOTTOM, 1)
	settings_btn.offset_left = 112; settings_btn.offset_right  = 220
	settings_btn.offset_top  = -55; settings_btn.offset_bottom = -30
	settings_btn.pressed.connect(func():
		SoundManager.play("click")
		get_tree().change_scene_to_file("res://scenes/SettingsScreen.tscn")
	)
	add_child(settings_btn)

	# Leaderboard button
	var lb_btn = Button.new()
	lb_btn.text = "🏆  Scores"
	lb_btn.add_theme_font_size_override("font_size", 14)
	lb_btn.set_anchor(SIDE_LEFT,   0); lb_btn.set_anchor(SIDE_RIGHT,  0)
	lb_btn.set_anchor(SIDE_TOP,    1); lb_btn.set_anchor(SIDE_BOTTOM, 1)
	lb_btn.offset_left = 10;  lb_btn.offset_right  = 220
	lb_btn.offset_top  = -27; lb_btn.offset_bottom = -4
	lb_btn.pressed.connect(func():
		SoundManager.play("click")
		get_tree().change_scene_to_file("res://scenes/Leaderboard.tscn")
	)
	add_child(lb_btn)

	# Map picker — choose your battlefield!
	_build_map_picker()

	# FIGHT button (bottom right)
	var btn = Button.new()
	btn.text = "⚔   FIGHT!"
	btn.add_theme_font_size_override("font_size", 22)
	btn.set_anchor(SIDE_LEFT,   0); btn.set_anchor(SIDE_RIGHT,  1)
	btn.set_anchor(SIDE_TOP,    1); btn.set_anchor(SIDE_BOTTOM, 1)
	btn.offset_left = 240; btn.offset_right  = -10
	btn.offset_top  = -55; btn.offset_bottom = -10
	btn.pressed.connect(_on_fight_pressed)
	add_child(btn)

func _build_map_picker():
	# A small row of map buttons above the fight button
	var maps = [
		{"key": "grassland", "label": "🌿"},
		{"key": "jungle",    "label": "🌴"},
		{"key": "city",      "label": "🏙"},
		{"key": "snow",      "label": "❄️"},
	]
	var map_buttons: Dictionary = {}
	var btn_w = 52
	var gap   = 6

	var heading = Label.new()
	heading.text = "MAP:"
	heading.add_theme_font_size_override("font_size", 13)
	heading.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	heading.set_anchor(SIDE_LEFT,   0); heading.set_anchor(SIDE_RIGHT,  0)
	heading.set_anchor(SIDE_TOP,    1); heading.set_anchor(SIDE_BOTTOM, 1)
	heading.offset_left = 240; heading.offset_right  = 295
	heading.offset_top  = -95; heading.offset_bottom = -65
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(heading)

	for i in range(maps.size()):
		var m = maps[i]
		var mb = Button.new()
		mb.text = m["label"]
		mb.add_theme_font_size_override("font_size", 18)
		mb.custom_minimum_size = Vector2(btn_w, 28)
		mb.set_anchor(SIDE_LEFT,   0); mb.set_anchor(SIDE_RIGHT,  0)
		mb.set_anchor(SIDE_TOP,    1); mb.set_anchor(SIDE_BOTTOM, 1)
		mb.offset_left   = 295 + i * (btn_w + gap)
		mb.offset_right  = 295 + i * (btn_w + gap) + btn_w
		mb.offset_top    = -95
		mb.offset_bottom = -65
		map_buttons[m["key"]] = mb

		mb.pressed.connect(func():
			SoundManager.play("click")
			GameManager.selected_map = m["key"]
			# Highlight selected map
			for k in map_buttons:
				map_buttons[k].modulate = Color(1, 1, 1)
			mb.modulate = Color(0.3, 1.0, 0.45)
		)
		add_child(mb)

	# Highlight the currently chosen map
	var current = GameManager.selected_map if GameManager else "grassland"
	if map_buttons.has(current):
		map_buttons[current].modulate = Color(0.3, 1.0, 0.45)

# -----------------------------------------------
# SELECTING A WEAPON TYPE
# -----------------------------------------------
func select_weapon(weapon: String, btn: Button):
	SoundManager.play("click")
	selected_weapon = weapon
	# Highlight selected, dim the rest
	for w in weapon_buttons:
		weapon_buttons[w].modulate = Color(1, 1, 1)
	btn.modulate = Color(0.3, 1.0, 0.45)
	print("Selected: ", weapon, " — now click your green zone to place a clone!")

# -----------------------------------------------
# CLICKING ON THE FIELD TO PLACE A CLONE
# -----------------------------------------------
func _input(event):
	if battlefield_area == null:
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return

	# Is the mouse over the battlefield area?
	var local = battlefield_area.get_local_mouse_position()
	var sz    = battlefield_area.size
	if local.x < 0 or local.x > sz.x or local.y < 0 or local.y > sz.y:
		return

	if selected_weapon == "":
		print("Pick a clone type from the left panel first!")
		return
	if placed_clones.size() >= MAX_CLONES:
		print("You've placed all 10 clones!")
		return

	place_clone(local, sz)

func place_clone(local_pos: Vector2, area_size: Vector2):
	# Map 2D click position → 3D battlefield coordinate
	var x   = lerp(FIELD_X_MIN, FIELD_X_MAX, local_pos.x / area_size.x)
	var z   = lerp(FIELD_Z_MIN, FIELD_Z_MAX, local_pos.y / area_size.y)
	var pos = Vector3(x, 0.1, z)

	placed_clones.append({"weapon": selected_weapon, "position": pos})

	# Draw a green dot at the click position
	var dot = ColorRect.new()
	dot.color = Color(0.25, 0.95, 0.35)
	dot.size  = Vector2(20, 20)
	dot.position = local_pos - Vector2(10, 10)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battlefield_area.add_child(dot)

	# Show a letter so you know which weapon type it is
	var lbl = Label.new()
	lbl.text = selected_weapon[0].to_upper()
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0, 0, 0))
	lbl.position = local_pos - Vector2(5, 9)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battlefield_area.add_child(lbl)

	SoundManager.play("place_clone")
	update_count()
	print("Placed ", selected_weapon, " at ", pos)

# -----------------------------------------------
# CLEAR ALL PLACED CLONES
# -----------------------------------------------
func clear_all_clones():
	placed_clones.clear()
	# Remove every child beyond the first two (bg + hint label)
	var to_remove = []
	for i in range(battlefield_area.get_child_count()):
		if i >= 2:
			to_remove.append(battlefield_area.get_child(i))
	for node in to_remove:
		node.queue_free()
	update_count()
	print("Cleared all clones.")

func update_count():
	count_label.text = str(placed_clones.size()) + " / " + str(MAX_CLONES) + " clones placed"

# -----------------------------------------------
# FIGHT!
# -----------------------------------------------
func _on_fight_pressed():
	if placed_clones.is_empty():
		print("Place at least one clone before fighting!")
		return

	# Store deploy positions so the Battlefield can read them
	GameManager.deploy_data = placed_clones
	print("Heading into battle with ", placed_clones.size(), " clones!")
	get_tree().change_scene_to_file("res://scenes/Battlefield.tscn")
