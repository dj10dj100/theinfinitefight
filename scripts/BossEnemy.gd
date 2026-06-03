extends CharacterBody3D

# -----------------------------------------------
# BOSS ENEMY 🐉 — "The General"
# A GIANT Rogue commander with THREE phases!
#
# Phase 1 (100–60% HP) — dark red, steady advance
# Phase 2 (60–30% HP)  — bright red, charge attack!
# Phase 3 (30–0% HP)   — PURPLE RAGE, double shots,
#                         summons minions every 8s
# -----------------------------------------------

@export var move_speed: float = 2.5
@export var health: float    = 1000.0
@export var shoot_range: float = 16.0

const BOSS_COLOUR_1 = Color(0.30, 0.05, 0.05)   # Phase 1 — dark crimson
const BOSS_COLOUR_2 = Color(0.55, 0.05, 0.02)   # Phase 2 — bright red
const BOSS_COLOUR_3 = Color(0.55, 0.05, 0.75)   # Phase 3 — purple rage

var bullet_scene = preload("res://scenes/Bullet.tscn")
var shoot_timer: float = 0.0
var target_clone = null
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var phase: int       = 1
var body_parts: Array = []
var max_health: float = 1000.0
var health_bar_3d: MeshInstance3D = null

# Charge attack
var _charge_active: bool   = false
var _charge_dir: Vector3   = Vector3.ZERO
var _charge_timer: float   = 0.0
var _next_charge: float    = 4.0

# Rage summon
var _summon_timer: float   = 8.0

@onready var shoot_point   = $ShootPoint
@onready var mesh_instance = $MeshInstance3D

func _ready():
	add_to_group("enemies")
	add_to_group("boss")
	max_health = health

	mesh_instance.visible = false
	body_parts = ArmyManBuilder.build(self, BOSS_COLOUR_1)
	scale = Vector3(2.2, 2.2, 2.2)

	_build_health_bar()
	_show_banner("👹 THE GENERAL HAS ARRIVED!", Color(1.0, 0.2, 0.2))
	print("⚠️ THE GENERAL HAS ARRIVED! ⚠️")
	SoundManager.play("last_stand")

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	shoot_timer  -= delta
	_next_charge -= delta
	_summon_timer -= delta

	_check_phase(delta)

	if target_clone == null or not is_instance_valid(target_clone):
		target_clone = _find_nearest_clone()

	if target_clone != null:
		if _charge_active:
			_do_charge(delta)
		else:
			_advance_and_shoot(delta)

	move_and_slide()
	_update_health_bar()

# -----------------------------------------------
# PHASE TRANSITIONS
# -----------------------------------------------
func _check_phase(_delta):
	var pct = health / max_health
	if phase == 1 and pct < 0.60:
		phase = 2
		move_speed = 4.0
		_recolour(BOSS_COLOUR_2)
		_show_banner("😡 PHASE 2 — HE'S GETTING ANGRY!", Color(1.0, 0.5, 0.0))
		print("👹 BOSS → PHASE 2!")

	elif phase == 2 and pct < 0.30:
		phase = 3
		move_speed = 6.0
		_recolour(BOSS_COLOUR_3)
		_show_banner("💜 PHASE 3 — FULL RAGE MODE!!!", Color(0.8, 0.0, 1.0))
		print("👹 BOSS → PHASE 3 RAGE!")

# -----------------------------------------------
# AI
# -----------------------------------------------
func _advance_and_shoot(_delta):
	if target_clone == null or not is_instance_valid(target_clone):
		return
	var dist = global_position.distance_to(target_clone.global_position)

	if dist > shoot_range:
		var dir = (target_clone.global_position - global_position).normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)

	_face_target()

	# Shoot (phase 3 = double shot)
	if dist <= shoot_range and shoot_timer <= 0:
		shoot()

	# Phase 2+: charge attack
	if phase >= 2 and _next_charge <= 0 and dist < 14.0:
		_start_charge()
		_next_charge = 5.0

	# Phase 3: summon minions
	if phase == 3 and _summon_timer <= 0:
		_summon_minion()
		_summon_timer = 8.0

func _start_charge():
	if target_clone == null or not is_instance_valid(target_clone):
		return
	_charge_active = true
	_charge_timer  = 0.7
	_charge_dir    = (target_clone.global_position - global_position).normalized()
	print("👹 BOSS CHARGES!")

func _do_charge(delta):
	_charge_timer -= delta
	velocity.x = _charge_dir.x * move_speed * 4.0
	velocity.z = _charge_dir.z * move_speed * 4.0
	# Smash any clone within reach
	for clone in get_tree().get_nodes_in_group("clones"):
		if is_instance_valid(clone) and global_position.distance_to(clone.global_position) < 2.5:
			clone.take_damage(55.0)
	if _charge_timer <= 0:
		_charge_active = false

func _summon_minion():
	_show_banner("💀 Minions incoming!", Color(0.8, 0.2, 0.2))
	var spawn_pos = global_position + Vector3(randf_range(-5.0, 5.0), 0, randf_range(-5.0, 5.0))
	var minion = CharacterBody3D.new()
	minion.set_script(load("res://scripts/Enemy.gd"))
	minion.position = spawn_pos
	get_tree().root.add_child(minion)
	print("👹 Boss summons a minion!")

