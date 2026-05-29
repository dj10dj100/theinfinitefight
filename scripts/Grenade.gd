extends Area3D

# -----------------------------------------------
# GRENADE
# Thrown by a clone.  Bounces for a moment, then
# BOOM! — damages all enemies in a big radius.
# -----------------------------------------------

var velocity_vec: Vector3 = Vector3.ZERO
var timer: float = 2.2      # Seconds until it explodes
var damage: float = 120.0   # Damage to enemies caught in the blast
var radius: float = 5.0     # Blast radius in metres

func _ready():
	# Make the grenade visible — a small dark sphere
	var mesh = MeshInstance3D.new()
	mesh.mesh = SphereMesh.new()
	mesh.mesh.radius = 0.14
	mesh.mesh.height = 0.28
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.18, 0.12)
	mat.roughness = 0.6
	mesh.set_surface_override_material(0, mat)
	add_child(mesh)

func _process(delta):
	# Fly through the air (simple arc — gravity pulls it down)
	velocity_vec.y -= 9.8 * delta
	position += velocity_vec * delta

	# Bounce off the floor (y=0)
	if position.y <= 0.1 and velocity_vec.y < 0:
		position.y = 0.1
		velocity_vec.y = -velocity_vec.y * 0.35   # Dampen the bounce
		velocity_vec.x *= 0.7
		velocity_vec.z *= 0.7

	timer -= delta
	if timer <= 0:
		_explode()

func _explode():
	# Big orange explosion flash
	Particles.death_explosion(global_position + Vector3(0, 0.5, 0), Color(1.0, 0.5, 0.05))
	SoundManager.play("death")   # Reuse the biggest boom we have

	# Damage every enemy inside the blast radius
	var kills = 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= radius:
			var was_alive = enemy.health > 0
			var falloff = 1.0 - (dist / radius)
			enemy.take_damage(damage * falloff)
			if was_alive and enemy.health <= 0:
				kills += 1

	if kills >= 3:
		Achievements.unlock("grenade_master")

	queue_free()
