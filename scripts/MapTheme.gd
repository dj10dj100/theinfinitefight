extends Node

# -----------------------------------------------
# MAP THEME
# This script reads which map was chosen and
# changes the colours + decorations of the
# battlefield to match!
#
# Maps:
#   grassland — classic green field (default)
#   jungle    — dark green, trees and shadows
#   city      — grey concrete and rubble
#   snow      — white ground, pale blue sky
# -----------------------------------------------

# Map settings: ground colour, sky colour, light colour, fog colour
const MAP_DATA = {
	"grassland": {
		"ground":     Color(0.22, 0.45, 0.12),
		"sky":        Color(0.42, 0.62, 0.92),
		"light":      Color(1.0,  0.95, 0.85),
		"fog":        Color(0.55, 0.72, 0.90),
		"decoration": "trees",
		"name":       "🌿 Grassland"
	},
	"jungle": {
		"ground":     Color(0.10, 0.28, 0.06),
		"sky":        Color(0.10, 0.20, 0.10),
		"light":      Color(0.7,  0.9,  0.5),
		"fog":        Color(0.12, 0.25, 0.12),
		"decoration": "jungle_trees",
		"name":       "🌴 Jungle"
	},
	"city": {
		"ground":     Color(0.32, 0.32, 0.30),
		"sky":        Color(0.55, 0.55, 0.60),
		"light":      Color(0.85, 0.85, 0.90),
		"fog":        Color(0.50, 0.50, 0.55),
		"decoration": "rubble",
		"name":       "🏙 City"
	},
	"snow": {
		"ground":     Color(0.88, 0.92, 0.96),
		"sky":        Color(0.72, 0.82, 0.95),
		"light":      Color(0.90, 0.95, 1.0),
		"fog":        Color(0.80, 0.88, 0.96),
		"decoration": "snow_mounds",
		"name":       "❄️ Snow"
	},
}

# Apply the chosen theme to the battlefield
func apply(battlefield: Node3D):
	var map = GameManager.selected_map if GameManager else "grassland"
	var data = MAP_DATA.get(map, MAP_DATA["grassland"])

	print("Loading map: ", data["name"])

	# Colour the ground
	var ground = battlefield.get_node_or_null("Ground")
	if ground and ground is MeshInstance3D:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = data["ground"]
		mat.roughness = 0.9
		ground.set_surface_override_material(0, mat)

	# Colour the sky / world environment
	var world_env = battlefield.get_node_or_null("WorldEnvironment")
	if world_env == null:
		world_env = _create_world_env(battlefield)
	_set_sky_colour(world_env, data["sky"], data["fog"])

	# Colour the directional light
	var light = battlefield.get_node_or_null("WorldLight")
	if light and light is DirectionalLight3D:
		light.light_color = data["light"]

	# Spawn map decorations (trees, rubble, etc.)
	_spawn_decorations(battlefield, data["decoration"], data["ground"])

func _create_world_env(parent: Node3D) -> WorldEnvironment:
	var we = WorldEnvironment.new()
	we.name = "WorldEnvironment"
	var env = Environment.new()
	we.environment = env
	parent.add_child(we)
	return we

func _set_sky_colour(world_env: WorldEnvironment, sky_col: Color, fog_col: Color):
	if world_env.environment == null:
		world_env.environment = Environment.new()
	var env = world_env.environment
	env.background_mode = Environment.BG_COLOR
	env.background_color = sky_col
	env.fog_enabled = true
	env.fog_light_color = fog_col
	env.fog_density = 0.008
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = sky_col * 0.5
	env.ambient_light_energy = 0.6

func _spawn_decorations(parent: Node3D, style: String, ground_col: Color):
	# Place a handful of decorative objects around the edges of the field
	var positions = [
		Vector3(-18, 0, -14), Vector3(18, 0, -14),
		Vector3(-18, 0, 14),  Vector3(18, 0, 14),
		Vector3(0,   0, -15), Vector3(0,  0, 15),
		Vector3(-12, 0, -15), Vector3(12, 0, -15),
		Vector3(-12, 0, 15),  Vector3(12, 0, 15),
	]

	for pos in positions:
		match style:
			"trees", "jungle_trees":
				_spawn_tree(parent, pos, style == "jungle_trees")
			"rubble":
				_spawn_rubble(parent, pos)
			"snow_mounds":
				_spawn_snow_mound(parent, pos)

func _spawn_tree(parent: Node3D, pos: Vector3, jungle: bool):
	var node = Node3D.new()
	node.position = pos

	# Trunk
	var trunk = MeshInstance3D.new()
	var tm = CylinderMesh.new()
	tm.top_radius    = 0.12
	tm.bottom_radius = 0.18
	tm.height        = 1.8
	trunk.mesh = tm
	var trunk_mat = StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.32, 0.20, 0.08)
	trunk_mat.roughness = 0.9
	trunk.set_surface_override_material(0, trunk_mat)
	trunk.position.y = 0.9
	node.add_child(trunk)

	# Foliage
	var leaves = MeshInstance3D.new()
	var lm = SphereMesh.new()
	lm.radius = 1.2 if jungle else 0.95
	lm.height = 2.8 if jungle else 1.9
	leaves.mesh = lm
	var leaves_mat = StandardMaterial3D.new()
	leaves_mat.albedo_color = Color(0.05, 0.28, 0.04) if jungle else Color(0.15, 0.48, 0.10)
	leaves_mat.roughness = 1.0
	leaves.set_surface_override_material(0, leaves_mat)
	leaves.position.y = 2.6 if jungle else 2.1
	node.add_child(leaves)

	parent.add_child(node)

func _spawn_rubble(parent: Node3D, pos: Vector3):
	# A few grey broken-wall chunks
	for i in range(3):
		var chunk = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = Vector3(randf_range(0.4, 1.2), randf_range(0.3, 1.0), randf_range(0.4, 0.9))
		chunk.mesh = bm
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(randf_range(0.28, 0.42), randf_range(0.28, 0.42), randf_range(0.28, 0.42))
		mat.roughness = 0.95
		chunk.set_surface_override_material(0, mat)
		chunk.position = pos + Vector3(randf_range(-0.8, 0.8), bm.size.y * 0.5, randf_range(-0.8, 0.8))
		chunk.rotation.y = randf_range(0, PI * 2)
		parent.add_child(chunk)

func _spawn_snow_mound(parent: Node3D, pos: Vector3):
	var mound = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = randf_range(0.5, 1.0)
	sm.height = randf_range(0.4, 0.7)
	mound.mesh = sm
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.92, 0.95, 1.0)
	mat.roughness = 0.8
	mound.set_surface_override_material(0, mat)
	mound.position = pos + Vector3(0, sm.height * 0.3, 0)
	parent.add_child(mound)
