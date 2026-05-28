extends CharacterBody3D

# -----------------------------------------------
# BOSS ENEMY — "The General"
# A giant, super-tough enemy that appears every
# 10 wins. It's twice the size of a normal enemy,
# has loads of health, and shoots really fast!
# Beat it for a bonus win!
# -----------------------------------------------

@export var move_speed: float = 2.0
@export var health: float = 1000.0
@export var shoot_range: float = 20.0

var bullet_scene = preload("res://scenes/Bullet.tscn")
var shoot_timer: float = 0.0
var target_clone = null
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# The boss is a dark red colour — scary!
const BOSS_COLOUR    = Color(0.55, 0.05, 0.05)
const BOSS_TRIM      = Color(0.7,  0.6,  0.0)   # Gold trim

var body_parts: Array = []
var max_health: float = 1000.0
var health_bar_3d: MeshInstance3D = null

@onready var shoot_point = $ShootPoint
@onready var mesh_instance = $MeshInstance3D

func _ready():
	add_to_group("enemies")
	add_to_group("boss")

	max_health = health

	# Hide the plain capsule — build a GIANT army man!
	mesh_instance.visible = false
	body_parts = ArmyManBuilder.build(self, BOSS_COLOUR)

	# Make the boss TWICE as big as a normal soldier
	scale = Vector3(2.2, 2.2, 2.2)

	# Add a floating health bar above the boss
	_build_health_bar()

	print("⚠️  THE GENERAL HAS ARRIVED! ⚠️")
	SoundManager.play("last_stand")

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	shoot_timer -= delta

	if target_clone == null or not is_instance_valid(target_clone):
		target_clone = find_nearest_clone()

	if target_clone != null:
		var distance = global_position.distance_to(target_clone.global_position)
		if distance <= shoot_range:
			var look_target = target_clone.global_position
			look_target.y = global_position.y
			look_at(look_target, Vector3.UP)
			if shoot_timer <= 0:
				shoot()
		else:
			var dir = (target_clone.global_position - global_position).normalized()
			velocity.x = dir.x * move_speed
			velocity.z = dir.z * move_speed

	move_and_slide()
	_update_health_bar()

# -----------------------------------------------
# SHOOTING — fires a burst of 3 bullets!
# -----------------------------------------------
func shoot():
	shoot_timer = 0.8  # Fires faster than normal enemies

	SoundManager.play("shoot_assault_rifle")

	# Fire 3 bullets in a small spread
	for i in range(3):
		var spread = Vector3(randf_range(-0.15, 0.15), 0, randf_range(-0.15, 0.15))
		var bullet = bullet_scene.instantiate()
		bullet.global_position = shoot_point.global_position
		bullet.direction = (-shoot_point.global_transform.basis.z + spread).normalized()
		bullet.damage = 25.0
		bullet.fired_by = "enemies"
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

	# Flash RED when hit (boss stays red but goes bright)
	var flash_mat = StandardMaterial3D.new()
	flash_mat.albedo_color = Color(1.0, 0.2, 0.2)
	flash_mat.roughness = 0.2
	var normal_mat = StandardMaterial3D.new()
	normal_mat.albedo_color = BOSS_COLOUR
	normal_mat.roughness = 0.35

	for part in body_parts:
		if is_instance_valid(part):
			part.set_surface_override_material(0, flash_mat)
	await get_tree().create_timer(0.08).timeout
	for part in body_parts:
		if is_instance_valid(part):
			part.set_surface_override_material(0, normal_mat)

	if health <= 0:
		die()

func die():
	print("🏆  THE GENERAL HAS BEEN DEFEATED! INCREDIBLE!")
	SoundManager.play("victory_sting")
	get_parent().on_enemy_died(self)
	queue_free()

# -----------------------------------------------
# FLOATING HEALTH BAR
# A red bar that floats above the boss's head
# so you can see how much damage you've done
# -----------------------------------------------
func _build_health_bar():
	# Background (dark bar)
	var bg = MeshInstance3D.new()
	var bg_mesh = BoxMesh.new()
	bg_mesh.size = Vector3(2.2, 0.22, 0.08)
	bg.mesh = bg_mesh
	var bg_mat = StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.15, 0.0, 0.0)
	bg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg.set_surface_override_material(0, bg_mat)
	bg.position = Vector3(0, 3.4, 0)
	add_child(bg)

	# Foreground (red fill — shrinks as boss loses health)
	health_bar_3d = MeshInstance3D.new()
	var bar_mesh = BoxMesh.new()
	bar_mesh.size = Vector3(2.2, 0.18, 0.1)
	health_bar_3d.mesh = bar_mesh
	var bar_mat = StandardMaterial3D.new()
	bar_mat.albedo_color = Color(0.9, 0.1, 0.1)
	bar_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	health_bar_3d.set_surface_override_material(0, bar_mat)
	health_bar_3d.position = Vector3(0, 3.4, 0.01)
	add_child(health_bar_3d)

func _update_health_bar():
	if health_bar_3d == null:
		return
	var ratio = clamp(health / max_health, 0.0, 1.0)
	# Shrink the bar from the right as health drops
	health_bar_3d.scale.x = ratio
	health_bar_3d.position.x = (ratio - 1.0) * 1.1  # Keep left-aligned
	# Change colour: green → yellow → red
	var bar_mat = StandardMaterial3D.new()
	bar_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if ratio > 0.6:
		bar_mat.albedo_color = Color(0.2, 0.9, 0.2)
	elif ratio > 0.3:
		bar_mat.albedo_color = Color(0.9, 0.8, 0.1)
	else:
		bar_mat.albedo_color = Color(0.9, 0.1, 0.1)
	health_bar_3d.set_surface_override_material(0, bar_mat)
