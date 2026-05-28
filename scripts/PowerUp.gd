extends Area3D

# -----------------------------------------------
# POWER-UP
# These appear randomly on the battlefield!
# Walk over one to pick it up.
#
# Types:
#   "health"  — heals your clone for 50 HP
#   "speed"   — makes you run faster for 8 seconds
#   "shield"  — blocks the next 3 hits completely
# -----------------------------------------------

@export var type: String = "health"   # health / speed / shield

# Each type has a colour
const COLOURS = {
	"health": Color(0.1, 0.9, 0.2),   # Bright green
	"speed":  Color(0.1, 0.5, 1.0),   # Blue
	"shield": Color(1.0, 0.85, 0.0),  # Gold
}

const LABELS = {
	"health": "❤️ +50 HP",
	"speed":  "⚡ SPEED!",
	"shield": "🛡 SHIELD!",
}

var spin_speed: float = 1.8   # How fast it spins
var bob_time:   float = 0.0   # Used for bobbing up and down
var base_y:     float = 0.0

func _ready():
	# Build the visual — a spinning glowing cube
	var mesh_inst = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.7, 0.7, 0.7)
	mesh_inst.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = COLOURS.get(type, Color(1, 1, 1))
	mat.emission_enabled = true
	mat.emission = COLOURS.get(type, Color(1, 1, 1)) * 0.6
	mat.roughness = 0.2
	mesh_inst.set_surface_override_material(0, mat)
	add_child(mesh_inst)

	# Collision so clones can pick it up
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.0, 1.0, 1.0)
	col.shape = shape
	add_child(col)

	base_y = position.y
	body_entered.connect(_on_body_entered)

func _process(delta):
	# Spin and bob up and down
	rotation.y += spin_speed * delta
	bob_time += delta
	position.y = base_y + sin(bob_time * 2.0) * 0.18

# -----------------------------------------------
# WHEN A CLONE WALKS INTO IT
# -----------------------------------------------
func _on_body_entered(body):
	if not body.is_in_group("clones"):
		return

	SoundManager.play("click")

	match type:
		"health":
			# Heal the clone!
			body.health = min(body.health + 50.0, 100.0)
			print("❤️  Health pack! Clone healed to ", body.health)

		"speed":
			# Speed boost for 8 seconds
			body.move_speed *= 2.2
			print("⚡  Speed boost! Running fast for 8 seconds!")
			# Create a timer to reset speed
			var timer = get_tree().create_timer(8.0)
			timer.timeout.connect(func():
				if is_instance_valid(body):
					body.move_speed /= 2.2
					print("Speed boost wore off.")
			)

		"shield":
			# Give the clone a shield (3 hit blocks)
			if body.has_method("activate_shield"):
				body.activate_shield(3)
			print("🛡  Shield activated! Next 3 hits blocked!")

	# Flash a label on screen
	_show_pickup_label()

	queue_free()

func _show_pickup_label():
	# Show a floating "+50 HP" or "SPEED!" message on screen
	var label = Label.new()
	label.text = LABELS.get(type, "POWER UP!")
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", COLOURS.get(type, Color(1,1,1)))

	# Put the label at the centre-top of the screen
	label.set_anchor(SIDE_LEFT, 0.5)
	label.set_anchor(SIDE_RIGHT, 0.5)
	label.set_anchor(SIDE_TOP, 0)
	label.set_anchor(SIDE_BOTTOM, 0)
	label.offset_left   = -100
	label.offset_right  =  100
	label.offset_top    =  80
	label.offset_bottom =  120
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Add to scene tree (as a CanvasLayer so it appears on screen)
	var canvas = CanvasLayer.new()
	canvas.add_child(label)
	get_tree().root.add_child(canvas)

	# Fade it up and out
	var tween = get_tree().create_tween()
	tween.tween_property(label, "position:y", label.position.y - 60, 1.2)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.2)
	tween.tween_callback(canvas.queue_free)