# -----------------------------------------------
# SHOOTING — burst of bullets, double in phase 3
# -----------------------------------------------
func shoot():
	shoot_timer = 0.8 if phase < 3 else 0.5
	SoundManager.play("shoot_assault_rifle")
	var dir = -shoot_point.global_transform.basis.z.normalized()
	Particles.muzzle_flash(shoot_point.global_position, dir)

	var shots = 3 if phase < 3 else 5
	for i in range(shots):
		var spread = Vector3(randf_range(-0.18, 0.18), 0, randf_range(-0.18, 0.18))
		var bullet = bullet_scene.instantiate()
		bullet.global_position = shoot_point.global_position
		bullet.direction       = (dir + spread).normalized()
		bullet.damage          = 25.0 + (phase - 1) * 15.0
		bullet.fired_by        = "enemies"
		get_tree().root.add_child(bullet)

func _find_nearest_clone() -> Node:
	var clones = get_tree().get_nodes_in_group("clones")
	var nearest = null; var nearest_dist = INF
	for clone in clones:
		var dist = global_position.distance_to(clone.global_position)
		if dist < nearest_dist:
			nearest_dist = dist; nearest = clone
	return nearest

func _face_target():
	if target_clone == null or not is_instance_valid(target_clone):
		return
	var lp    = target_clone.global_position
	lp.y      = global_position.y
	look_at(lp, Vector3.UP)

# -----------------------------------------------
# DAMAGE & DEATH
# -----------------------------------------------
func take_damage(amount: float):
	health -= amount
	SoundManager.play("hit")

	var flash = StandardMaterial3D.new()
	flash.albedo_color = Color(1.0, 0.3, 0.3)
	for part in body_parts:
		if is_instance_valid(part):
			part.set_surface_override_material(0, flash)
	await get_tree().create_timer(0.08).timeout
	if not is_instance_valid(self):
		return
	_recolour(_phase_colour())

	if health <= 0:
		_die_epic()

func _phase_colour() -> Color:
	match phase:
		2: return BOSS_COLOUR_2
		3: return BOSS_COLOUR_3
	return BOSS_COLOUR_1

func _recolour(colour: Color):
	var mat = StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness    = 0.25
	for part in body_parts:
		if is_instance_valid(part):
			part.set_surface_override_material(0, mat)

func _die_epic():
	print("🏆 THE GENERAL HAS BEEN DEFEATED!")
	Achievements.unlock("boss_slayer")
	_show_banner("🏆 BOSS DEFEATED! LEGENDARY!", Color(1.0, 0.9, 0.0))
	for i in range(6):
		await get_tree().create_timer(0.18).timeout
		if not is_instance_valid(self):
			return
		var off = Vector3(randf_range(-2.0, 2.0), randf_range(0.3, 2.5), randf_range(-2.0, 2.0))
		Particles.death_explosion(global_position + off, _phase_colour())
		SoundManager.play("death")
	get_parent().on_enemy_died(self)
	queue_free()

# -----------------------------------------------
# FLOATING HEALTH BAR
# -----------------------------------------------
func _build_health_bar():
	var bg = MeshInstance3D.new()
	var bgm = BoxMesh.new(); bgm.size = Vector3(2.2, 0.22, 0.08)
	bg.mesh = bgm
	var bgmat = StandardMaterial3D.new()
	bgmat.albedo_color = Color(0.1, 0.0, 0.0)
	bgmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg.set_surface_override_material(0, bgmat)
	bg.position = Vector3(0, 3.4, 0)
	add_child(bg)

	health_bar_3d = MeshInstance3D.new()
	var bm = BoxMesh.new(); bm.size = Vector3(2.2, 0.18, 0.1)
	health_bar_3d.mesh = bm
	var bmat = StandardMaterial3D.new()
	bmat.albedo_color = Color(0.9, 0.1, 0.1)
	bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	health_bar_3d.set_surface_override_material(0, bmat)
	health_bar_3d.position = Vector3(0, 3.4, 0.01)
	add_child(health_bar_3d)

func _update_health_bar():
	if health_bar_3d == null: return
	var ratio = clamp(health / max_health, 0.0, 1.0)
	health_bar_3d.scale.x    = ratio
	health_bar_3d.position.x = (ratio - 1.0) * 1.1
	var bmat = StandardMaterial3D.new()
	bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if ratio > 0.6:   bmat.albedo_color = Color(0.2, 0.9, 0.2)
	elif ratio > 0.3: bmat.albedo_color = Color(0.9, 0.8, 0.1)
	else:             bmat.albedo_color = Color(0.9, 0.1, 0.8)   # Purple in rage
	health_bar_3d.set_surface_override_material(0, bmat)

# Banner helper (big text on screen)
func _show_banner(text: String, colour: Color):
	var canvas = CanvasLayer.new()
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", colour)
	lbl.set_anchor(SIDE_LEFT, 0.5);  lbl.set_anchor(SIDE_RIGHT, 0.5)
	lbl.set_anchor(SIDE_TOP, 0.38);  lbl.set_anchor(SIDE_BOTTOM, 0.38)
	lbl.offset_left = -280; lbl.offset_right = 280
	lbl.offset_top  = -20;  lbl.offset_bottom = 20
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	canvas.add_child(lbl)
	get_tree().root.add_child(canvas)
	var tw = get_tree().create_tween()
	tw.tween_interval(2.2)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.8)
	tw.tween_callback(canvas.queue_free)
