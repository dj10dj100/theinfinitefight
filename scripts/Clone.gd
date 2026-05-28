extends CharacterBody3D

# -----------------------------------------------
# ARMY CLONE
# Controls one of your army clones.
# When you're not in control → fights by itself (AI).
# When you click it → YOU take over in first-person!
# -----------------------------------------------

@export var weapon: String = "pistol"
@export var secondary_weapon: String = ""   # Only used by the Sniper clone!
@export var move_speed: float = 3.5
@export var health: float = 100.0
@export var shoot_range: float = 15.0

# Sniper clones can switch between their two weapons
var active_weapon: String = ""     # Which weapon is currently active

# Load the bullet scene so we can fire bullets!
var bullet_scene = preload("res://scenes/Bullet.tscn")

var is_player_controlled: bool = false
var shoot_timer: float = 0.0
var target_enemy = null
var mouse_sensitivity: float = 0.003
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Plastic colour — classic olive green toy soldier
const CLONE_COLOUR = Color(0.30, 0.38, 0.16)

# Stores all the mesh parts so we can flash them on hit
var body_parts: Array = []

# Shield — blocks this many hits before breaking
var shield_hits: int = 0

@onready var shoot_point = $ShootPoint
@onready var mesh_instance = $MeshInstance3D

func _ready():
	add_to_group("clones")

	active_weapon = weapon
	if weapon == "sniper":
		shoot_range = 30.0

	# Hide the plain capsule and build a proper plastic army man instead!
	mesh_instance.visible = false
	body_parts = ArmyManBuilder.build(self, CLONE_COLOUR)

# -----------------------------------------------
# Every frame — movement, shooting, AI
# -----------------------------------------------
func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	shoot_timer -= delta

	if is_player_controlled:
		handle_player_movement(delta)
	else:
		handle_ai(delta)

	move_and_slide()

# -----------------------------------------------
# Mouse look (only in first-person mode)
# -----------------------------------------------
func _input(event):
	if is_player_controlled and event is InputEventMouseMotion:
		# Rotate left/right with the mouse
		rotate_y(-event.relative.x * mouse_sensitivity)

	# Left-click to shoot in first-person
	if is_player_controlled and event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if shoot_timer <= 0:
				shoot()

	# Press R to swap weapons — sniper clones only!
	if is_player_controlled and event is InputEventKey:
		if event.pressed and event.keycode == KEY_R and secondary_weapon != "":
			swap_weapon()

# -----------------------------------------------
# PLAYER MOVEMENT (WASD or arrow keys)
# -----------------------------------------------
func handle_player_movement(delta):
	var direction = Vector3.ZERO
	if Input.is_action_pressed("ui_up"):    direction -= transform.basis.z
	if Input.is_action_pressed("ui_down"):  direction += transform.basis.z
	if Input.is_action_pressed("ui_left"):  direction -= transform.basis.x
	if Input.is_action_pressed("ui_right"): direction += transform.basis.x

	if direction != Vector3.ZERO:
		direction = direction.normalized()
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)

# -----------------------------------------------
# AI — finds an enemy and walks/shoots at them
# -----------------------------------------------
func handle_ai(delta):
	if target_enemy == null or not is_instance_valid(target_enemy):
		target_enemy = find_nearest_enemy()

	if target_enemy != null:
		var distance = global_position.distance_to(target_enemy.global_position)
		if distance <= shoot_range:
			# Face the enemy
			var look_target = target_enemy.global_position
			look_target.y = global_position.y  # Don't tilt up/down
			look_at(look_target, Vector3.UP)
			if shoot_timer <= 0:
				shoot()
		else:
			# Walk towards the enemy
			var dir = (target_enemy.global_position - global_position).normalized()
			velocity.x = dir.x * move_speed
			velocity.z = dir.z * move_speed

