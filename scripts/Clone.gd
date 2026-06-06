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

# AMMO SYSTEM — each weapon has its own magazine size
# When ammo hits 0, the clone has to reload before shooting again!
var ammo: int = 15           # Bullets left in current magazine
var max_ammo: int = 15       # Full magazine size
var is_reloading: bool = false
var reload_timer: float = 0.0

# Load the bullet scene so we can fire bullets!
var bullet_scene = preload("res://scenes/Bullet.tscn")

var is_player_controlled: bool = false
var is_player2_controlled: bool = false
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

# Special ability chosen in CloneCustomise
var special_ability: String = "none"

# Rank system
var kills: int = 0
var rank_index: int = 0
var rank_damage_bonus: float = 1.0

# Custom colour (set from Battlefield after deploy)
var custom_colour: Color = Color(0.30, 0.38, 0.16)

# Medic: heal timer
var _medic_timer: float = 0.0

# Special ability cooldowns (in seconds)
# These count DOWN — when they hit 0 the ability is ready again!
var grenade_cooldown:   float = 0.0   # G key — throw a grenade
var airstrike_cooldown: float = 0.0   # A key — call an airstrike
var landmine_cooldown:  float = 0.0   # M key — plant a landmine
const GRENADE_CD   = 12.0
const AIRSTRIKE_CD = 25.0
const LANDMINE_CD  = 18.0

# Animation variables — used to bob and sway the body while moving
var _anim_time: float = 0.0
var _is_moving: bool  = false

@onready var shoot_point = $ShootPoint
@onready var mesh_instance = $MeshInstance3D

func _ready():
	add_to_group("clones")

	active_weapon = weapon
	if weapon == "sniper":
		shoot_range = 30.0
	# Fill the magazine for whichever weapon this clone starts with
	max_ammo = get_max_ammo(active_weapon)
	ammo     = max_ammo

	# Hide the plain capsule and build a proper plastic army man instead!
	mesh_instance.visible = false
	# Use custom colour if set, otherwise default olive green
	var build_colour = custom_colour if custom_colour != Color(0.30, 0.38, 0.16) else CLONE_COLOUR
	body_parts = ArmyManBuilder.build(self, build_colour)

# -----------------------------------------------
# Every frame — movement, shooting, AI
# -----------------------------------------------
func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	shoot_timer -= delta

	# Reload countdown — when it finishes, refill the magazine!
	if is_reloading:
		reload_timer -= delta
		if reload_timer <= 0.0:
			is_reloading = false
			ammo = max_ammo
			if is_player_controlled:
				print("✅ Reloaded! ", ammo, " bullets ready.")

	# Tick down the special ability cooldowns every frame
	grenade_cooldown   = max(grenade_cooldown   - delta, 0.0)
	airstrike_cooldown = max(airstrike_cooldown - delta, 0.0)
	landmine_cooldown  = max(landmine_cooldown  - delta, 0.0)

	# Touch fire button — shoot while held
	if is_player_controlled:
		var touch = get_node_or_null("/root/TouchControls")
		if touch and touch.fire_pressed and shoot_timer <= 0:
			shoot()

	if is_player_controlled:
		handle_player_movement(delta)
	elif is_player2_controlled:
		handle_player2_movement(delta)
	else:
		handle_ai(delta)

	move_and_slide()
	_update_animation(delta)
	_update_ability(delta)

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

	# Special abilities — only in first-person!
	if is_player_controlled and event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_G:
				if grenade_cooldown <= 0:
					_throw_grenade()
				else:
					print("Grenade not ready! Wait ", int(grenade_cooldown) + 1, " more seconds.")
			KEY_A:
				if airstrike_cooldown <= 0:
					_call_airstrike()
				else:
					print("Airstrike not ready! Wait ", int(airstrike_cooldown) + 1, " more seconds.")
			KEY_M:
				if landmine_cooldown <= 0:
					_plant_landmine()
				else:
					print("Landmine not ready! Wait ", int(landmine_cooldown) + 1, " more seconds.")

