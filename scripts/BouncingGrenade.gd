extends Node3D

# -----------------------------------------------
# BOUNCING GRENADE
# Fired by the Grenade Launcher!
# It bounces along the ground a couple of times,
# then EXPLODES — damaging everything nearby! 💣
# -----------------------------------------------

var velocity_vec: Vector3 = Vector3.ZERO
var damage: float = 100.0
var fired_by: String = "clones"

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var bounces: int = 0
const MAX_BOUNCES = 2
const BLAST_RADIUS = 5.0
const FLOOR_Y = 0.3

var _exploded: bool = false

# Visual: a small green sphere
var _mesh: MeshInstance3D

func _ready():
	_mesh = MeshInstance3D.new()
	var sph = SphereMesh.new()
	sph.radius = 0.18
	sph.height = 0.36
	_mesh.mesh = sph
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.7, 0.2)
	_mesh.set_surface_override_material(0, mat)
	add_child(_mesh)

	# Safety fuse — explodes after 2.5 seconds no matter what
	await get_tree().create_timer(2.5).timeout
	if is_instance_valid(self) and not _exploded:
		_explode()

func _process(delta):
	if _exploded:
		return

	# Apply gravity
	velocity_vec.y -= gravity * delta
	position += velocity_vec * delta

	# Spin the grenade as it flies — looks cool!
	_mesh.rotate_x(delta * 8.0)

	# Bounce off the floor
	if global_position.y <= FLOOR_Y and velocity_vec.y < 0:
		velocity_vec.y = abs(velocity_vec.y) * 0.55   # Bounce up with less energy
		velocity_vec.x *= 0.75
		velocity_vec.z *= 0.75
		bounces += 1
		SoundManager.play("click")
		if bounces >= MAX_BOUNCES:
			_explode()

func _explode():
	if _exploded:
		return
	_exploded = true

	print("💣 GRENADE LAUNCHER — BOOM!")
	Particles.death_explosion(global_position, Color(0.2, 0.8, 0.2))
	SoundManager.play("boom")

	# Damage all enemies in the blast zone
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			if global_position.distance_to(enemy.global_position) <= BLAST_RADIUS:
				enemy.take_damage(damage)

	queue_free()
