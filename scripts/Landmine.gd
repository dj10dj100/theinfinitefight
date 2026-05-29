extends Area3D

# -----------------------------------------------
# LANDMINE
# Dropped on the ground by a clone.
# Goes invisible after 2 seconds (hidden!).
# Explodes when an enemy walks over it.
# -----------------------------------------------

var damage: float = 150.0
var radius: float = 3.5
var armed: bool = false   # Not active right away — gives you time to run!

func _ready():
	add_to_group("landmines")

	# Build the mine mesh (a flat disc on the ground)
	var m = MeshInstance3D.new()
	m.name = "MeshInstance3D"
	m.mesh = CylinderMesh.new()
	m.mesh.top_radius    = 0.22
	m.mesh.bottom_radius = 0.22
	m.mesh.height        = 0.08
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.30, 0.18)
	mat.roughness = 0.7
	m.set_surface_override_material(0, mat)
	add_child(m)

	# Small blink light on top — yellow dot
	var dot = MeshInstance3D.new()
	dot.mesh = SphereMesh.new()
	dot.mesh.radius = 0.05
	dot.mesh.height = 0.1
	var dmat = StandardMaterial3D.new()
	dmat.albedo_color = Color(1.0, 0.9, 0.1)
	dmat.emission_enabled = true
	dmat.emission = Color(1.0, 0.8, 0.0)
	dot.set_surface_override_material(0, dmat)
	dot.position = Vector3(0, 0.06, 0)
	add_child(dot)

	# Arm after 2 seconds (so the clone who placed it can move away!)
	await get_tree().create_timer(2.0).timeout
	armed = true

	# Slowly fade out — the mine goes underground / hidden
	var tween = get_tree().create_tween()
	tween.tween_property(m, "modulate:a", 0.0, 1.0)
	tween.parallel().tween_property(dot, "modulate:a", 0.0, 1.0)

	# Connect collision — now watch for enemies
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if not armed:
		return
	if body.is_in_group("enemies"):
		_explode()

func _explode():
	Particles.death_explosion(global_position + Vector3(0, 0.3, 0), Color(1.0, 0.55, 0.0))
	SoundManager.play("death")
	Achievements.unlock("landmine_trap")

	for enemy in get_tree().get_nodes_in_group("enemies"):
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= radius:
			var falloff = 1.0 - (dist / radius)
			enemy.take_damage(damage * falloff)

	queue_free()
