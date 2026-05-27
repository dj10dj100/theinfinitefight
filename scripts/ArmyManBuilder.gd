extends Node

# -----------------------------------------------
# ARMY MAN BUILDER
# Builds the classic plastic toy soldier look
# entirely from primitive shapes in code.
#
# Shape breakdown (Y = height from feet):
#   Base disc    — the flat oval they stand on
#   Legs         — lower body capsule
#   Torso        — wider upper body
#   Head         — sphere
#   Helmet       — flat disc on top of head
#   Right arm    — cylinder angling forward
#   Left arm     — cylinder angling forward
#   Right hand   — small sphere gripping the gun
#   Left hand    — small sphere gripping the gun
#   Gun stock    — thick back part of the rifle
#   Gun body     — main rifle body
#   Gun barrel   — long thin front of the rifle
# -----------------------------------------------

static func build(parent: Node3D, colour: Color) -> Array:
	var parts: Array = []

	# Plastic body material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness    = 0.28
	mat.metallic     = 0.0

	# Gun is always dark grey — like a real toy rifle
	var gun_mat = StandardMaterial3D.new()
	gun_mat.albedo_color = Color(0.18, 0.18, 0.18)
	gun_mat.roughness    = 0.35
	gun_mat.metallic     = 0.1

	# ---- BASE DISC ----
	parts.append(_add_cylinder(parent, mat,
		Vector3(0, 0.035, 0),   Vector3(0,0,0),
		0.26, 0.26, 0.07, 16))

	# ---- LEGS ----
	parts.append(_add_capsule(parent, mat,
		Vector3(0, 0.42, 0),    Vector3(0,0,0),
		0.18, 0.55))

	# ---- TORSO ----
	parts.append(_add_capsule(parent, mat,
		Vector3(0, 0.88, 0),    Vector3(0,0,0),
		0.23, 0.45))

	# ---- HEAD ----
	parts.append(_add_sphere(parent, mat,
		Vector3(0, 1.32, 0),
		0.185))

	# ---- HELMET ----
	# Squashed sphere sitting on top of the head
	var helmet_mesh = SphereMesh.new()
	helmet_mesh.radius = 0.21
	helmet_mesh.height = 0.20
	var helmet = MeshInstance3D.new()
	helmet.mesh = helmet_mesh
	helmet.set_surface_override_material(0, mat)
	helmet.position = Vector3(0, 1.50, 0)
	parent.add_child(helmet)
	parts.append(helmet)

	# ---- RIGHT ARM ----
	# Angles forward from the right shoulder toward the gun
	parts.append(_add_cylinder(parent, mat,
		Vector3(0.20, 1.02, -0.12),  Vector3(40, 0, -20),
		0.065, 0.065, 0.30, 8))

	# ---- LEFT ARM ----
	# Mirrors the right — both arms reach forward to grip the rifle
	parts.append(_add_cylinder(parent, mat,
		Vector3(-0.20, 1.02, -0.12), Vector3(40, 0, 20),
		0.065, 0.065, 0.30, 8))

	# ---- RIGHT HAND ----
	parts.append(_add_sphere(parent, mat,
		Vector3(0.12, 0.88, -0.32), 0.075))

	# ---- LEFT HAND ----
	parts.append(_add_sphere(parent, mat,
		Vector3(-0.12, 0.88, -0.32), 0.075))

	# ---- GUN STOCK (back/thick part of the rifle) ----
	parts.append(_add_cylinder(parent, gun_mat,
		Vector3(0, 0.88, -0.08),  Vector3(90, 0, 0),
		0.075, 0.075, 0.18, 8))

	# ---- GUN BODY (middle section) ----
	parts.append(_add_cylinder(parent, gun_mat,
		Vector3(0, 0.90, -0.30),  Vector3(90, 0, 0),
		0.060, 0.060, 0.24, 8))

	# ---- GUN BARREL (long thin front) ----
	parts.append(_add_cylinder(parent, gun_mat,
		Vector3(0, 0.91, -0.54),  Vector3(90, 0, 0),
		0.030, 0.030, 0.28, 8))

	return parts

# -----------------------------------------------
# HELPER FUNCTIONS — add a shape and return it
# -----------------------------------------------
static func _add_cylinder(parent, mat, pos, rot_deg, top_r, bot_r, h, segs) -> MeshInstance3D:
	var mesh = CylinderMesh.new()
	mesh.top_radius    = top_r
	mesh.bottom_radius = bot_r
	mesh.height        = h
	mesh.radial_segments = segs
	var node = MeshInstance3D.new()
	node.mesh = mesh
	node.set_surface_override_material(0, mat)
	node.position        = pos
	node.rotation_degrees = rot_deg
	parent.add_child(node)
	return node

static func _add_capsule(parent, mat, pos, rot_deg, radius, height) -> MeshInstance3D:
	var mesh = CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	var node = MeshInstance3D.new()
	node.mesh = mesh
	node.set_surface_override_material(0, mat)
	node.position        = pos
	node.rotation_degrees = rot_deg
	parent.add_child(node)
	return node

static func _add_sphere(parent, mat, pos, radius) -> MeshInstance3D:
	var mesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	var node = MeshInstance3D.new()
	node.mesh = mesh
	node.set_surface_override_material(0, mat)
	node.position = pos
	parent.add_child(node)
	return node