# -----------------------------------------------
# SHOOT — spawns a real bullet!
# -----------------------------------------------
func shoot():
	shoot_timer = get_shoot_cooldown()

	# Play the right gunshot sound for the weapon!
	SoundManager.play("shoot_" + active_weapon)

	var bullet = bullet_scene.instantiate()
	bullet.global_position = shoot_point.global_position
	bullet.direction = -shoot_point.global_transform.basis.z.normalized()
	bullet.damage = get_bullet_damage()
	bullet.fired_by = "clones"
	get_tree().root.add_child(bullet)

# Sniper clone swaps between sniper rifle and secondary weapon
func swap_weapon():
	if active_weapon == weapon:
		active_weapon = secondary_weapon
		shoot_range = 10.0   # Secondary weapon is close-range
	else:
		active_weapon = weapon
		shoot_range = 30.0   # Back to sniper range
	print("Switched to: ", active_weapon)

# How fast does this weapon fire?
func get_shoot_cooldown() -> float:
	match active_weapon:
		"pistol":        return 1.5
		"revolver":      return 2.0
		"shotgun":       return 2.2
		"assault_rifle": return 0.3
		"machine_gun":   return 0.15
		"sniper":        return 3.0
		_:               return 1.5

# How much damage does each weapon do per shot?
func get_bullet_damage() -> float:
	match active_weapon:
		"pistol":        return 20.0
		"revolver":      return 35.0
		"shotgun":       return 60.0
		"assault_rifle": return 15.0
		"machine_gun":   return 10.0
		"sniper":        return 90.0
		_:               return 20.0

# -----------------------------------------------
# FIND THE NEAREST ENEMY
# -----------------------------------------------
func find_nearest_enemy() -> Node:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest = null
	var nearest_dist = INF
	for enemy in enemies:
		var dist = global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	return nearest

# -----------------------------------------------
# TAKING DAMAGE
# -----------------------------------------------
func activate_shield(hits: int):
	shield_hits = hits
	# Flash gold to show the shield is active
	var shield_mat = StandardMaterial3D.new()
	shield_mat.albedo_color = Color(1.0, 0.85, 0.0)
	shield_mat.emission_enabled = true
	shield_mat.emission = Color(0.8, 0.6, 0.0)
	shield_mat.roughness = 0.1
	for part in body_parts:
		if is_instance_valid(part):
			part.set_surface_override_material(0, shield_mat)

func take_damage(amount: float):
	# Shield blocks the hit!
	if shield_hits > 0:
		shield_hits -= 1
		SoundManager.play("click")
		print("🛡 Shield blocked the hit! ", shield_hits, " blocks left.")
		# If shield just ran out, restore normal colour
		if shield_hits == 0:
			var normal_mat = StandardMaterial3D.new()
			normal_mat.albedo_color = CLONE_COLOUR
			normal_mat.roughness = 0.28
			for part in body_parts:
				if is_instance_valid(part):
					part.set_surface_override_material(0, normal_mat)
		return

	health -= amount
	SoundManager.play("hit")
	print("Clone hit! Health left: ", health)

	# Flash all parts white, then restore the olive green
	var white_mat = StandardMaterial3D.new()
	white_mat.albedo_color = Color(1, 1, 1)
	white_mat.roughness = 0.28
	var normal_mat = StandardMaterial3D.new()
	normal_mat.albedo_color = CLONE_COLOUR
	normal_mat.roughness = 0.28

	for part in body_parts:
		if is_instance_valid(part):
			part.set_surface_override_material(0, white_mat)
	await get_tree().create_timer(0.1).timeout
	for part in body_parts:
		if is_instance_valid(part):
			part.set_surface_override_material(0, normal_mat)

	if health <= 0:
		die()

func die():
	print("A clone has fallen!")
	SoundManager.play("death")
	get_parent().on_clone_died(self)
	queue_free()

# -----------------------------------------------
# TAKE / RELEASE PLAYER CONTROL
# -----------------------------------------------
func take_player_control():
	is_player_controlled = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)  # Hide + lock mouse for first-person
	get_tree().call_group("battlefield", "enter_first_person", self)
	print("You are now controlling the ", weapon, " clone!")

func release_player_control():
	is_player_controlled = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)   # Show mouse again
	get_tree().call_group("battlefield", "exit_first_person")