# -----------------------------------------------
# PLAYER MOVEMENT (WASD or arrow keys)
# -----------------------------------------------
func handle_player_movement(delta):
	var direction = Vector3.ZERO

	# --- Keyboard (desktop) ---
	if Input.is_action_pressed("ui_up"):    direction -= transform.basis.z
	if Input.is_action_pressed("ui_down"):  direction += transform.basis.z
	if Input.is_action_pressed("ui_left"):  direction -= transform.basis.x
	if Input.is_action_pressed("ui_right"): direction += transform.basis.x

	# --- Virtual joystick (mobile) ---
	var touch = get_node_or_null("/root/TouchControls")
	if touch and touch.move_vector != Vector2.ZERO:
		direction -= transform.basis.z * touch.move_vector.y
		direction += transform.basis.x * touch.move_vector.x

	# --- Touch look (swipe right side of screen) ---
	if touch and touch.look_delta != Vector2.ZERO:
		rotate_y(-touch.look_delta.x * mouse_sensitivity)

	# --- Touch ability buttons ---
	if touch:
		if touch.key_g and grenade_cooldown <= 0:
			_throw_grenade()
		if touch.key_a and airstrike_cooldown <= 0:
			_call_airstrike()
		if touch.key_m and landmine_cooldown <= 0:
			_plant_landmine()
		if touch.key_e:
			# Enter/exit helicopter via touch
			for heli in get_tree().get_nodes_in_group("helicopter"):
				if heli.has_method("_try_enter_helicopter") or heli.has_method("_exit_helicopter"):
					if heli.is_player_in:
						heli._exit_helicopter()
					else:
						heli._try_enter_helicopter()

	# Jump — Space to jump, jetpack backpack leaps much higher!
	var jump_pressed = Input.is_key_pressed(KEY_SPACE) or (touch and touch.key_jump)
	if jump_pressed and is_on_floor():
		velocity.y = 10.0 if has_meta("has_jetpack") else 6.0
		if has_meta("has_jetpack"):
			print("🚀 JETPACK!")

	if direction != Vector3.ZERO:
		direction = direction.normalized()
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)

# -----------------------------------------------
# PLAYER 2 MOVEMENT — IJKL keys + SPACE to shoot
# Player 2 controls from a top-down view,
# facing the enemy zone (positive Z direction)
# -----------------------------------------------
func handle_player2_movement(delta):
	var direction = Vector3.ZERO
	if Input.is_action_pressed("p2_up"):    direction -= Vector3(0, 0, 1)
	if Input.is_action_pressed("p2_down"):  direction += Vector3(0, 0, 1)
	if Input.is_action_pressed("p2_left"):  direction -= Vector3(1, 0, 0)
	if Input.is_action_pressed("p2_right"): direction += Vector3(1, 0, 0)

	if direction != Vector3.ZERO:
		direction = direction.normalized()
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		# Face the direction of movement
		look_at(global_position + direction, Vector3.UP)
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)

	# Spacebar to shoot
	if Input.is_action_just_pressed("p2_shoot"):
		if shoot_timer <= 0:
			shoot()

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
	# Can't shoot while reloading!
	if is_reloading:
		return

	# Out of ammo? Start reloading instead!
	if ammo <= 0:
		_start_reload()
		return

	# Fire! Use one bullet.
	ammo -= 1
	shoot_timer = get_shoot_cooldown()

	# Auto-reload when the last bullet is fired
	if ammo <= 0:
		_start_reload()

	# Play the right gunshot sound for the weapon!
	SoundManager.play("shoot_" + active_weapon)

	# Shout a battle phrase!
	VoiceLines.say_shoot(global_position)

	var shoot_dir = -shoot_point.global_transform.basis.z.normalized()
	Particles.muzzle_flash(shoot_point.global_position, shoot_dir)

	# Each weapon fires differently!
	match active_weapon:
		"flamethrower":
			_shoot_flamethrower()
		"rocket_launcher":
			_shoot_rocket()
		"lightning_gun":
			_shoot_lightning()
		"grenade_launcher":
			_shoot_grenade_launcher()
		_:
			# Regular bullet for all other weapons
			var bullet = bullet_scene.instantiate()
			bullet.global_position = shoot_point.global_position
			bullet.direction = shoot_dir
			bullet.damage    = get_bullet_damage()
			bullet.fired_by  = "clones"
			bullet.shot_by   = self
			get_tree().root.add_child(bullet)

