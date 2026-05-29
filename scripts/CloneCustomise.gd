extends Control

# -----------------------------------------------
# CLONE CUSTOMISATION
# Before battle, personalise your army!
#   - Pick your clone colour
#   - Give your squad a nickname
#   - Choose a special ability
# Your choices are saved to GameManager.
# -----------------------------------------------

# Colour options — each has a name and a Color
const COLOURS = [
	{"name": "🟢 Olive",    "colour": Color(0.30, 0.38, 0.16)},
	{"name": "🔵 Blue",     "colour": Color(0.15, 0.30, 0.65)},
	{"name": "🔴 Red",      "colour": Color(0.65, 0.10, 0.10)},
	{"name": "🟣 Purple",   "colour": Color(0.40, 0.10, 0.55)},
	{"name": "🟠 Orange",   "colour": Color(0.75, 0.35, 0.05)},
	{"name": "⚪ White",    "colour": Color(0.88, 0.88, 0.88)},
	{"name": "🩷 Pink",     "colour": Color(0.85, 0.35, 0.55)},
	{"name": "🟡 Yellow",   "colour": Color(0.80, 0.75, 0.05)},
]

# Special abilities — each clone in your squad gets this!
const ABILITIES = [
	{
		"key":  "none",
		"name": "⚔️  None",
		"desc": "Standard clone. No special power."
	},
	{
		"key":  "berserker",
		"name": "😡  Berserker",
		"desc": "Gets faster as health drops!\nBelow 50% HP = double speed."
	},
	{
		"key":  "medic",
		"name": "💊  Medic",
		"desc": "Slowly heals 2 HP per second\nduring battle."
	},
	{
		"key":  "tank",
		"name": "🛡  Tank",
		"desc": "Starts with a free shield\nthat blocks 2 hits."
	},
	{
		"key":  "sniper_eye",
		"name": "🎯  Eagle Eye",
		"desc": "All weapons get +30%\nshooting range."
	},
	{
		"key":  "field_medic",
		"name": "🏥  Field Medic",
		"desc": "Heals ALL nearby clones\n4 HP per second in a radius."
	},
	{
		"key":  "demolitions",
		"name": "💣  Demolitions",
		"desc": "Grenades recharge twice\nas fast. Double grenade power!"
	},
	{
		"key":  "engineer",
		"name": "🔧  Engineer",
		"desc": "Shoots twice as fast!\nBattlefield repairs over time."
	},
]

var colour_buttons: Array   = []
var ability_buttons: Array  = []
var preview_mesh: ColorRect = null
var name_input: LineEdit    = null

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	build_ui()

func build_ui():
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.07, 0.08, 0.12)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Header
	var title = Label.new()
	title.text = "🎨  CUSTOMISE YOUR CLONES"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	title.set_anchor(SIDE_LEFT, 0);  title.set_anchor(SIDE_RIGHT, 1)
	title.set_anchor(SIDE_TOP, 0);   title.set_anchor(SIDE_BOTTOM, 0)
	title.offset_top = 14;           title.offset_bottom = 58
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	_build_colour_section()
	_build_name_section()
	_build_ability_section()
	_build_preview_section()
	_build_bottom_buttons()

