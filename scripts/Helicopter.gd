extends CharacterBody3D

# -----------------------------------------------
# HELICOPTER 🚁
# A flyable helicopter on the battlefield!
# Walk up to it and press E to get in.
# Once inside, you fly it yourself!
#
# CONTROLS (when flying):
#   W / S        — fly forward / backward
#   A / D        — strafe left / right
#   SPACE        — fly up
#   LEFT SHIFT   — fly down
#   MOUSE        — look around
#   LEFT CLICK   — shoot from the helicopter!
#   E            — get out (lands you nearby)
# -----------------------------------------------

const FLY_SPEED    = 8.0
const VERTICAL_SPEED = 5.0
const ENTER_RANGE  = 3.5    # How close you need to be to press E

var is_player_in  : bool = false
var mouse_sensitivity: float = 0.003
var pilot_clone           = null   # The clone that climbed in
var _rotor_angle: float   = 0.0
var _shoot_timer: float   = 0.0

# Body parts built in _ready
var _body: MeshInstance3D
var _rotor: MeshInstance3D
var _tail_rotor: MeshInstance3D

# A bullet scene for shooting
var bullet_scene = preload("res://scenes/Bullet.tscn")

func _ready():
	add_to_group("helicopter")
	_build_visual()
	print("🚁 Helicopter is ready! Walk up and press E to get in.")

# -----------------------------------------------
# Build the helicopter from basic shapes
# -----------------------------------------------
func _build_visual():
	# Main body — a wide flat box
	_body = MeshInstance3D.new()
	var body_mesh = BoxMesh.new()
	body_mesh.size = Vector3(1.8, 0.6, 3.0)
	_body.mesh = body_mesh
	var body_mat = StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.2, 0.5, 0.2)   # Army green
	body_mat.roughness = 0.4
	_body.set_surface_override_material(0, body_mat)
	_body.position = Vector3(0, 0.3, 0)
	add_child(_body)

	# Tail boom — a thin box sticking out the back
	var tail = MeshInstance3D.new()
	var tail_mesh = BoxMesh.new()
	tail_mesh.size = Vector3(0.3, 0.3, 2.0)
	tail.mesh = tail_mesh
	tail.set_surface_override_material(0, body_mat)
	tail.position = Vector3(0, 0.3, 2.2)
	add_child(tail)

	# Main rotor — a long thin spinning bar on top
	_rotor = MeshInstance3D.new()
	var rotor_mesh = BoxMesh.new()
	rotor_mesh.size = Vector3(4.0, 0.06, 0.2)
	_rotor.mesh = rotor_mesh
	var rotor_mat = StandardMaterial3D.new()
	rotor_mat.albedo_color = Color(0.15, 0.15, 0.15)
	_rotor.set_surface_override_material(0, rotor_mat)
	_rotor.position = Vector3(0, 0.65, 0)
	add_child(_rotor)

	# Tail rotor — a small spinning disc on the side of the tail
	_tail_rotor = MeshInstance3D.new()
	var tr_mesh = BoxMesh.new()
	tr_mesh.size = Vector3(0.06, 0.8, 0.12)
	_tail_rotor.mesh = tr_mesh
	_tail_rotor.set_surface_override_material(0, rotor_mat)
	_tail_rotor.position = Vector3(0.22, 0.35, 3.1)
	add_child(_tail_rotor)

	# Landing skids — two thin bars under the body
	for side in [-0.7, 0.7]:
		var skid = MeshInstance3D.new()
		var skid_mesh = BoxMesh.new()
		skid_mesh.size = Vector3(0.08, 0.08, 2.4)
		skid.mesh = skid_mesh
		skid.set_surface_override_material(0, rotor_mat)
		skid.position = Vector3(side, -0.05, 0)
		add_child(skid)

	# Collision shape so the player can walk up to it
	var col = CollisionShape3D.new()
	col.shape = BoxShape3D.new()
	col.shape.size = Vector3(1.8, 1.0, 3.0)
	col.position = Vector3(0, 0.3, 0)
	add_child(col)

