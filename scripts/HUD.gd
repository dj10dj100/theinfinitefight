extends CanvasLayer

# -----------------------------------------------
# FIRST-PERSON HUD
# Only visible when you're controlling a clone.
# Shows:
#   - Crosshair (centre of screen)
#   - Health bar (bottom left)
#   - Weapon name (bottom right)
#   - "Press R to swap" hint for sniper clones
#   - Red edges when health is getting low!
# -----------------------------------------------

var tracked_clone = null   # The clone we're currently controlling

# UI nodes we'll update every frame
var health_bar:    ProgressBar
var health_label:  Label
var weapon_label:  Label
var swap_hint:     Label
var vignette:      ColorRect   # Red glow around the edges when low health

func _ready():
	build_hud()
	visible = false   # Hidden until player takes control

# -----------------------------------------------
# BUILD ALL THE HUD ELEMENTS
# -----------------------------------------------
func build_hud():
	# Root control that fills the whole screen
	var root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# === CROSSHAIR (dead centre) ===
	# Four short lines with a gap in the middle — classic FPS style
	var gap  = 6     # Gap between centre and each line
	var len  = 14    # Length of each line
	var thickness = 2
	var crosshair_color = Color(1, 1, 1, 0.90)

	# Top line
	_add_crosshair_bar(root, crosshair_color,
		Vector2(-thickness * 0.5, -(gap + len)),
		Vector2(thickness, len))
	# Bottom line
	_add_crosshair_bar(root, crosshair_color,
		Vector2(-thickness * 0.5, gap),
		Vector2(thickness, len))
	# Left line
	_add_crosshair_bar(root, crosshair_color,
		Vector2(-(gap + len), -thickness * 0.5),
		Vector2(len, thickness))
	# Right line
	_add_crosshair_bar(root, crosshair_color,
		Vector2(gap, -thickness * 0.5),
		Vector2(len, thickness))
	# Centre dot
	_add_crosshair_bar(root, Color(1, 0.35, 0.35, 0.95),
		Vector2(-2, -2), Vector2(4, 4))

	# === RED VIGNETTE (danger warning — shown when health < 30%) ===
	vignette = ColorRect.new()
	vignette.color = Color(0.7, 0, 0, 0.0)   # Starts invisible
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# We'll use a shader-style look by just modulating alpha
	root.add_child(vignette)

	# === HEALTH BAR (bottom left) ===
	var health_bg = Panel.new()
	health_bg.set_anchor(SIDE_LEFT,   0)
	health_bg.set_anchor(SIDE_RIGHT,  0)
	health_bg.set_anchor(SIDE_TOP,    1)
	health_bg.set_anchor(SIDE_BOTTOM, 1)
	health_bg.offset_left   = 20
	health_bg.offset_right  = 260
	health_bg.offset_top    = -80
	health_bg.offset_bottom = -20
	root.add_child(health_bg)

	var hp_title = Label.new()
	hp_title.text = "❤  HEALTH"
	hp_title.add_theme_font_size_override("font_size", 12)
	hp_title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	hp_title.position = Vector2(8, 4)
	hp_title.size     = Vector2(230, 20)
	hp_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_bg.add_child(hp_title)

	health_bar = ProgressBar.new()
	health_bar.min_value = 0
	health_bar.max_value = 100
	health_bar.value     = 100
	health_bar.position  = Vector2(8, 24)
	health_bar.size      = Vector2(230, 18)
	health_bar.show_percentage = false
	health_bg.add_child(health_bar)

	health_label = Label.new()
	health_label.text = "100 / 100"
	health_label.add_theme_font_size_override("font_size", 12)
	health_label.add_theme_color_override("font_color", Color(1, 1, 1))
	health_label.position = Vector2(8, 44)
	health_label.size     = Vector2(230, 18)
	health_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_bg.add_child(health_label)

	# === WEAPON INFO (bottom right) ===
	var weapon_bg = Panel.new()
	weapon_bg.set_anchor(SIDE_LEFT,   1)
	weapon_bg.set_anchor(SIDE_RIGHT,  1)
	weapon_bg.set_anchor(SIDE_TOP,    1)
	weapon_bg.set_anchor(SIDE_BOTTOM, 1)
	weapon_bg.offset_left   = -240
	weapon_bg.offset_right  = -20
	weapon_bg.offset_top    = -80
	weapon_bg.offset_bottom = -20
	root.add_child(weapon_bg)

	var w_title = Label.new()
	w_title.text = "🔫  WEAPON"
	w_title.add_theme_font_size_override("font_size", 12)
	w_title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	w_title.position = Vector2(8, 4)
	w_title.size     = Vector2(210, 20)
	w_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	weapon_bg.add_child(w_title)

	weapon_label = Label.new()
	weapon_label.text = "Pistol"
	weapon_label.add_theme_font_size_override("font_size", 20)
	weapon_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	weapon_label.position = Vector2(8, 22)
	weapon_label.size     = Vector2(210, 30)
	weapon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	weapon_bg.add_child(weapon_label)

	# Swap hint (only visible for sniper clones)
	swap_hint = Label.new()
	swap_hint.text = "[ R ] — swap weapon"
	swap_hint.add_theme_font_size_override("font_size", 12)
	swap_hint.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	swap_hint.position = Vector2(8, 50)
	swap_hint.size     = Vector2(210, 18)
	swap_hint.visible  = false
	swap_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	weapon_bg.add_child(swap_hint)

	# === ESC HINT (top right, small) ===
	var esc_hint = Label.new()
	esc_hint.text = "ESC — back to overview"
	esc_hint.add_theme_font_size_override("font_size", 12)
	esc_hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	esc_hint.set_anchor(SIDE_LEFT,  1)
	esc_hint.set_anchor(SIDE_RIGHT, 1)
	esc_hint.set_anchor(SIDE_TOP,   0)
	esc_hint.offset_left   = -240
	esc_hint.offset_right  = -10
	esc_hint.offset_top    = 12
	esc_hint.offset_bottom = 32
	esc_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	esc_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(esc_hint)

