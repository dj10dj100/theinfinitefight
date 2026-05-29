extends StaticBody3D

# -----------------------------------------------
# TRAP / BARRIER
# Can be a Wall (blocks movement) or
# a Spike Trap (hurts enemies that walk over it).
# Placed on the deploy screen before battle.
# -----------------------------------------------

@export var trap_type: String = "wall"  # "wall" or "spikes"

var _spike_timer: float = 0.0

func _ready():
	add_to_group("traps")
	_build_visuals()

	if trap_type == "spikes":
		# Spikes use an Area3D to detect enemies walking over them
		var area = Area3D.new()
		var shape = CollisionShape3D.new()
		shape.shape = BoxShape3D.new()
		shape.shape.size = Vector3(1.8, 0.4, 1.8)
		area.add_child(shape)
		area.body_entered.connect(_on_spike_triggered)
		add_child(area)

func _build_visuals():
	match trap_type:
		"wall":
			# A tall solid wall — dark grey
			var mesh = MeshInstance3D.new()
			mesh.mesh = BoxMesh.new()
			mesh.mesh.size = Vector3(2.0, 1.8, 0.3)
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.25, 0.25, 0.28)
			mat.roughness = 0.8
			mesh.set_surface_override_material(0, mat)
			add_child(mesh)

			# Collision shape for the wall
			var col = CollisionShape3D.new()
			col.shape = BoxShape3D.new()
			col.shape.size = Vector3(2.0, 1.8, 0.3)
			add_child(col)

		"spikes":
			# Low flat base with pointy spikes sticking up — danger red
			var base = MeshInstance3D.new()
			base.mesh = BoxMesh.new()
			base.mesh.size = Vector3(1.8, 0.1, 1.8)
			var bmat = StandardMaterial3D.new()
			bmat.albedo_color = Color(0.3, 0.0, 0.0)
			bmat.roughness = 0.6
			base.set_surface_override_material(0, bmat)
			add_child(base)

			# Five spike cones
			for sx in [-0.5, 0.0, 0.5]:
				for sz in [-0.5, 0.5]:
					var spike = MeshInstance3D.new()
					spike.mesh = CylinderMesh.new()
					spike.mesh.top_radius    = 0.0
					spike.mesh.bottom_radius = 0.08
					spike.mesh.height        = 0.45
					var smat = StandardMaterial3D.new()
					smat.albedo_color = Color(0.7, 0.7, 0.75)
					smat.roughness = 0.2
					spike.set_surface_override_material(0, smat)
					spike.position = Vector3(sx, 0.27, sz)
					add_child(spike)

			# Low collision just for physics
			var col = CollisionShape3D.new()
			col.shape = BoxShape3D.new()
			col.shape.size = Vector3(1.8, 0.1, 1.8)
			add_child(col)

func _on_spike_triggered(body):
	if body.is_in_group("enemies"):
		body.take_damage(40.0)
		print("⚠ Enemy hit spikes!")