# -----------------------------------------------
# COLOUR PICKER
# -----------------------------------------------
func _build_colour_section():
	var lbl = Label.new()
	lbl.text = "Squad Colour:"
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	lbl.set_anchor(SIDE_LEFT, 0.03);  lbl.set_anchor(SIDE_RIGHT, 0.5)
	lbl.set_anchor(SIDE_TOP, 0);      lbl.set_anchor(SIDE_BOTTOM, 0)
	lbl.offset_top = 68;              lbl.offset_bottom = 95
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)

	var btn_size = 64
	var gap      = 10
	for i in range(COLOURS.size()):
		var c    = COLOURS[i]
		var btn  = Button.new()
		btn.text = c["name"]
		btn.add_theme_font_size_override("font_size", 11)
		btn.custom_minimum_size = Vector2(btn_size, btn_size)
		btn.set_anchor(SIDE_LEFT, 0.03); btn.set_anchor(SIDE_RIGHT, 0.03)
		btn.set_anchor(SIDE_TOP, 0);     btn.set_anchor(SIDE_BOTTOM, 0)
		btn.offset_left   = i * (btn_size + gap)
		btn.offset_right  = i * (btn_size + gap) + btn_size
		btn.offset_top    = 100
		btn.offset_bottom = 100 + btn_size

		# Tint the button background to show the colour
		btn.self_modulate = c["colour"].lightened(0.2)

		btn.pressed.connect(_on_colour_picked.bind(i))
		colour_buttons.append(btn)
		add_child(btn)

	_highlight_colour(GameManager.clone_colour_index if GameManager else 0)

# -----------------------------------------------
# SQUAD NAME
# -----------------------------------------------
func _build_name_section():
	var lbl = Label.new()
	lbl.text = "Squad Name:"
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	lbl.set_anchor(SIDE_LEFT, 0.03);  lbl.set_anchor(SIDE_RIGHT, 0.5)
	lbl.set_anchor(SIDE_TOP, 0);      lbl.set_anchor(SIDE_BOTTOM, 0)
	lbl.offset_top = 178;             lbl.offset_bottom = 204
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)

	name_input = LineEdit.new()
	name_input.placeholder_text = "e.g. Delta Squad"
	name_input.max_length = 16
	name_input.text = GameManager.squad_name if GameManager else ""
	name_input.add_theme_font_size_override("font_size", 17)
	name_input.set_anchor(SIDE_LEFT, 0.03);  name_input.set_anchor(SIDE_RIGHT, 0.55)
	name_input.set_anchor(SIDE_TOP, 0);      name_input.set_anchor(SIDE_BOTTOM, 0)
	name_input.offset_top    = 210
	name_input.offset_bottom = 246
	add_child(name_input)

# -----------------------------------------------
# ABILITY PICKER
# -----------------------------------------------
func _build_ability_section():
	var lbl = Label.new()
	lbl.text = "Special Ability:"
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	lbl.set_anchor(SIDE_LEFT, 0.03);  lbl.set_anchor(SIDE_RIGHT, 0.6)
	lbl.set_anchor(SIDE_TOP, 0);      lbl.set_anchor(SIDE_BOTTOM, 0)
	lbl.offset_top = 258;             lbl.offset_bottom = 284
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)

	var card_w = 148
	var card_h = 88
	var gap    = 10
	for i in range(ABILITIES.size()):
		var ab  = ABILITIES[i]
		var btn = Button.new()
		btn.text = ab["name"] + "\n\n" + ab["desc"]
		btn.add_theme_font_size_override("font_size", 12)
		btn.custom_minimum_size = Vector2(card_w, card_h)
		btn.set_anchor(SIDE_LEFT, 0.03); btn.set_anchor(SIDE_RIGHT, 0.03)
		btn.set_anchor(SIDE_TOP, 0);     btn.set_anchor(SIDE_BOTTOM, 0)
		btn.offset_left   = i * (card_w + gap)
		btn.offset_right  = i * (card_w + gap) + card_w
		btn.offset_top    = 290
		btn.offset_bottom = 290 + card_h
		btn.pressed.connect(_on_ability_picked.bind(i))
		ability_buttons.append(btn)
		add_child(btn)

	_highlight_ability(GameManager.clone_ability_index if GameManager else 0)

