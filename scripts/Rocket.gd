extends Node3D

# -----------------------------------------------
# ROCKET
# Fired by the Rocket Launcher!
# Flies forward, then EXPLODES in a big area —
# damaging all enemies nearby. BOOM! 💥
# -----------------------------------------------

var speed: float    = 18.0
var damage: float   = 150.0
var direction: Vector3 = Vector3.ZERO
var fired_by: String   = "clones"
var shot_by            = null

# The explosion radius — everything inside this gets hurt!
const BLAST_RADIUS = 6.0

# Visual: a simple orange cylinder (the rocket body)
var _mesh: MeshInstance3D

func _ready():
	# Build a simple visual rocket from a cylinder + tiny sphere tip
	_mesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius    = 0.1
	cyl.bottom_radius = 0.15
	cyl.height        = 0.6
	_mesh.mesh = cyl
	var mat = StandardMaterial3D.new()
	mat.albedo_color      = Color(0.9, 0.4, 0.1)
	mat.emission_enabled  = true
	mat.emission          = Color(1.0, 0.3, 0.0)
	_mesh.set_surface_override_material(0, mat)
	add_child(_mesh)

	# Tilt the mesh to face the direction of travel
	if direction != Vector3.ZERO:
		look_at(global_position + direction, Vector3.UP)

	# Self-destruct after 4 seconds even if nothing hit
	await get_tree().create_timer(4.0).timeout
	if is_instance_valid(self):
		_explode()

func _process(delta):
	# Fly forward!
	position += direction * speed * delta
	# Leave a smoke trail
	Particles.bullet_trail(global_position, global_position + direction * 0.5)

func _explode():
	print("💥 ROCKET EXPLODES!")
	# Big orange explosion at the impact point
	Particles.death_explosion(global_position, Color(1.0, 0.5, 0.0))
	SoundManager.play("boom")

	# Damage all enemies caught in the blast radius
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist <= BLAST_RADIUS:
				# Closer = more damage (falls off with distance)
				var falloff = 1.0 - (dist / BLAST_RADIUS)
				enemy.take_damage(damage * falloff)

	queue_free()
