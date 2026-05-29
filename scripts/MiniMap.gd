extends CanvasLayer

# -----------------------------------------------
# MINI MAP
# A small radar in the bottom-right corner that
# shows where every clone and enemy is on the
# battlefield in real time!
#
# Green dots = your clones
# Red dots   = enemies
# Yellow star = the clone YOU are controlling
# Orange big dot = the Boss!
# -----------------------------------------------

const MAP_SIZE    = 180.0   # Pixel size of the mini-map
const FIELD_W     = 36.0    # Real battlefield width  (-18 to +18)
const FIELD_D     = 30.0    # Real battlefield depth  (-15 to +15)
const DOT_SIZE    = 7.0     # How big each blip is

var _map_bg:    ColorRect = null
var _container: Control   = null

func _ready():
	layer = 5   # Draw on top of everything

	# Outer panel
	_container = Control.new()
	_container.set_anchor(SIDE_RIGHT,  1)
	_container.set_anchor(SIDE_BOTTOM, 1)
	_container.set_anchor(SIDE_LEFT,   1)
	_container.set_anchor(SIDE_TOP,    1)
	_container.offset_left   = -(MAP_SIZE + 14)
	_container.offset_right  = -8
	_container.offset_top    = -(MAP_SIZE + 14)
	_container.offset_bottom = -8
	add_child(_container)

	# Dark background
	_map_bg = ColorRect.new()
	_map_bg.color = Color(0.0, 0.06, 0.0, 0.82)
	_map_bg.size  = Vector2(MAP_SIZE, MAP_SIZE)
	_container.add_child(_map_bg)

	# Green border
	for side in ["top","bottom","left","right"]:
		var border = ColorRect.new()
		border.color = Color(0.2, 0.7, 0.2, 0.9)
		match side:
			"top":    border.position = Vector2(0,0);            border.size = Vector2(MAP_SIZE, 2)
			"bottom": border.position = Vector2(0,MAP_SIZE-2);   border.size = Vector2(MAP_SIZE, 2)
			"left":   border.position = Vector2(0,0);            border.size = Vector2(2, MAP_SIZE)
			"right":  border.position = Vector2(MAP_SIZE-2,0);   border.size = Vector2(2, MAP_SIZE)
		_map_bg.add_child(border)

	# "MAP" label top-left
	var lbl = Label.new()
	lbl.text = "MAP"
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3, 0.8))
	lbl.position = Vector2(4, 2)
	_map_bg.add_child(lbl)

func _process(_delta):
	# Clear old dots (everything after the border lines + label)
	var children = _map_bg.get_children()
	for i in range(children.size() - 1, 4, -1):
		children[i].queue_free()

	# Draw enemy dots (red)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			var is_boss = enemy.is_in_group("boss")
			_draw_dot(enemy.global_position,
				Color(1.0, 0.15, 0.15) if not is_boss else Color(1.0, 0.5, 0.0),
				DOT_SIZE * (2.0 if is_boss else 1.0))

	# Draw clone dots (green, or yellow star if player-controlled)
	for clone in get_tree().get_nodes_in_group("clones"):
		if is_instance_valid(clone):
			var is_controlled = clone.is_player_controlled or clone.is_player2_controlled
			_draw_dot(clone.global_position,
				Color(1.0, 0.95, 0.1) if is_controlled else Color(0.2, 1.0, 0.3),
				DOT_SIZE * (1.4 if is_controlled else 1.0),
				"★" if is_controlled else "")

func _draw_dot(world_pos: Vector3, colour: Color, size: float, symbol: String = ""):
	# Convert 3D world position to 2D mini-map pixel position
	var px = ((world_pos.x + FIELD_W * 0.5) / FIELD_W) * MAP_SIZE
	var py = ((world_pos.z + FIELD_D * 0.5) / FIELD_D) * MAP_SIZE
	px = clamp(px, 2, MAP_SIZE - 2)
	py = clamp(py, 2, MAP_SIZE - 2)

	if symbol != "":
		var lbl = Label.new()
		lbl.text = symbol
		lbl.add_theme_font_size_override("font_size", int(size + 4))
		lbl.add_theme_color_override("font_color", colour)
		lbl.position = Vector2(px - size * 0.5, py - size * 0.5)
		_map_bg.add_child(lbl)
	else:
		var dot = ColorRect.new()
		dot.color    = colour
		dot.size     = Vector2(size, size)
		dot.position = Vector2(px - size * 0.5, py - size * 0.5)
		_map_bg.add_child(dot)
