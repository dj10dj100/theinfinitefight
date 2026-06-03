extends Control

# -----------------------------------------------
# LEVEL EDITOR
# Place objects on a grid before battle.
# Objects get saved to GameManager and spawned
# when the battle starts.
# Grid covers the ENEMY zone (top half of field).
# -----------------------------------------------

# Grid size — how many cells wide and tall
const COLS = 17
const ROWS = 8

# Cell size in pixels on screen
const CELL_PX = 44

# What object types you can place
const OBJECTS = [
	{"key": "tree",  "icon": "🌲", "label": "Tree",       "colour": Color(0.15, 0.45, 0.12)},
	{"key": "rock",  "icon": "🪨", "label": "Rock",       "colour": Color(0.45, 0.42, 0.38)},
	{"key": "wall",  "icon": "🧱", "label": "Wall",       "colour": Color(0.35, 0.30, 0.25)},
	{"key": "bush",  "icon": "🌿", "label": "Bush",       "colour": Color(0.20, 0.52, 0.18)},
	{"key": "erase", "icon": "🗑", "label": "Erase",      "colour": Color(0.6, 0.15, 0.15)},
]

var selected_object: String = "tree"
var grid: Dictionary = {}    # {Vector2i(col, row): object_key}
var cell_rects: Dictionary = {}   # {Vector2i: ColorRect}
var grid_container: Control = null

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	SoundManager.play_music("menu")
	# Load any previously placed objects
	if GameManager and GameManager.has_meta("level_editor_grid"):
		grid = GameManager.get_meta("level_editor_grid")
	build_ui()

func build_ui():
	# Dark background
	var bg = ColorRect.new()
	bg.color = Color(0.07, 0.09, 0.13)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Title
	var title = Label.new()
	title.text = "🛠  LEVEL EDITOR  🛠"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	title.set_anchor(SIDE_LEFT,  0); title.set_anchor(SIDE_RIGHT,  1)
	title.set_anchor(SIDE_TOP,   0); title.set_anchor(SIDE_BOTTOM, 0)
	title.offset_top    = 12
	title.offset_bottom = 50
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	var hint = Label.new()
	hint.text = "Click cells to place objects in the ENEMY ZONE.  Your army deploys in the green zone below."
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	hint.set_anchor(SIDE_LEFT,  0); hint.set_anchor(SIDE_RIGHT,  1)
	hint.offset_top    = 52
	hint.offset_bottom = 74
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)

	# Tool palette (left side)
	_build_palette()

	# Grid (centre)
	_build_grid()

	# Bottom buttons
	_build_bottom_bar()

# -----------------------------------------------
# LEFT PALETTE — pick what to place
# -----------------------------------------------
func _build_palette():
	var panel = Panel.new()
	panel.set_anchor(SIDE_LEFT,   0); panel.set_anchor(SIDE_RIGHT,  0)
	panel.set_anchor(SIDE_TOP,    0); panel.set_anchor(SIDE_BOTTOM, 1)
	panel.offset_left   = 10
	panel.offset_right  = 130
	panel.offset_top    = 80
	panel.offset_bottom = -70
	add_child(panel)

	var h = Label.new()
	h.text = "TOOLS"
	h.add_theme_font_size_override("font_size", 14)
	h.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
	h.position = Vector2(0, 10)
	h.size     = Vector2(120, 24)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(h)

	var tool_btns: Array = []
	for i in OBJECTS.size():
		var obj = OBJECTS[i]
		var btn = Button.new()
		btn.text = obj["icon"] + "  " + obj["label"]
		btn.add_theme_font_size_override("font_size", 14)
		btn.position = Vector2(8, 44 + i * 52)
		btn.size     = Vector2(104, 44)
		var is_sel = (obj["key"] == selected_object)
		btn.modulate = Color(0.3, 1.0, 0.5) if is_sel else Color(1, 1, 1)
		var key = obj["key"]
		btn.pressed.connect(func():
			selected_object = key
			SoundManager.play("click")
			for b in tool_btns:
				b.modulate = Color(1, 1, 1)
			btn.modulate = Color(0.3, 1.0, 0.5)
		)
		panel.add_child(btn)
		tool_btns.append(btn)

	# Object count label
	var count_lbl = Label.new()
	count_lbl.name = "CountLabel"
	count_lbl.text = _count_text()
	count_lbl.add_theme_font_size_override("font_size", 11)
	count_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	count_lbl.position = Vector2(4, 310)
	count_lbl.size     = Vector2(116, 80)
	count_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(count_lbl)