# Sniper clone swaps between sniper rifle and secondary weapon
func swap_weapon():
	if active_weapon == weapon:
		active_weapon = secondary_weapon
		shoot_range = 10.0   # Secondary weapon is close-range
	else:
		active_weapon = weapon
		shoot_range = 30.0   # Back to sniper range
	# Refill ammo for the weapon we just switched to
	max_ammo     = get_max_ammo(active_weapon)
	ammo         = max_ammo
	is_reloading = false
	print("Switched to: ", active_weapon)

# Start a reload — fills up the magazine after a short wait
func _start_reload():
	if is_reloading:
		return
	# Arnie's Raygun never needs to reload — infinite power!
	if active_weapon == "arnies_raygun":
		ammo = max_ammo
		return
	is_reloading  = true
	reload_timer  = get_reload_time()
	if is_player_controlled:
		print("🔄 Reloading... (", reload_timer, "s)")
	SoundManager.play("click")

# How many bullets in a full magazine?
func get_max_ammo(w: String) -> int:
	match w:
		"pistol":        return 15
		"revolver":      return 6
		"shotgun":       return 5
		"assault_rifle": return 30
		"sniper":        return 1
		"smg":           return 70
		"arnies_raygun": return 1000000000   # Basically infinite!
		"minigun":           return 1000
		"flamethrower":      return 100
		"rocket_launcher":   return 4
		"lightning_gun":     return 20
		"grenade_launcher":  return 6
	return 15

# How long does it take to reload each weapon?
func get_reload_time() -> float:
	match active_weapon:
		"pistol":        return 1.5
		"revolver":      return 2.0
		"shotgun":       return 2.5
		"assault_rifle": return 2.0
		"sniper":        return 2.5
		"smg":           return 2.5
		"arnies_raygun": return 0.0   # Never reloads
		"minigun":           return 3.0
		"flamethrower":      return 3.0
		"rocket_launcher":   return 3.5
		"lightning_gun":     return 2.0
		"grenade_launcher":  return 2.5
	return 2.0

# How fast does this weapon fire?
func get_shoot_cooldown() -> float:
	var base = 1.5
	match active_weapon:
		"pistol":        base = 1.5
		"revolver":      base = 2.0
		"shotgun":       base = 2.2
		"assault_rifle": base = 0.3
		"sniper":        base = 3.0
		"smg":           base = 0.1
		"arnies_raygun":     base = 0.5
		"minigun":           base = 0.08
		"flamethrower":      base = 0.05
		"rocket_launcher":   base = 2.5
		"lightning_gun":     base = 0.8
		"grenade_launcher":  base = 1.5
	# Fast Reload upgrade: -20% cooldown per level
	var reduction = 1.0 - GameManager.get_upgrade("fast_reload") * 0.20 if GameManager else 1.0
	# Engineer class: shoots twice as fast!
	if special_ability == "engineer":
		reduction *= 0.5
	return base * clamp(reduction, 0.2, 1.0)

