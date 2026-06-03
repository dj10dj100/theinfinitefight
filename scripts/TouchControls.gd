extends CanvasLayer

# -----------------------------------------------
# TOUCH CONTROLS 📱
# Shows a virtual joystick and buttons on screen
# so the game works on phones and tablets!
#
# Layout:
#   Bottom-left  → Joystick (move)
#   Right side   → Swipe zone (look in first-person)
#   Bottom-right → FIRE button (big red)
#   Above fire   → G (grenade), A (airstrike), M (mine)
#   Top-right    → E button (enter/exit helicopter)
# -----------------------------------------------

# ---- Public values read by Clone.gd & Helicopter.gd ----
var move_vector:  Vector2 = Vector2.ZERO   # Joystick output (-1..1 on each axis)
var look_delta:   Vector2 = Vector2.ZERO   # How much the camera should rotate this frame
var fire_pressed: bool    = false          # True while the fire button is held
var key_g:        bool    = false          # Grenade button tapped
var key_a:        bool    = false          # Airstrike button tapped
var key_m:        bool    = false          # Mine button tapped
var key_e:        bool    = false          # Enter/exit helicopter tapped

# Only show touch controls when running on a touchscreen device
var _touch_enabled: bool = false

# ---- Joystick state ----
const JOYSTICK_RADIUS = 80.0
var _joy_touch_id:   int     = -1
var _joy_origin:     Vector2 = Vector2.ZERO
var _joy_current:    Vector2 = Vector2.ZERO

# ---- Look zone state ----
var _look_touch_id:  int     = -1
var _look_last:      Vector2 = Vector2.ZERO

# ---- UI nodes ----
var _joy_base:   ColorRect
var _joy_stick:  ColorRect
var _fire_btn:   Button
var _g_btn:      Button
var _a_btn:      Button
var _m_btn:      Button
var _e_btn:      Button
var _look_zone:  Control

func _ready():
	# Detect if this is a touchscreen
	_touch_enabled = DisplayServer.is_touchscreen_available()
	if not _touch_enabled:
		# Still show on desktop if there's no mouse (web mobile builds)
		_touch_enabled = OS.has_feature("mobile") or OS.has_feature("web")

	if not _touch_enabled:
		return   # Desktop with keyboard+mouse — hide everything

	layer = 10   # Draw on top of everything
	_build_ui()

# -----------------------------------------------
# Build the UI from code — no scene file needed!
# -----------------------------------------------
func _build_ui():
	var screen = get_viewport().get_visible_rect().size

	# ---------- LOOK ZONE (whole right half of screen) ----------
	_look_zone = Control.new()
	_look_zone.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_look_zone)

	# ---------- JOYSTICK BASE (bottom-left) ----------
	var joy_cx = 130.0
	var joy_cy = screen.y - 130.0

	_joy_base = ColorRect.new()
	_joy_base.color = Color(1, 1, 1, 0.15)
	_joy_base.size = Vector2(JOYSTICK_RADIUS * 2, JOYSTICK_RADIUS * 2)
	_joy_base.position = Vector2(joy_cx - JOYSTICK_RADIUS, joy_cy - JOYSTICK_RADIUS)
	_joy_base.pivot_offset = Vector2(JOYSTICK_RADIUS, JOYSTICK_RADIUS)
	# Round it with a StyleBox
	var joy_style = StyleBoxFlat.new()
	joy_style.corner_radius_top_left = int(JOYSTICK_RADIUS)
	joy_style.corner_radius_top_right = int(JOYSTICK_RADIUS)
	joy_style.corner_radius_bottom_left = int(JOYSTICK_RADIUS)
	joy_style.corner_radius_bottom_right = int(JOYSTICK_RADIUS)
	joy_style.bg_color = Color(1, 1, 1, 0.15)
	joy_style.border_width_left = 2
	joy_style.border_width_right = 2
	joy_style.border_width_top = 2
	joy_style.border_width_bottom = 2
	joy_style.border_color = Color(1, 1, 1, 0.4)
	_joy_base.add_theme_stylebox_override("panel", joy_style)
	add_child(_joy_base)

	# Joystick knob (smaller circle in the middle)
	_joy_stick = ColorRect.new()
	_joy_stick.color = Color(1, 1, 1, 0.5)
	const KNOB = 36.0
	_joy_stick.size = Vector2(KNOB * 2, KNOB * 2)
	_joy_stick.position = Vector2(joy_cx - KNOB, joy_cy - KNOB)
	_joy_stick.pivot_offset = Vector2(KNOB, KNOB)
	var knob_style = StyleBoxFlat.new()
	knob_style.corner_radius_top_left = int(KNOB)
	knob_style.corner_radius_top_right = int(KNOB)
	knob_style.corner_radius_bottom_left = int(KNOB)
	knob_style.corner_radius_bottom_right = int(KNOB)
	knob_style.bg_color = Color(1, 1, 1, 0.55)
	_joy_stick.add_theme_stylebox_override("panel", knob_style)
	add_child(_joy_stick)

	# ---------- FIRE BUTTON (bottom-right) ----------
	_fire_btn = _make_button("🔴\nFIRE", Color(0.9, 0.1, 0.1, 0.8), Vector2(screen.x - 110, screen.y - 110), Vector2(100, 100))
	_fire_btn.button_down.connect(func(): fire_pressed = true)
	_fire_btn.button_up.connect(func():   fire_pressed = false)
	add_child(_fire_btn)

	# ---------- ABILITY BUTTONS (above fire) ----------
	_g_btn = _make_button("💣\nG", Color(0.8, 0.5, 0.1, 0.8), Vector2(screen.x - 230, screen.y - 110), Vector2(80, 80))
	_g_btn.pressed.connect(func(): key_g = true)
	add_child(_g_btn)

	_a_btn = _make_button("✈️\nA", Color(0.1, 0.5, 0.9, 0.8), Vector2(screen.x - 230, screen.y - 200), Vector2(80, 80))
	_a_btn.pressed.connect(func(): key_a = true)
	add_child(_a_btn)

	_m_btn = _make_button("💥\nM", Color(0.6, 0.1, 0.1, 0.8), Vector2(screen.x - 120, screen.y - 220), Vector2(80, 80))
	_m_btn.pressed.connect(func(): key_m = true)
	add_child(_m_btn)

	# ---------- HELICOPTER BUTTON (top-right) ----------
	_e_btn = _make_button("🚁\nE", Color(0.2, 0.6, 0.2, 0.8), Vector2(screen.x - 100, 20), Vector2(80, 80))
	_e_btn.pressed.connect(func(): key_e = true)
	add_child(_e_btn)

