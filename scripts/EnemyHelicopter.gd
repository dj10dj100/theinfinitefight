extends CharacterBody3D

# -----------------------------------------------
# ENEMY HELICOPTER 🚁💀
# Spawns after 30 seconds of battle.
# Flies over the battlefield, shoots at clones,
# and can be shot down!
# -----------------------------------------------

var health: float   = 250.0
var _shoot_timer: float = 0.0
var _rotor_angle: float = 0.0
var _target_clone = null
var bullet_scene = preload("res://scenes/Bullet.tscn")

const FLY_HEIGHT  = 8.0
const FLY_SPEED   = 5.0
const SHOOT_RANGE = 20.0

func _ready():
	add_to_group("enemies")
	_build_visual()
	position.y = FLY_HEIGHT
	print("🚁💀 ENEMY HELICOPTER INCOMING!")
	_show_warning()

func _build_visual():
	var body = MeshInstance3D.new()
	var bm   = BoxMesh.new()
	bm.size  = Vector3(1.8, 0.6, 3.0)
	body.mesh = bm
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.10, 0.10)   # Dark red — enemy colours
	mat.roughness    = 0.4
	body.set_surface_override_material(0, mat)
	body.position = Vector3(0, 0.3, 0)
	add_child(body)

	var tail = MeshInstance3D.new()
	var tm   = BoxMesh.new()
	tm.size  = Vector3(0.3, 0.3, 2.0)
	tail.mesh = tm
	tail.set_surface_override_material(0, mat)
	tail.position = Vector3(0, 0.3, 2.2)
	add_child(tail)

	var rotor = MeshInstance3D.new()
	var rm    = BoxMesh.new()
	rm.size   = Vector3(4.0, 0.06, 0.2)
	rotor.mesh = rm
	var rmat = StandardMaterial3D.new()
	rmat.albedo_color = Color(0.2, 0.2, 0.2)
	rotor.set_surface_override_material(0, rmat)
	rotor.name     = "Rotor"
	rotor.position = Vector3(0, 0.65, 0)
	add_child(rotor)

	var col = CollisionShape3D.new()
	col.shape      = BoxShape3D.new()
	col.shape.size = Vector3(1.8, 1.0, 3.0)
	col.position   = Vector3(0, 0.3, 0)
	add_child(col)

func _physics_process(delta):
	# Spin rotor
	_rotor_angle += delta * 22.0
	var rotor = get_node_or_null("Rotor")
	if rotor:
		rotor.rotation.y = _rotor_angle

	_shoot_timer -= delta

	# Find nearest clone to chase
	if _target_clone == null or not is_instance_valid(_target_clone):
		_target_clone = _find_nearest_clone()

	if _target_clone and is_instance_valid(_target_clone):
		# Fly toward target, staying at fly height
		var target_pos = Vector3(_target_clone.global_position.x, FLY_HEIGHT, _target_clone.global_position.z)
		var dir = (target_pos - global_position).normalized()
		velocity.x = dir.x * FLY_SPEED
		velocity.z = dir.z * FLY_SPEED
		velocity.y = (FLY_HEIGHT - global_position.y) * 2.0

		# Look at target
		var flat_target = Vector3(_target_clone.global_position.x, global_position.y, _target_clone.global_position.z)
		if flat_target.distance_to(global_position) > 0.5:
			look_at(flat_target, Vector3.UP)

		# Shoot down at clones
		var dist = global_position.distance_to(_target_clone.global_position)
		if dist <= SHOOT_RANGE and _shoot_timer <= 0:
			_shoot_at(_target_clone)
			_shoot_timer = 1.2

	move_and_slide()

func _find_nearest_clone() -> Node:
	var nearest = null
	var nearest_dist = INF
	for clone in get_tree().get_nodes_in_group("clones"):
		if clone.get("is_invisible") == true:
			continue
		var d = global_position.distance_to(clone.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = clone
	return nearest

func _shoot_at(target):
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position + Vector3(0, -0.5, -1.5)
	var dir = (target.global_position - bullet.global_position).normalized()
	bullet.direction = dir
	bullet.damage    = 25.0
	bullet.fired_by  = "enemies"
	bullet.speed     = 25.0
	get_tree().root.add_child(bullet)
	Particles.muzzle_flash(bullet.global_position, dir)
	SoundManager.play("shoot_assault_rifle")

func take_damage(amount: float):
	health -= amount
	SoundManager.play("hit")
	if health <= 0:
		_crash()

func _crash():
	Particles.death_explosion(global_position, Color(1.0, 0.4, 0.0))
	Particles.death_explosion(global_position + Vector3(0, -2, 0), Color(0.8, 0.2, 0.0))
	SoundManager.play("death")
	print("🚁💥 Enemy helicopter shot down!")
	queue_free()

func _show_warning():
	var canvas = CanvasLayer.new()
	canvas.layer = 18
	get_tree().root.add_child(canvas)
	var lbl = Label.new()
	lbl.text = "⚠️  ENEMY HELICOPTER INCOMING!"
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	lbl.set_anchor(SIDE_LEFT, 0.0); lbl.set_anchor(SIDE_RIGHT, 1.0)
	lbl.set_anchor(SIDE_TOP, 0.1); lbl.set_anchor(SIDE_BOTTOM, 0.2)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(lbl)
	var tw = get_tree().create_tween()
	tw.tween_interval(3.0)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.5)
	tw.tween_callback(canvas.queue_free)