# -----------------------------------------------
# GRID — the clickable cell area
# -----------------------------------------------
func _build_grid():
	grid_container = Control.new()
	grid_container.set_anchor(SIDE_LEFT, 0.5); grid_container.set_anchor(SIDE_RIGHT, 0.5)
	grid_container.set_anchor(SIDE_TOP,  0);   grid_container.set_anchor(SIDE_BOTTOM, 0)
	var total_w = COLS * CELL_PX
	var total_h = ROWS * CELL_PX
	grid_container.offset_left   = -total_w / 2.0
	grid_container.offset_right  =  total_w / 2.0
	grid_container.offset_top    = 84
	grid_container.offset_bottom = 84 + total_h
	add_child(grid_container)

	for row in ROWS:
		for col in COLS:
			var cell = ColorRect.new()
			# Alternate a subtle checkerboard
			var light = (row + col) % 2 == 0
			cell.color = Color(0.18, 0.24, 0.18) if light else Color(0.15, 0.20, 0.15)
			cell.position = Vector2(col * CELL_PX, row * CELL_PX)
			cell.size     = Vector2(CELL_PX - 1, CELL_PX - 1)
			cell.mouse_filter = Control.MOUSE_FILTER_STOP
			var coord = Vector2i(col, row)
			cell.gui_input.connect(_on_cell_input.bind(coord))
			grid_container.add_child(cell)
			cell_rects[coord] = cell

	# Draw any already-placed objects
	for coord in grid:
		_paint_cell(coord, grid[coord])

	# Border label — enemy zone
	var ez = Label.new()
	ez.text = "ENEMY ZONE  🔴"
	ez.add_theme_font_size_override("font_size", 13)
	ez.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4, 0.7))
	ez.set_anchor(SIDE_LEFT, 0.5); ez.set_anchor(SIDE_RIGHT, 0.5)
	ez.set_anchor(SIDE_TOP, 0);    ez.set_anchor(SIDE_BOTTOM, 0)
	ez.offset_left  = -200
	ez.offset_right = 200
	ez.offset_top   = 60
	ez.offset_bottom = 82
	ez.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ez.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ez)

func _on_cell_input(event: InputEvent, coord: Vector2i):
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	SoundManager.play("click")
	if selected_object == "erase":
		grid.erase(coord)
		_paint_cell(coord, "")
	else:
		grid[coord] = selected_object
		_paint_cell(coord, selected_object)
	_update_count()

func _paint_cell(coord: Vector2i, obj_key: String):
	var cell = cell_rects.get(coord)
	if cell == null:
		return
	# Remove old content label if any
	for child in cell.get_children():
		child.queue_free()

	if obj_key == "":
		var light = (coord.x + coord.y) % 2 == 0
		cell.color = Color(0.18, 0.24, 0.18) if light else Color(0.15, 0.20, 0.15)
		return

	# Find the object info
	for obj in OBJECTS:
		if obj["key"] == obj_key:
			cell.color = obj["colour"]
			var icon = Label.new()
			icon.text = obj["icon"]
			icon.add_theme_font_size_override("font_size", 22)
			icon.position = Vector2(4, 4)
			icon.size     = Vector2(CELL_PX - 8, CELL_PX - 8)
			icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cell.add_child(icon)
			break

