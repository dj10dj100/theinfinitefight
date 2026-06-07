extends StaticBody3D

# -----------------------------------------------
# DESTRUCTIBLE WALL 🏗
# Blocks bullets and clones.
# Rockets, grenades and airstrikes can blow it up!
# Health: 200. Turns red as it takes damage, then BOOM!
# -----------------------------------------------

var health: float = 200.0
var _mesh: MeshInstance3D

func _ready():
	add_to_group("destructible")
	_build_visual()

func _build_visual():
	_mesh = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(2.0, 1.5, 0.3)
	_mesh.mesh = bm
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.45, 0.32)   # Sandy/concrete colour
	mat.roughness    = 0.9
	_mesh.set_surface_override_material(0, mat)
	add_child(_mesh)

	var col = CollisionShape3D.new()
	col.shape = BoxShape3D.new()
	col.shape.size = Vector3(2.0, 1.5, 0.3)
	add_child(col)

func take_damage(amount: float):
	health -= amount
	# Flash red as it gets damaged
	var ratio = clamp(health / 200.0, 0.0, 1.0)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.55 + (1.0 - ratio) * 0.45, 0.45 * ratio, 0.32 * ratio)
	mat.roughness    = 0.9
	_mesh.set_surface_override_material(0, mat)

	if health <= 0:
		_explode()

func _explode():
	Particles.death_explosion(global_position + Vector3(0, 0.75, 0), Color(0.6, 0.5, 0.3))
	SoundManager.play("death")
	print("🏗 Wall destroyed!")
	queue_free()