# How much damage does each weapon do per shot?
func get_bullet_damage() -> float:
	var base = 20.0
	match active_weapon:
		# Each weapon does 5 more damage than the last!
		# Unlock order: pistol(1) revolver(2) shotgun(3) assault_rifle(4)
		#   sniper(5) smg(6) minigun(7) arnies_raygun(8)
		#   flamethrower(9) rocket_launcher(10) lightning_gun(11) grenade_launcher(12)
		"pistol":            base = 15.0
		"revolver":          base = 20.0
		"shotgun":           base = 25.0
		"assault_rifle":     base = 30.0
		"sniper":            base = 35.0
		"smg":               base = 40.0
		"minigun":           base = 45.0
		"arnies_raygun":     base = 50.0
		"flamethrower":      base = 55.0
		"rocket_launcher":   base = 60.0
		"lightning_gun":     base = 65.0
		"grenade_launcher":  base = 70.0
	# Bigger Bullets upgrade: +25% damage per level
	var upgrade_bonus = 1.0 + GameManager.get_upgrade("bigger_bullets") * 0.25 if GameManager else 1.0
	return base * upgrade_bonus * rank_damage_bonus

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
# -----------------------------------------------
# BODY BOB ANIMATION
# Makes the clone bob up and down while walking,
# and tilt forward slightly when running.
# -----------------------------------------------
func _update_ability(delta: float):
	match special_ability:
		"berserker":
			# Below 50% HP: run faster!
			if health < 50.0:
				move_speed = 7.0
		"medic":
			# Heal 2 HP per second (self only)
			_medic_timer += delta
			if _medic_timer >= 1.0:
				_medic_timer = 0.0
				health = min(health + 2.0, 100.0)
		"field_medic":
			# Heal ALL nearby clones 4 HP per second
			_medic_timer += delta
			if _medic_timer >= 1.0:
				_medic_timer = 0.0
				for c in get_tree().get_nodes_in_group("clones"):
					if is_instance_valid(c) and global_position.distance_to(c.global_position) <= 6.0:
						c.health = min(c.health + 4.0, 100.0)
		"demolitions":
			pass
		"engineer":
			pass

	# Backpack: medkit heals 5 HP/s
	if has_meta("medkit_active"):
		_medic_timer += delta
		if _medic_timer >= 1.0:
			_medic_timer = 0.0
			health = min(health + 5.0, 100.0)

	# Backpack: grenade bag — halve the grenade cooldown constant
	if has_meta("grenade_bag"):
		pass   # Applied when throwing (checked in _throw_grenade)

func _update_animation(delta: float):
	_is_moving = velocity.length() > 0.5 and is_on_floor()
	if _is_moving:
		_anim_time += delta * 8.0  # Walking speed
	else:
		_anim_time = lerp(_anim_time, round(_anim_time), delta * 6.0)

	# Bob the whole body up and down
	var bob = sin(_anim_time) * 0.06 if _is_moving else 0.0
	# Sway side to side a tiny bit
	var sway = sin(_anim_time * 0.5) * 0.03 if _is_moving else 0.0

	# Apply to each body part (they were built at fixed positions)
	# We offset the whole character up/down via a position tweak
	if body_parts.size() > 0:
		var first = body_parts[0]
		if is_instance_valid(first):
			first.get_parent().position.y = bob

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
	VoiceLines.say_hit(global_position)
	Particles.blood_splat(global_position + Vector3(0, 0.8, 0))
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
	VoiceLines.say_death(global_position)
	Particles.blood_splat(global_position + Vector3(0, 0.8, 0))
	get_parent().on_clone_died(self)

	# Stop the clone from moving or shooting any more
	is_player_controlled = false
	set_physics_process(false)
	set_process(false)

	# Tip over and fall to the ground like a knocked-over toy soldier
	var fall = get_tree().create_tween()
	fall.tween_property(self, "rotation_degrees:x", 90.0, 0.4).set_ease(Tween.EASE_IN)
	fall.parallel().tween_property(self, "position:y", position.y - 0.3, 0.4)
	fall.tween_interval(1.2)
	fall.tween_callback(queue_free)

# -----------------------------------------------
# NEW WEAPON SPECIAL FIRE MODES
# -----------------------------------------------

# FLAMETHROWER — sprays a cone of fire bullets in 3 directions
func _shoot_flamethrower():
	var base_dir = -shoot_point.global_transform.basis.z.normalized()
	var spreads = [Vector3.ZERO, Vector3(0.15, 0, 0), Vector3(-0.15, 0, 0)]
	for offset in spreads:
		var b = bullet_scene.instantiate()
		b.global_position = shoot_point.global_position
		b.direction = (base_dir + offset).normalized()
		b.damage    = get_bullet_damage()
		b.fired_by  = "clones"
		b.shot_by   = self
		b.lifetime  = 0.4   # Short range — flames fade fast!
		b.speed     = 18.0
		get_tree().root.add_child(b)

# ROCKET LAUNCHER — fires an explosive rocket!
func _shoot_rocket():
	var shoot_dir = -shoot_point.global_transform.basis.z.normalized()
	var rocket = Node3D.new()
	rocket.set_script(load("res://scripts/Rocket.gd"))
	rocket.set("direction", shoot_dir)
	rocket.set("damage", get_bullet_damage())
	rocket.set("fired_by", "clones")
	rocket.set("shot_by", self)
	rocket.global_position = shoot_point.global_position
	get_tree().root.add_child(rocket)

