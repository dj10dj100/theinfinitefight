extends CharacterBody3D

# -----------------------------------------------
# ENEMY (The Rogue Clone)
# Walks towards your clones and shoots at them.
# Made RED so you can tell them apart!
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

@onready var shoot_point = $ShootPoint
@onready var mesh_instance = $MeshInstance3D

func _ready():
	add_to_group("enemies")

	# Hide the plain capsule and build a Rogue army man!
	mesh_instance.visible = false
	body_parts = ArmyManBuilder.build(self, ENEMY_COLOUR)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	shoot_timer -= delta

	if target_clone == null or not is_instance_valid(target_clone):
		target_clone = find_nearest_clone()

	if target_clone != null:
		var distance = global_position.distance_to(target_clone.global_position)
		if distance <= shoot_range:
			# Face the clone and shoot!
			var look_target = target_clone.global_position
			look_target.y = global_position.y
			look_at(look_target, Vector3.UP)
			if shoot_timer <= 0:
				shoot()
		else:
			# Walk towards the clone
			var dir = (target_clone.global_position - global_position).normalized()
			velocity.x = dir.x * move_speed
			velocity.z = dir.z * move_speed

	move_and_slide()

# -----------------------------------------------
# SHOOT — fires a real bullet at your clone!
# -----------------------------------------------
func shoot():
	shoot_timer = 1.8  # Enemies fire a bit slower than your clones

	SoundManager.play("shoot_" + weapon, -4.0)   # Slightly quieter than player shots

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
	get_parent().on_enemy_died(self)
	queue_free()