# -----------------------------------------------
# Helper — a single coloured bar for the crosshair
# offset is from screen centre
# -----------------------------------------------
func _add_crosshair_bar(root: Control, colour: Color,
		offset: Vector2, size: Vector2) -> void:
	var bar = ColorRect.new()
	bar.color = colour
	bar.set_anchor(SIDE_LEFT,   0.5)
	bar.set_anchor(SIDE_RIGHT,  0.5)
	bar.set_anchor(SIDE_TOP,    0.5)
	bar.set_anchor(SIDE_BOTTOM, 0.5)
	bar.offset_left   = offset.x
	bar.offset_right  = offset.x + size.x
	bar.offset_top    = offset.y
	bar.offset_bottom = offset.y + size.y
	bar.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	root.add_child(bar)

# -----------------------------------------------
# SHOW / HIDE — called by Battlefield.gd
# -----------------------------------------------
func show_hud(clone) -> void:
	tracked_clone = clone
	visible = true

func hide_hud() -> void:
	tracked_clone = null
	visible = false

# -----------------------------------------------
# UPDATE every frame — health, weapon, vignette
# -----------------------------------------------
func _process(_delta: float) -> void:
	if not visible or tracked_clone == null:
		return
	if not is_instance_valid(tracked_clone):
		hide_hud()
		return

	# --- Health ---
	var hp     = tracked_clone.health
	var max_hp = 100.0
	health_bar.value = clamp((hp / max_hp) * 100.0, 0, 100)
	health_label.text = str(int(hp)) + " HP"

	# Colour the bar green → yellow → red as health drops
	var hp_pct = hp / max_hp
	if hp_pct > 0.5:
		health_bar.modulate = Color(0.3, 1.0, 0.35)   # Green
	elif hp_pct > 0.25:
		health_bar.modulate = Color(1.0, 0.75, 0.1)   # Yellow
	else:
		health_bar.modulate = Color(1.0, 0.2, 0.2)    # Red

	# --- Red danger vignette when health < 30% ---
	if hp_pct < 0.30:
		# Pulse the vignette in and out
		var pulse = (sin(Time.get_ticks_msec() * 0.004) + 1.0) * 0.5
		vignette.color.a = lerp(0.0, 0.35, pulse) * (1.0 - hp_pct / 0.30)
	else:
		vignette.color.a = 0.0

	# --- Weapon name ---
	var weapon_names = {
		"pistol":        "Pistol",
		"revolver":      "Revolver",
		"shotgun":       "Shotgun",
		"assault_rifle": "Assault Rifle",
		"machine_gun":   "Machine Gun",
		"sniper":        "Sniper Rifle"
	}
	var active = tracked_clone.active_weapon if "active_weapon" in tracked_clone else tracked_clone.weapon
	weapon_label.text = weapon_names.get(active, active.capitalize())

	# --- Swap hint (only for snipers with a secondary weapon) ---
	var has_secondary = "secondary_weapon" in tracked_clone and tracked_clone.secondary_weapon != ""
	swap_hint.visible = has_secondary
