extends Node3D

# -----------------------------------------------
# SKY DROP 🌀
# A power-up crate falls from the sky during battle!
# Walk over it to collect it instantly.
#
# Types:
#   speed_boost   — all clones move 2× faster for 8s
#   invincibility — all clones take no damage for 5s
#   mega_damage   — all clones deal 3× damage for 8s
#   full_heal     — all clones fully healed to 100 HP
#   ammo_drop     — all clones get full ammo instantly
# -----------------------------------------------

var drop_type: String = "speed_boost"

const DROP_TYPES = ["speed_boost", "invincibility", "mega_damage", "full_heal", "ammo_drop"]

const COLOURS = {
	"speed_boost":   Color(0.2, 0.8, 1.0),   # Cyan
	"invincibility": Color(1.0, 0.9, 0.1),   # Gold
	"mega_damage":   Color(1.0, 0.2, 0.1),   # Red
	"full_heal":     Color(0.2, 1.0, 0.4),   # Green
	"ammo_drop":     Color(0.8, 0.5, 0.1),   # Orange
}

const LABELS = {
	"speed_boost":   "⚡ SPEED BOOST!",
	"invincibility": "🛡️ INVINCIBLE!",
	"mega_damage":   "💥 MEGA DAMAGE!",
	"full_heal":     "💚 FULL HEAL!",
	"ammo_drop":     "🔫 AMMO DROP!",
}

var _collected: bool = false
var _land_y: float   = 0.5
var _falling: bool   = true
var _bob_time: float = 0.0
var _mesh: MeshInstance3D
var _light: OmniLight3D
var _col: Area3D

func _ready():
	# Pick a random type if not set
	if drop_type == "speed_boost":
		drop_type = DROP_TYPES[randi() % DROP_TYPES.size()]

	_build_visual()

func _build_visual():
	var colour = COLOURS[drop_type]

	# Crate body
	_mesh = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(0.7, 0.7, 0.7)
	_mesh.mesh = bm
	var mat = StandardMaterial3D.new()
	mat.albedo_color    = colour
	mat.emission_enabled = true
	mat.emission        = colour * 0.6
	mat.roughness       = 0.3
	_mesh.set_surface_override_material(0, mat)
	add_child(_mesh)

	# Glow light
	_light = OmniLight3D.new()
	_light.light_color  = colour
	_light.light_energy = 2.5
	_light.omni_range   = 4.0
	add_child(_light)

	# Pickup collision area
	_col = Area3D.new()
	var shape = CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = Vector3(1.0, 1.0, 1.0)
	_col.add_child(shape)
	_col.body_entered.connect(_on_body_entered)
	add_child(_col)

	# Show a floating label above the crate
	var canvas = CanvasLayer.new()
	var lbl = Label.new()
	lbl.text = LABELS[drop_type]
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", colour)
	lbl.set_anchor(SIDE_LEFT, 0.5); lbl.set_anchor(SIDE_RIGHT, 0.5)
	lbl.set_anchor(SIDE_TOP, 0.5);  lbl.set_anchor(SIDE_BOTTOM, 0.5)
	lbl.offset_left = -100; lbl.offset_right = 100
	lbl.offset_top  = -200; lbl.offset_bottom = -180
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	canvas.add_child(lbl)
	add_child(canvas)

func _process(delta):
	if _collected:
		return

	if _falling:
		# Fall from the sky
		position.y -= 12.0 * delta
		if position.y <= _land_y:
			position.y = _land_y
			_falling   = false
			SoundManager.play("click")
			print("📦 POWER-UP LANDED: ", LABELS[drop_type])

	else:
		# Bob up and down gently to attract attention
		_bob_time += delta * 2.5
		_mesh.position.y = sin(_bob_time) * 0.12
		# Spin
		_mesh.rotate_y(delta * 1.5)
		# Pulse the light
		_light.light_energy = 2.0 + sin(_bob_time * 3.0) * 0.5

	# Auto-despawn after 20 seconds if nobody picks it up
	# (handled via a timer set in Battlefield when spawning)

func _on_body_entered(body):
	if _collected:
		return
	if body.is_in_group("clones"):
		_collected = true
		_apply_effect()
		queue_free()

func _apply_effect():
	var clones = get_tree().get_nodes_in_group("clones")
	print("✨ Power-up collected: ", drop_type)

	match drop_type:
		"speed_boost":
			for clone in clones:
				if is_instance_valid(clone):
					clone.move_speed *= 2.0
			await get_tree().create_timer(8.0).timeout
			for clone in clones:
				if is_instance_valid(clone):
					clone.move_speed /= 2.0
			print("⚡ Speed boost wore off.")

		"invincibility":
			# Give every clone a huge shield
			for clone in clones:
				if is_instance_valid(clone):
					clone.activate_shield(999)
			await get_tree().create_timer(5.0).timeout
			for clone in clones:
				if is_instance_valid(clone):
					clone.shield_hits = 0
			print("🛡️ Invincibility wore off.")

		"mega_damage":
			for clone in clones:
				if is_instance_valid(clone):
					clone.rank_damage_bonus *= 3.0
			await get_tree().create_timer(8.0).timeout
			for clone in clones:
				if is_instance_valid(clone):
					clone.rank_damage_bonus /= 3.0
			print("💥 Mega damage wore off.")

		"full_heal":
			for clone in clones:
				if is_instance_valid(clone):
					clone.health = 100.0
			print("💚 All clones fully healed!")

		"ammo_drop":
			for clone in clones:
				if is_instance_valid(clone):
					clone.ammo        = clone.max_ammo
					clone.is_reloading = false
			print("🔫 All clones reloaded!")

	_show_effect_banner(LABELS[drop_type], COLOURS[drop_type])

func _show_effect_banner(text: String, colour: Color):
	var canvas = CanvasLayer.new()
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 30)
	lbl.add_theme_color_override("font_color", colour)
	lbl.set_anchor(SIDE_LEFT, 0.5);  lbl.set_anchor(SIDE_RIGHT, 0.5)
	lbl.set_anchor(SIDE_TOP, 0.35);  lbl.set_anchor(SIDE_BOTTOM, 0.35)
	lbl.offset_left = -250; lbl.offset_right = 250
	lbl.offset_top  = -20;  lbl.offset_bottom = 20
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	canvas.add_child(lbl)
	get_tree().root.add_child(canvas)
	SoundManager.play("victory_sting")
	var tw = get_tree().create_tween()
	tw.tween_property(lbl, "position:y", lbl.position.y - 40, 2.0)
	tw.parallel().tween_interval(1.4)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.6)
	tw.tween_callback(canvas.queue_free)