# Helper: build a styled square button
func _make_button(label: String, colour: Color, pos: Vector2, sz: Vector2) -> Button:
	var btn = Button.new()
	btn.text = label
	btn.position = pos
	btn.size = sz
	btn.add_theme_font_size_override("font_size", 14)
	var style = StyleBoxFlat.new()
	style.bg_color = colour
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("hover", style)
	return btn

# -----------------------------------------------
# Touch input processing
# -----------------------------------------------
func _input(event):
	if not _touch_enabled:
		return

	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _handle_touch(event: InputEventScreenTouch):
	var pos = event.position
	var screen_w = get_viewport().get_visible_rect().size.x

	if event.pressed:
		# Is this touch inside the joystick zone? (left 30% of screen, bottom half)
		if pos.x < screen_w * 0.35 and pos.y > get_viewport().get_visible_rect().size.y * 0.4:
			_joy_touch_id = event.index
			_joy_origin   = pos
			_joy_current  = pos
		else:
			# Right side = look zone
			if _look_touch_id == -1:
				_look_touch_id = event.index
				_look_last     = pos
	else:
		# Finger lifted
		if event.index == _joy_touch_id:
			_joy_touch_id = -1
			move_vector   = Vector2.ZERO
			_reset_joystick_visual()
		if event.index == _look_touch_id:
			_look_touch_id = -1
			look_delta     = Vector2.ZERO

func _handle_drag(event: InputEventScreenDrag):
	if event.index == _joy_touch_id:
		_joy_current = event.position
		var offset   = _joy_current - _joy_origin
		var clamped  = offset.limit_length(JOYSTICK_RADIUS)
		move_vector  = clamped / JOYSTICK_RADIUS   # Normalised -1..1
		# Move the knob visual
		if _joy_stick:
			const KNOB = 36.0
			_joy_stick.position = _joy_origin + clamped - Vector2(KNOB, KNOB)

	elif event.index == _look_touch_id:
		look_delta = event.relative   # Raw pixel delta — Clone.gd scales it
		_look_last = event.position

# -----------------------------------------------
# Each frame: clear one-shot flags
# -----------------------------------------------
func _process(_delta):
	if not _touch_enabled:
		return
	# One-shot buttons reset after one frame so Clone picks them up once
	key_g = false
	key_a = false
	key_m = false
	key_e = false
	# Look delta decays to zero when the finger stops moving
	look_delta = Vector2.ZERO

func _reset_joystick_visual():
	if not _joy_base or not _joy_stick:
		return
	var cx = _joy_base.position.x + JOYSTICK_RADIUS
	var cy = _joy_base.position.y + JOYSTICK_RADIUS
	const KNOB = 36.0
	_joy_stick.position = Vector2(cx - KNOB, cy - KNOB)

# Show / hide the controls (called by Battlefield when entering first-person etc.)
func show_controls():
	if _touch_enabled:
		visible = true

func hide_controls():
	visible = false
