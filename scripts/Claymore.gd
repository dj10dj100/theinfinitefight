extends Node3D

# -----------------------------------------------
# CLAYMORE MINE 💣
# Placed by the player with the C key.
# A red laser tripwire shoots out in front.
# Any enemy that walks through — BOOM!
# -----------------------------------------------

var _triggered: bool = false
var _laser:     MeshInstance3D = null
var _body:      MeshInstance3D = null
const DAMAGE    = 120.0
const RANGE     = 4.5   # How long the laser beam is

func _ready():
	_build_visual()
	_build_tripwire()

func _build_visual():
	# The mine body — a small green box with a red light
	_body = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(0.25, 0.12, 0.15)
	_body.mesh = bm
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.20, 0.28, 0.10)
	mat.roughness    = 0.7
	_body.set_surface_override_material(0, mat)
	add_child(_body)

	# Red warning light on top
	var light = OmniLight3D.new()
	light.light_color  = Color(1.0, 0.1, 0.1)
	light.light_energy = 1.5
	light.omni_range   = 1.5
	light.position     = Vector3(0, 0.1, 0)
	add_child(light)

	# Pulse the light
	var tw = get_tree().create_tween().set_loops()
	tw.tween_property(light, "light_energy", 0.2, 0.5)
	tw.tween_property(light, "light_energy", 1.5, 0.5)

func _build_tripwire():
	# Laser beam shooting forward
	_laser = MeshInstance3D.new()
	var bm  = BoxMesh.new()
	bm.size = Vector3(0.025, 0.025, RANGE)
	_laser.mesh = bm
	var mat = StandardMaterial3D.new()
	mat.albedo_color     = Color(1.0, 0.05, 0.05)
	mat.emission_enabled = true
	mat.emission         = Color(1.0, 0.0, 0.0) * 3.0
	mat.shading_mode     = BaseMaterial3D.SHADING_MODE_UNSHADED
	_laser.set_surface_override_material(0, mat)
	_laser.position = Vector3(0, 0.06, -RANGE * 0.5)
	add_child(_laser)

	# Detection area along the laser
	var area = Area3D.new()
	var shape = CollisionShape3D.new()
	var box   = BoxShape3D.new()
	box.size  = Vector3(0.3, 0.4, RANGE)
	shape.shape   = box
	shape.position = Vector3(0, 0.06, -RANGE * 0.5)
	area.add_child(shape)
	area.body_entered.connect(_on_body_entered)
	add_child(area)

func _on_body_entered(body):
	if _triggered:
		return
	if body.is_in_group("enemies"):
		_triggered = true
		_explode()

func _explode():
	SoundManager.play("death")
	Particles.death_explosion(global_position + Vector3(0, 0.3, 0), Color(1.0, 0.5, 0.1))

	# Damage all enemies in blast radius
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist < 3.5:
				enemy.take_damage(DAMAGE * (1.0 - dist / 3.5))

	print("💣 CLAYMORE TRIGGERED!")
	queue_free()