# -----------------------------------------------
# Every frame
# -----------------------------------------------
func _physics_process(delta):
	# Spin the rotors!
	_rotor_angle += delta * (20.0 if is_player_in else 5.0)
	_rotor.rotation.y      =  _rotor_angle
	_tail_rotor.rotation.z = -_rotor_angle * 3.0

	_shoot_timer -= delta

	if is_player_in:
		_handle_flying(delta)
	else:
		# Sit on the ground — apply gravity so it doesn't float
		if not is_on_floor():
			velocity.y -= 9.8 * delta
		else:
			velocity = Vector3.ZERO
		move_and_slide()

func _handle_flying(delta):
	var direction = Vector3.ZERO

	if Input.is_action_pressed("ui_up"):    direction -= transform.basis.z
	if Input.is_action_pressed("ui_down"):  direction += transform.basis.z
	if Input.is_action_pressed("ui_left"):  direction -= transform.basis.x
	if Input.is_action_pressed("ui_right"): direction += transform.basis.x

	if direction != Vector3.ZERO:
		direction = direction.normalized()
	velocity.x = direction.x * FLY_SPEED
	velocity.z = direction.z * FLY_SPEED

	# Up and down with Space / Shift
	if Input.is_key_pressed(KEY_SPACE):
		velocity.y = VERTICAL_SPEED
	elif Input.is_key_pressed(KEY_SHIFT):
		velocity.y = -VERTICAL_SPEED
	else:
		velocity.y = move_toward(velocity.y, 0, VERTICAL_SPEED * delta * 4.0)

	# Don't fall through the ground!
	if global_position.y < 0.5 and velocity.y < 0:
		velocity.y = 0

	move_and_slide()

func _input(event):
	# Mouse look while flying
	if is_player_in and event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)

	# Shoot while flying!
	if is_player_in and event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if _shoot_timer <= 0:
				_shoot()

	# Press E — get in or get out
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		if is_player_in:
			_exit_helicopter()
		else:
			_try_enter_helicopter()

# -----------------------------------------------
# Enter / Exit
# -----------------------------------------------
func _try_enter_helicopter():
	# Find the player-controlled clone
	for clone in get_tree().get_nodes_in_group("clones"):
		if clone.is_player_controlled:
			var dist = global_position.distance_to(clone.global_position)
			if dist <= ENTER_RANGE:
				_enter_helicopter(clone)
				return
	print("🚁 You need to walk closer to the helicopter first!")

func _enter_helicopter(clone):
	pilot_clone     = clone
	is_player_in    = true
	clone.is_player_controlled = false   # Clone goes on autopilot
	clone.visible   = false              # Hide the clone (they're inside!)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	print("🚁 You jumped in the helicopter! WASD to fly, SPACE=up, SHIFT=down, E=exit")

func _exit_helicopter():
	is_player_in = false
	if pilot_clone and is_instance_valid(pilot_clone):
		# Drop the pilot out next to the helicopter
		pilot_clone.global_position = global_position + Vector3(2.5, 0, 0)
		pilot_clone.visible         = true
		pilot_clone.is_player_controlled = true
		pilot_clone = null
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	print("🚁 You jumped out of the helicopter!")

# -----------------------------------------------
# Shoot from the helicopter
# -----------------------------------------------
func _shoot():
	_shoot_timer = 0.4   # One shot every 0.4 seconds from the heli-gun

	var shoot_dir = -global_transform.basis.z.normalized()

	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position + Vector3(0, 0.3, -1.5)
	bullet.direction = shoot_dir + Vector3(0, -0.15, 0)   # Aim slightly downward
	bullet.damage    = 40.0
	bullet.fired_by  = "clones"
	bullet.speed     = 30.0
	get_tree().root.add_child(bullet)

	Particles.muzzle_flash(bullet.global_position, shoot_dir)
	SoundManager.play("shoot_assault_rifle")
