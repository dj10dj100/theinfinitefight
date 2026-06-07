extends Node3D

# -----------------------------------------------
# AIRSTRIKE
# A bomb falls from the sky at a target position.
# There's a warning circle first so you can see
# where it's going to land — then KABOOM!
# -----------------------------------------------

var target_pos: Vector3 = Vector3.ZERO
var damage: float  = 200.0   # Huge damage — direct hit
var radius: float  = 6.0     # Big blast radius

func _ready():
	# Show a warning circle on the ground so you know where it will land
	_spawn_warning_circle()
	# Wait 1.5 seconds, then drop the bomb
	await get_tree().create_timer(1.5).timeout
	_drop_bomb()

func _spawn_warning_circle():
	# Red flashing ring on the ground
	var ring = MeshInstance3D.new()
	ring.mesh = TorusMesh.new()
	ring.mesh.inner_radius = radius - 0.3
	ring.mesh.outer_radius = radius
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.1, 0.1, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.0, 0.0)
	ring.set_surface_override_material(0, mat)
	ring.position = target_pos
	ring.position.y = 0.05   # Just above the ground
	get_tree().root.add_child(ring)

	# Flash it on and off (5 flashes over 1.5 seconds), then remove it
	var tween = get_tree().create_tween()
	tween.set_loops(5)
	tween.tween_callback(func(): ring.visible = false)
	tween.tween_interval(0.15)
	tween.tween_callback(func(): ring.visible = true)
	tween.tween_interval(0.15)
	# Free the ring after the flashing is done (5 × 0.3s = 1.5s)
	get_tree().create_timer(1.5).timeout.connect(func():
		if is_instance_valid(ring):
			ring.queue_free()
	)

func _drop_bomb():
	# The bomb itself — starts high above the target
	var bomb = MeshInstance3D.new()
	bomb.mesh = CylinderMesh.new()
	bomb.mesh.top_radius = 0.05
	bomb.mesh.bottom_radius = 0.22
	bomb.mesh.height = 0.7
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.2)
	bomb.set_surface_override_material(0, mat)
	bomb.position = target_pos + Vector3(0, 30, 0)
	get_tree().root.add_child(bomb)

	# Tween it dropping fast
	var tween = get_tree().create_tween()
	tween.tween_property(bomb, "position:y", 0.5, 0.5)
	tween.tween_callback(func():
		bomb.queue_free()
		_explode()
	)

func _explode():
	# Multiple overlapping explosions for a big effect
	Particles.death_explosion(target_pos + Vector3(0, 0.3, 0), Color(1.0, 0.4, 0.0))
	Particles.death_explosion(target_pos + Vector3(1, 0.5, 0.5), Color(1.0, 0.7, 0.0))
	Particles.death_explosion(target_pos + Vector3(-0.8, 0.4, -0.6), Color(1.0, 0.2, 0.0))
	SoundManager.play("death")

	# Damage every enemy inside the blast radius
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var dist = target_pos.distance_to(enemy.global_position)
		if dist <= radius:
			var falloff = 1.0 - (dist / radius)
			enemy.take_damage(damage * falloff)

	# Blow up destructible walls too!
	for wall in get_tree().get_nodes_in_group("destructible"):
		if is_instance_valid(wall):
			var dist = target_pos.distance_to(wall.global_position)
			if dist <= radius:
				wall.take_damage(damage * (1.0 - dist / radius))

	queue_free()
