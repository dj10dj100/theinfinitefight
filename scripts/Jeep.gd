extends CharacterBody3D

# -----------------------------------------------
# JEEP
# A driveable vehicle on the battlefield!
# Click it from top-down view to get in.
# WASD to drive, mouse to aim the cannon,
# left-click to fire.  ESC to get out.
# Runs over enemies for instant damage!
# -----------------------------------------------

@export var drive_speed: float  = 8.0
@export var turn_speed: float   = 2.5
@export var cannon_damage: float = 80.0
@export var health: float = 300.0

var is_player_driven: bool = false
var shoot_timer: float = 0.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Body parts for tinting on hit
var body_parts: Array = []

func _ready():
	add_to_group("jeep")
	_build_jeep_visuals()

	# Damage enemies we drive over
	var area = Area3D.new()
	var shape = CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = Vector3(1.8, 0.5, 3.0)
	shape.position = Vector3(0, 0.3, 0)
	area.add_child(shape)
	area.body_entered.connect(_on_ran_over)
	add_child(area)

func _build_jeep_visuals():
	# Main body — olive green box
	var body = MeshInstance3D.new()
	body.mesh = BoxMesh.new()
	body.mesh.size = Vector3(1.6, 0.5, 2.8)
	var bmat = StandardMaterial3D.new()
	bmat.albedo_color = Color(0.28, 0.35, 0.14)
	bmat.roughness = 0.7
	body.set_surface_override_material(0, bmat)
	body.position = Vector3(0, 0.5, 0)
	add_child(body)
	body_parts.append(body)

	# Cab / windscreen
	var cab = MeshInstance3D.new()
	cab.mesh = BoxMesh.new()
	cab.mesh.size = Vector3(1.4, 0.5, 1.2)
	var cmat = StandardMaterial3D.new()
	cmat.albedo_color = Color(0.25, 0.32, 0.12)
	cmat.roughness = 0.5
	cab.set_surface_override_material(0, cmat)
	cab.position = Vector3(0, 1.0, -0.3)
	add_child(cab)

	# Four wheels
	var wheel_positions = [
		Vector3( 0.9, 0.2,  1.0),
		Vector3(-0.9, 0.2,  1.0),
		Vector3( 0.9, 0.2, -1.0),
		Vector3(-0.9, 0.2, -1.0),
	]
	for wp in wheel_positions:
		var wheel = MeshInstance3D.new()
		wheel.mesh = CylinderMesh.new()
		wheel.mesh.top_radius    = 0.32
		wheel.mesh.bottom_radius = 0.32
		wheel.mesh.height        = 0.22
		var wmat = StandardMaterial3D.new()
		wmat.albedo_color = Color(0.12, 0.12, 0.12)
		wmat.roughness = 0.9
		wheel.set_surface_override_material(0, wmat)
		wheel.position = wp
		wheel.rotation.z = PI / 2.0
		add_child(wheel)

	# Cannon on top
	var cannon = MeshInstance3D.new()
	cannon.name = "Cannon"
	cannon.mesh = CylinderMesh.new()
	cannon.mesh.top_radius    = 0.06
	cannon.mesh.bottom_radius = 0.1
	cannon.mesh.height        = 1.0
	var cnmat = StandardMaterial3D.new()
	cnmat.albedo_color = Color(0.15, 0.15, 0.15)
	cannon.set_surface_override_material(0, cnmat)
	cannon.position = Vector3(0, 1.35, 0.2)
	cannon.rotation.x = -PI / 6.0   # Tilted forward a bit
	add_child(cannon)

	# "ENTER" label above the jeep (shown before player enters)
	var label_canvas = CanvasLayer.new()
	label_canvas.name = "EnterHint"
	# We'll handle hints via printing for now

	# Main collision shape
	var col = CollisionShape3D.new()
	col.shape = BoxShape3D.new()
	col.shape.size = Vector3(1.6, 0.9, 2.8)
	col.position = Vector3(0, 0.5, 0)
	add_child(col)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	shoot_timer -= delta

	if is_player_driven:
		_handle_driving(delta)
	else:
		# Slow to a stop when no one is driving
		velocity.x = move_toward(velocity.x, 0, drive_speed)
		velocity.z = move_toward(velocity.z, 0, drive_speed)

	move_and_slide()

func _handle_driving(delta):
	var forward = -global_transform.basis.z

	# Forward / backward
	if Input.is_action_pressed("ui_up"):
		velocity.x = forward.x * drive_speed
		velocity.z = forward.z * drive_speed
	elif Input.is_action_pressed("ui_down"):
		velocity.x = -forward.x * drive_speed * 0.6
		velocity.z = -forward.z * drive_speed * 0.6
	else:
		velocity.x = move_toward(velocity.x, 0, drive_speed)
		velocity.z = move_toward(velocity.z, 0, drive_speed)

	# Turn left / right
	if Input.is_action_pressed("ui_left"):
		rotate_y(turn_speed * delta)
	if Input.is_action_pressed("ui_right"):
		rotate_y(-turn_speed * delta)

func _input(event):
	if not is_player_driven:
		return

	# Click to fire the cannon
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if shoot_timer <= 0:
			_fire_cannon()

	# ESC to get out
	if event.is_action_pressed("ui_cancel"):
		exit_jeep()

func _fire_cannon():
	shoot_timer = 2.0
	SoundManager.play("shoot_shotgun")
	var cannon = get_node_or_null("Cannon")
	if cannon == null:
		return
	var fire_dir = -global_transform.basis.z.normalized()
	Particles.muzzle_flash(cannon.global_position, fire_dir)

	# Cannonball — a fast heavy bullet
	var bullet = load("res://scenes/Bullet.tscn").instantiate()
	bullet.global_position = cannon.global_position
	bullet.direction = fire_dir
	bullet.damage = cannon_damage
	bullet.fired_by = "clones"
	bullet.speed = 30.0
	get_tree().root.add_child(bullet)
	print("💥 BOOM! Cannon fired!")

func _on_ran_over(body):
	if body.is_in_group("enemies") and is_player_driven:
		body.take_damage(60.0)
		print("🚗 Ran over an enemy!")

func enter_jeep():
	is_player_driven = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	print("🚗 You're driving the jeep! WASD = drive, click = fire cannon, ESC = get out")

func exit_jeep():
	is_player_driven = false
	print("Got out of the jeep.")

func take_damage(amount: float):
	health -= amount
	SoundManager.play("hit")
	if health <= 0:
		_explode_jeep()

func _explode_jeep():
	Particles.death_explosion(global_position + Vector3(0, 0.5, 0), Color(0.8, 0.4, 0.0))
	SoundManager.play("death")
	queue_free()