# -----------------------------------------------
# COLOUR PREVIEW — shows a coloured square
# -----------------------------------------------
func _build_preview_section():
	var lbl = Label.new()
	lbl.text = "Preview:"
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	lbl.set_anchor(SIDE_LEFT, 0.65);  lbl.set_anchor(SIDE_RIGHT, 1)
	lbl.set_anchor(SIDE_TOP, 0);      lbl.set_anchor(SIDE_BOTTOM, 0)
	lbl.offset_top = 68;              lbl.offset_bottom = 95
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)

	# A big coloured square showing the chosen colour
	preview_mesh = ColorRect.new()
	var idx = GameManager.clone_colour_index if GameManager else 0
	preview_mesh.color = COLOURS[idx]["colour"]
	preview_mesh.set_anchor(SIDE_LEFT, 0.68);  preview_mesh.set_anchor(SIDE_RIGHT, 0.90)
	preview_mesh.set_anchor(SIDE_TOP, 0);      preview_mesh.set_anchor(SIDE_BOTTOM, 0)
	preview_mesh.offset_top    = 105
	preview_mesh.offset_bottom = 270
	preview_mesh.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	add_child(preview_mesh)

	# Squad name shown inside the preview
	var name_lbl = Label.new()
	name_lbl.name = "PreviewName"
	name_lbl.text = (GameManager.squad_name if GameManager and GameManager.squad_name != "" else "Your Squad")
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	name_lbl.set_anchor(SIDE_LEFT, 0.68);  name_lbl.set_anchor(SIDE_RIGHT, 0.90)
	name_lbl.set_anchor(SIDE_TOP, 0);      name_lbl.set_anchor(SIDE_BOTTOM, 0)
	name_lbl.offset_top    = 278
	name_lbl.offset_bottom = 305
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	add_child(name_lbl)

# -----------------------------------------------
# BOTTOM BUTTONS
# -----------------------------------------------
func _build_bottom_buttons():
	var save_btn = Button.new()
	save_btn.text = "✅  Save & Go Back"
	save_btn.add_theme_font_size_override("font_size", 20)
	save_btn.set_anchor(SIDE_LEFT, 0.3);    save_btn.set_anchor(SIDE_RIGHT, 0.7)
	save_btn.set_anchor(SIDE_BOTTOM, 1);    save_btn.set_anchor(SIDE_TOP, 1)
	save_btn.offset_top    = -55
	save_btn.offset_bottom = -10
	save_btn.pressed.connect(_on_save)
	add_child(save_btn)

	var back_btn = Button.new()
	back_btn.text = "← Back without saving"
	back_btn.add_theme_font_size_override("font_size", 14)
	back_btn.set_anchor(SIDE_LEFT, 0.35);   back_btn.set_anchor(SIDE_RIGHT, 0.65)
	back_btn.set_anchor(SIDE_BOTTOM, 1);    back_btn.set_anchor(SIDE_TOP, 1)
	back_btn.offset_top    = -75
	back_btn.offset_bottom = -58
	back_btn.pressed.connect(func():
		SoundManager.play("click")
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	add_child(back_btn)

# -----------------------------------------------
# BUTTON HANDLERS
# -----------------------------------------------
func _on_colour_picked(index: int):
	SoundManager.play("click")
	_highlight_colour(index)
	if GameManager:
		GameManager.clone_colour_index = index
	# Update preview
	if preview_mesh:
		preview_mesh.color = COLOURS[index]["colour"]

func _on_ability_picked(index: int):
	SoundManager.play("click")
	_highlight_ability(index)
	if GameManager:
		GameManager.clone_ability_index = index

func _highlight_colour(index: int):
	for i in range(colour_buttons.size()):
		colour_buttons[i].modulate = Color(0.4, 1.0, 0.5) if i == index else Color(1, 1, 1)

func _highlight_ability(index: int):
	for i in range(ability_buttons.size()):
		ability_buttons[i].modulate = Color(0.4, 1.0, 0.5) if i == index else Color(1, 1, 1)

func _on_save():
	SoundManager.play("click")
	if GameManager:
		GameManager.squad_name = name_input.text.strip_edges()
		GameManager.save_player_data()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
