extends CharacterBody3D

# -----------------------------------------------
# SIDEKICK DOG 🐕
# A loyal little dog that follows its clone owner
# and bites any enemy that gets too close!
# -----------------------------------------------

var owner_clone = null
var _bite_timer: float = 0.0
var _bob_time:   float = 0.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	_build_visual()

func _build_visual():
	# Body
	var body = MeshInstance3D.new()
	var bm   = BoxMesh.new()
	bm.size  = Vector3(0.32, 0.22, 0.45)
	body.mesh = bm
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.38, 0.20)   # Brown dog
	mat.roughness    = 0.9
	body.set_surface_override_material(0, mat)
	body.position = Vector3(0, 0.18, 0)
	add_child(body)

	# Head
	var head = MeshInstance3D.new()
	var hm   = BoxMesh.new()
	hm.size  = Vector3(0.22, 0.22, 0.22)
	head.mesh = hm
	head.set_surface_override_material(0, mat)
	head.position = Vector3(0, 0.28, -0.28)
	add_child(head)

	# Tail (little stick pointing up)
	var tail = MeshInstance3D.new()
	var tm   = BoxMesh.new()
	tm.size  = Vector3(0.05, 0.18, 0.05)
	tail.mesh = tm
	tail.set_surface_override_material(0, mat)
	tail.position = Vector3(0, 0.32, 0.24)
	tail.rotation.z = 0.5
	add_child(tail)

	# Collision
	var col = CollisionShape3D.new()
	col.shape = BoxShape3D.new()
	col.shape.size = Vector3(0.32, 0.28, 0.45)
	col.position = Vector3(0, 0.18, 0)
	add_child(col)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	_bite_timer -= delta
	_bob_time   += delta * 8.0

	if owner_clone == null or not is_instance_valid(owner_clone):
		queue_free()
		return

	# Follow the owner, staying slightly behind and to the side
	var follow_target = owner_clone.global_position + Vector3(0.6, 0, 0.5)
	var to_target = follow_target - global_position
	if to_target.length() > 0.5:
		var dir = to_target.normalized()
		velocity.x = dir.x * 5.5
		velocity.z = dir.z * 5.5
		look_at(owner_clone.global_position * Vector3(1, 0, 1) + Vector3(0, global_position.y, 0), Vector3.UP)
	else:
		velocity.x = move_toward(velocity.x, 0, 5.5)
		velocity.z = move_toward(velocity.z, 0, 5.5)

	# Bob up and down while running
	position.y += sin(_bob_time) * 0.01

	# Find and bite nearby enemies!
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist < 1.2 and _bite_timer <= 0:
				enemy.take_damage(18.0)
				_bite_timer = 1.8
				SoundManager.play("hit")
				print("🐕 WOOF! Dog bit an enemy!")

	move_and_slide()
