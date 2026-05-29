extends CharacterBody3D

# -----------------------------------------------
# ENEMY (The Rogue Clone)
# Walks towards your clones and shoots at them.
# Made RED so you can tell them apart!
# Now with SMARTER AI — they take cover and flank!
# -----------------------------------------------

@export var weapon: String = "pistol"
@export var move_speed: float = 3.0
@export var health: float = 200.0
@export var shoot_range: float = 12.0

var bullet_scene = preload("res://scenes/Bullet.tscn")

var shoot_timer: float = 0.0
var target_clone = null
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Plastic colour — dark muddy tan for the Rogue army
const ENEMY_COLOUR = Color(0.42, 0.30, 0.16)

var body_parts: Array = []

# -----------------------------------------------
# SMART AI VARIABLES
# -----------------------------------------------
var ai_state: String = "advance"   # "advance", "cover", "flank", "shoot"
var _ai_timer: float  = 0.0        # How long to stay in current state
var _cover_pos: Vector3 = Vector3.ZERO   # Where we're hiding
var _flank_dir: float   = 1.0           # +1 or -1 for flank direction

@onready var shoot_point = $ShootPoint
@onready var mesh_instance = $MeshInstance3D

func _ready():
	add_to_group("enemies")

	# Hide the plain capsule and build a Rogue army man!
	mesh_instance.visible = false
	body_parts = ArmyManBuilder.build(self, ENEMY_COLOUR)

	# Randomise the starting flank direction so not all enemies go the same way
	_flank_dir = 1.0 if randf() > 0.5 else -1.0
	# Stagger AI so enemies don't all act in sync
	_ai_timer = randf_range(0.0, 2.0)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	shoot_timer -= delta
	_ai_timer   -= delta

	if target_clone == null or not is_instance_valid(target_clone):
		target_clone = find_nearest_clone()

	if target_clone != null:
		_run_smart_ai(delta)

	move_and_slide()

# -----------------------------------------------
# SMART AI — switches between states
# -----------------------------------------------
func _run_smart_ai(delta):
	var dist = global_position.distance_to(target_clone.global_position)

	# Pick a new state when the timer runs out
	if _ai_timer <= 0:
		_pick_new_state(dist)

	match ai_state:
		"advance":
			# Walk straight at the target
			var dir = (target_clone.global_position - global_position).normalized()
			velocity.x = dir.x * move_speed
			velocity.z = dir.z * move_speed
			_face_target()
			if dist <= shoot_range and shoot_timer <= 0:
				shoot()

		"cover":
			# Move to the cover position, then crouch and shoot
			var to_cover = (_cover_pos - global_position)
			if to_cover.length() > 1.0:
				var dir = to_cover.normalized()
				velocity.x = dir.x * move_speed
				velocity.z = dir.z * move_speed
			else:
				# At cover — stop and shoot from here
				velocity.x = move_toward(velocity.x, 0, move_speed)
				velocity.z = move_toward(velocity.z, 0, move_speed)
				_face_target()
				if dist <= shoot_range and shoot_timer <= 0:
					shoot()

		"flank":
			# Strafe sideways to get around the side of the target
			var to_target = (target_clone.global_position - global_position).normalized()
			# Rotate 90 degrees for the flank direction
			var flank = Vector3(to_target.z * _flank_dir, 0, -to_target.x * _flank_dir)
			# Still move a bit forward while flanking
			var move_dir = (to_target * 0.4 + flank * 0.6).normalized()
			velocity.x = move_dir.x * move_speed
			velocity.z = move_dir.z * move_speed
			_face_target()
			if dist <= shoot_range and shoot_timer <= 0:
				shoot()

		"shoot":
			# Stand still and fire repeatedly
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)
			_face_target()
			if dist <= shoot_range and shoot_timer <= 0:
				shoot()
			elif dist > shoot_range:
				# Target moved away — go back to advancing
				ai_state = "advance"
				_ai_timer = 1.5

func _pick_new_state(dist: float):
	# Use a random roll + distance to pick a smart state
	var roll = randf()

	if dist > shoot_range + 3.0:
		# Far away — always advance
		ai_state = "advance"
		_ai_timer = randf_range(1.5, 3.0)
	elif roll < 0.30:
		# 30% chance: take cover (pick a spot slightly to the side and behind)
		ai_state = "cover"
		_ai_timer = randf_range(2.0, 4.0)
		var side = Vector3(randf_range(-4.0, 4.0), 0, randf_range(-2.0, 2.0))
		_cover_pos = global_position + side
		_cover_pos.y = 0.1
	elif roll < 0.55:
		# 25% chance: flank!
		ai_state = "flank"
		_ai_timer = randf_range(1.5, 2.5)
		_flank_dir = 1.0 if randf() > 0.5 else -1.0
	else:
		# 45% chance: just stop and shoot
		ai_state = "shoot"
		_ai_timer = randf_range(1.0, 2.5)

func _face_target():
	if target_clone == null or not is_instance_valid(target_clone):
		return
	var look_pos = target_clone.global_position
	look_pos.y = global_position.y
	look_at(look_pos, Vector3.UP)

# -----------------------------------------------
# SHOOT — fires a real bullet at your clone!
# -----------------------------------------------
func shoot():
	shoot_timer = 1.8  # Enemies fire a bit slower than your clones

	SoundManager.play("shoot_" + weapon, -4.0)
	var shoot_dir = -shoot_point.global_transform.basis.z.normalized()
	Particles.muzzle_flash(shoot_point.global_position, shoot_dir)

	var bullet = bullet_scene.instantiate()
	bullet.global_position = shoot_point.global_position
	bullet.direction = -shoot_point.global_transform.basis.z.normalized()
	bullet.damage = 20.0
	bullet.fired_by = "enemies"  # So it only hurts clones!
	get_tree().root.add_child(bullet)

func find_nearest_clone() -> Node:
	var clones = get_tree().get_nodes_in_group("clones")
	var nearest = null
	var nearest_dist = INF
	for clone in clones:
		var dist = global_position.distance_to(clone.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = clone
	return nearest

# -----------------------------------------------
# TAKING DAMAGE
# -----------------------------------------------
func take_damage(amount: float):
	health -= amount
	SoundManager.play("hit")
	print("Enemy hit! Health left: ", health)

	# Flash all parts white, then restore the tan colour
	var white_mat = StandardMaterial3D.new()
	white_mat.albedo_color = Color(1, 1, 1)
	white_mat.roughness = 0.28
	var normal_mat = StandardMaterial3D.new()
	normal_mat.albedo_color = ENEMY_COLOUR
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
	print("An enemy has been defeated!")
	SoundManager.play("death")
	Particles.death_explosion(global_position + Vector3(0, 0.8, 0), ENEMY_COLOUR)

	# Drop a coin!
	var coin = Area3D.new()
	coin.set_script(load("res://scripts/BattleCoin.gd"))
	coin.global_position = global_position + Vector3(randf_range(-0.5, 0.5), 0.3, randf_range(-0.5, 0.5))
	get_tree().root.add_child(coin)

	get_parent().on_enemy_died(self)
	queue_free()