func _count_text() -> String:
	var counts: Dictionary = {}
	for key in grid.values():
		counts[key] = counts.get(key, 0) + 1
	var txt = "Placed:\n"
	for obj in OBJECTS:
		if obj["key"] == "erase":
			continue
		var n = counts.get(obj["key"], 0)
		if n > 0:
			txt += obj["icon"] + " " + str(n) + "\n"
	return txt if counts.size() > 0 else "Nothing placed yet"

func _update_count():
	# Find the count label and update it
	var palette = get_node_or_null("Panel")  # first panel added
	# Walk children to find it
	for child in get_children():
		if child is Panel:
			var lbl = child.get_node_or_null("CountLabel")
			if lbl:
				lbl.text = _count_text()
			break

# -----------------------------------------------
# BOTTOM BAR
# -----------------------------------------------
func _build_bottom_bar():
	# Clear all button
	var clear_btn = Button.new()
	clear_btn.text = "🗑  Clear All"
	clear_btn.add_theme_font_size_override("font_size", 16)
	clear_btn.set_anchor(SIDE_LEFT,   0); clear_btn.set_anchor(SIDE_RIGHT,  0)
	clear_btn.set_anchor(SIDE_TOP,    1); clear_btn.set_anchor(SIDE_BOTTOM, 1)
	clear_btn.offset_left   = 10
	clear_btn.offset_right  = 200
	clear_btn.offset_top    = -60
	clear_btn.offset_bottom = -10
	clear_btn.pressed.connect(func():
		SoundManager.play("click")
		grid.clear()
		for coord in cell_rects:
			_paint_cell(coord, "")
		_update_count()
	)
	add_child(clear_btn)

	# Save and go to Deploy button
	var save_btn = Button.new()
	save_btn.text = "💾  Save & Deploy  ➜"
	save_btn.add_theme_font_size_override("font_size", 20)
	save_btn.set_anchor(SIDE_LEFT,   1); save_btn.set_anchor(SIDE_RIGHT,  1)
	save_btn.set_anchor(SIDE_TOP,    1); save_btn.set_anchor(SIDE_BOTTOM, 1)
	save_btn.offset_left   = -340
	save_btn.offset_right  = -10
	save_btn.offset_top    = -60
	save_btn.offset_bottom = -10
	save_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	save_btn.pressed.connect(_save_and_deploy)
	add_child(save_btn)

	# Back to menu
	var back_btn = Button.new()
	back_btn.text = "← Back"
	back_btn.add_theme_font_size_override("font_size", 16)
	back_btn.set_anchor(SIDE_LEFT,   0); back_btn.set_anchor(SIDE_RIGHT,  0)
	back_btn.set_anchor(SIDE_TOP,    1); back_btn.set_anchor(SIDE_BOTTOM, 1)
	back_btn.offset_left   = 210
	back_btn.offset_right  = 360
	back_btn.offset_top    = -60
	back_btn.offset_bottom = -10
	back_btn.pressed.connect(func():
		SoundManager.play("click")
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	add_child(back_btn)

func _save_and_deploy():
	SoundManager.play("click")
	# Save grid to GameManager
	if GameManager:
		GameManager.set_meta("level_editor_grid", grid)
	# Convert grid cells to 3D world positions for Battlefield to use
	var objects_3d: Array = []
	for coord in grid:
		# Map grid col/row to 3D world coords (enemy zone)
		var world_x = lerp(-15.0, 15.0, float(coord.x) / float(COLS - 1))
		var world_z = lerp(2.0,   14.0, float(coord.y) / float(ROWS - 1))
		objects_3d.append({
			"type":     grid[coord],
			"position": Vector3(world_x, 0.0, world_z),
		})
	if GameManager:
		GameManager.set_meta("editor_objects", objects_3d)
	get_tree().change_scene_to_file("res://scenes/DeployScreen.tscn")
