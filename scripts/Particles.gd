extends Node

# -----------------------------------------------
# PARTICLES
# Spawns visual effects anywhere in the game!
# Call these from any script like:
#   Particles.muzzle_flash(position, direction)
#   Particles.hit_sparks(position)
#   Particles.death_explosion(position, colour)
#   Particles.bullet_trail(start, end)
# -----------------------------------------------

# Spawn a muzzle flash at the tip of a gun
func muzzle_flash(pos: Vector3, dir: Vector3):
	var node = Node3D.new()
	node.position = pos
	get_tree().root.add_child(node)

	# Bright yellow-orange flash sphere
	var flash = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = 0.18
	sm.height = 0.36
	flash.mesh = sm
	var mat = StandardMaterial3D.new()
	mat.albedo_color     = Color(1.0, 0.85, 0.2)
	mat.emission_enabled = true
	mat.emission         = Color(1.0, 0.6, 0.0) * 3.0
	mat.shading_mode     = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash.set_surface_override_material(0, mat)
	node.add_child(flash)

	# Shoot out 6 tiny spark particles in a cone
	for i in range(6):
		var spark = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = Vector3(0.04, 0.04, 0.18)
		spark.mesh = bm
		var smat = StandardMaterial3D.new()
		smat.albedo_color     = Color(1.0, 0.9, 0.3)
		smat.emission_enabled = true
		smat.emission         = Color(1.0, 0.7, 0.1) * 2.0
		smat.shading_mode     = BaseMaterial3D.SHADING_MODE_UNSHADED
		spark.set_surface_override_material(0, smat)

		# Spread sparks in a rough cone around the shoot direction
		var spread = Vector3(randf_range(-0.4, 0.4), randf_range(-0.4, 0.4), randf_range(-0.4, 0.4))
		var spark_dir = (dir + spread).normalized()
		spark.position = spark_dir * randf_range(0.05, 0.22)
		node.add_child(spark)

		# Animate each spark flying outward and shrinking to nothing
		var tween = get_tree().create_tween()
		tween.tween_property(spark, "position", spark.position + spark_dir * 0.5, 0.12)
		tween.parallel().tween_property(spark, "scale", Vector3(0.01, 0.01, 0.01), 0.12)

	# Fade out the whole flash quickly
	var tween = get_tree().create_tween()
	tween.tween_property(node, "scale", Vector3(0.01, 0.01, 0.01), 0.10)
	tween.tween_callback(node.queue_free)

# Spawn hit sparks when a bullet hits something
func hit_sparks(pos: Vector3):
	var node = Node3D.new()
	node.position = pos
	get_tree().root.add_child(node)

	for i in range(8):
		var spark = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = Vector3(0.05, 0.05, 0.12)
		spark.mesh = bm
		var mat = StandardMaterial3D.new()
		mat.albedo_color     = Color(1.0, 0.7, 0.1)
		mat.emission_enabled = true
		mat.emission         = Color(1.0, 0.5, 0.0) * 1.8
		mat.shading_mode     = BaseMaterial3D.SHADING_MODE_UNSHADED
		spark.set_surface_override_material(0, mat)
		node.add_child(spark)

		var dir = Vector3(randf_range(-1,1), randf_range(0.2,1), randf_range(-1,1)).normalized()
		var tween = get_tree().create_tween()
		tween.tween_property(spark, "position", dir * randf_range(0.3, 0.8), 0.25)
		tween.parallel().tween_property(spark, "scale", Vector3(0.01, 0.01, 0.01), 0.25)

	var cleanup = get_tree().create_tween()
	cleanup.tween_interval(0.3)
	cleanup.tween_callback(node.queue_free)

# Death explosion — bigger burst of colour matching the dead soldier
func death_explosion(pos: Vector3, colour: Color):
	var node = Node3D.new()
	node.position = pos
	get_tree().root.add_child(node)

	# Central flash
	var flash = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = 0.4
	sm.height = 0.8
	flash.mesh = sm
	var fmat = StandardMaterial3D.new()
	fmat.albedo_color     = colour.lightened(0.4)
	fmat.emission_enabled = true
	fmat.emission         = colour * 1.5
	fmat.shading_mode     = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash.set_surface_override_material(0, fmat)
	node.add_child(flash)

	# Lots of flying chunks
	for i in range(14):
		var chunk = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = Vector3(randf_range(0.05,0.15), randf_range(0.05,0.15), randf_range(0.05,0.15))
		chunk.mesh = bm
		var cmat = StandardMaterial3D.new()
		cmat.albedo_color = colour.lerp(Color(0.8,0.8,0.8), randf_range(0.0, 0.4))
		cmat.roughness    = 0.8
		chunk.set_surface_override_material(0, cmat)
		node.add_child(chunk)

		var dir = Vector3(randf_range(-1,1), randf_range(0.5,1.5), randf_range(-1,1)).normalized()
		var dist = randf_range(0.5, 1.6)
		var tween = get_tree().create_tween()
		tween.tween_property(chunk, "position", dir * dist, 0.4)
		tween.parallel().tween_property(chunk, "scale", Vector3(0.01, 0.01, 0.01), 0.4)
		tween.parallel().tween_property(chunk, "rotation", Vector3(randf_range(0,6), randf_range(0,6), randf_range(0,6)), 0.4)

	# Expand and shrink the flash
	var tween = get_tree().create_tween()
	tween.tween_property(flash, "scale", Vector3(3.0, 3.0, 3.0), 0.25)
	tween.parallel().tween_property(flash, "scale", Vector3(0.01, 0.01, 0.01), 0.25)
	tween.tween_callback(node.queue_free)

# A glowing trail left behind by a bullet
func bullet_trail(start: Vector3, end: Vector3):
	var node = MeshInstance3D.new()
	var length = start.distance_to(end)
	var bm = BoxMesh.new()
	bm.size = Vector3(0.025, 0.025, length)
	node.mesh = bm
	var mat = StandardMaterial3D.new()
	mat.albedo_color     = Color(1.0, 0.95, 0.5, 0.7)
	mat.emission_enabled = true
	mat.emission         = Color(1.0, 0.8, 0.2) * 1.2
	mat.shading_mode     = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency     = BaseMaterial3D.TRANSPARENCY_ALPHA
	node.set_surface_override_material(0, mat)

	# Position and orient between start and end
	# Add to tree FIRST, then look_at (node must be in the tree to use look_at)
	node.position = (start + end) * 0.5
	get_tree().root.add_child(node)
	node.look_at_from_position(node.global_position, end, Vector3.UP)

	# Shrink to nothing quickly (modulate:a doesn't work on 3D nodes)
	var tween = get_tree().create_tween()
	tween.tween_property(node, "scale", Vector3(0.01, 0.01, 0.01), 0.08)
	tween.tween_callback(node.queue_free)