# LIGHTNING GUN — instant hit on nearest enemy, chains to nearby ones too!
func _shoot_lightning():
	var enemies = get_tree().get_nodes_in_group("enemies")
	var primary = null
	var nearest_dist = 30.0
	for enemy in enemies:
		var dist = global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			primary = enemy
	if primary == null:
		return
	# Zap the main target
	primary.take_damage(get_bullet_damage())
	Particles.hit_sparks(primary.global_position)
	# Chain to nearby enemies for half damage (like electricity jumping!)
	for enemy in enemies:
		if enemy != primary and primary.global_position.distance_to(enemy.global_position) <= 6.0:
			enemy.take_damage(get_bullet_damage() * 0.5)
			Particles.hit_sparks(enemy.global_position)
	print("⚡ ZAP! Lightning strikes!")

# GRENADE LAUNCHER — bouncing grenade that explodes after a short delay
func _shoot_grenade_launcher():
	var shoot_dir = -shoot_point.global_transform.basis.z.normalized()
	var gl = Node3D.new()
	gl.set_script(load("res://scripts/BouncingGrenade.gd"))
	gl.set("velocity_vec", shoot_dir * 14.0 + Vector3(0, 6.0, 0))
	gl.set("damage", get_bullet_damage())
	gl.set("fired_by", "clones")
	gl.global_position = shoot_point.global_position + Vector3(0, 0.5, 0)
	get_tree().root.add_child(gl)

# -----------------------------------------------
# SPECIAL ABILITIES
# -----------------------------------------------
func _throw_grenade():
	# Demolitions class: cooldown is halved!
	var cd_mult = 1.0
	if special_ability == "demolitions": cd_mult *= 0.5
	if has_meta("grenade_bag"):          cd_mult *= 0.5
	grenade_cooldown = GRENADE_CD * cd_mult
	SoundManager.play("click")
	VoiceLines.say_grenade(global_position)
	print("💣 GRENADE! Watch out!")

	var grenade = load("res://scripts/Grenade.gd")
	var g = Area3D.new()
	g.set_script(grenade)

	# Add a collision shape so it can detect things
	var shape = CollisionShape3D.new()
	shape.shape = SphereShape3D.new()
	shape.shape.radius = 0.2
	g.add_child(shape)

	# Throw it forward and slightly upward from the clone's position
	g.global_position = global_position + Vector3(0, 1.2, 0)
	var throw_dir = -global_transform.basis.z.normalized()
	g.set("velocity_vec", throw_dir * 10.0 + Vector3(0, 5.0, 0))
	# Demolitions class: double damage!
	if special_ability == "demolitions":
		g.set("damage", 240.0)
	get_tree().root.add_child(g)

func _call_airstrike():
	airstrike_cooldown = AIRSTRIKE_CD
	SoundManager.play("click")
	VoiceLines.say_airstrike(global_position)
	print("✈️ AIRSTRIKE INCOMING!")
	Achievements.airstrike_count += 1
	if Achievements.airstrike_count >= 5:
		Achievements.unlock("airstrike_ace")

	# Target: 15 metres in front of the clone
	var target = global_position + (-global_transform.basis.z.normalized() * 15.0)
	target.y = 0.0

	var strike = Node3D.new()
	strike.set_script(load("res://scripts/Airstrike.gd"))
	strike.set("target_pos", target)
	get_tree().root.add_child(strike)

func _plant_landmine():
	landmine_cooldown = LANDMINE_CD
	SoundManager.play("click")
	print("💥 Mine planted! Back away...")

	var mine = Area3D.new()
	mine.set_script(load("res://scripts/Landmine.gd"))

	# Add a collision shape so enemies trigger it
	var shape = CollisionShape3D.new()
	shape.shape = CylinderShape3D.new()
	shape.shape.radius = 0.5
	shape.shape.height = 0.3
	mine.add_child(shape)

	mine.global_position = global_position
	mine.global_position.y = 0.05
	get_tree().root.add_child(mine)

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
