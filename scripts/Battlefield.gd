extends Node3D

# -----------------------------------------------
# BATTLEFIELD
# Runs the battle — handles clicking on clones,
# switching between top-down and first-person,
# and tracking when the battle is won or lost.
# -----------------------------------------------

var clones_on_field: Array = []
var enemies_on_field: Array = []
var controlled_clone = null
var last_stand_used: bool = false
var game_manager = null
var battle_over: bool = false
var hud: CanvasLayer = null

# Battle coins — collected by walking over dropped coins
var battle_coins: int = 0
var _coin_label = null
var _upgrade_panel = null

# Wave mode
var wave_manager = null

@onready var top_down_camera = $TopDownCamera
@onready var first_person_camera = $FirstPersonCamera

func _ready():
	add_to_group("battlefield")
	game_manager = get_node_or_null("/root/GameManager")

	# Spawn the HUD (hidden until first-person mode)
	var hud_scene = load("res://scenes/HUD.tscn")
	hud = hud_scene.instantiate()
	add_child(hud)

	# Spawn the Mini Map radar
	var minimap = load("res://scenes/MiniMap.tscn")
	if minimap:
		add_child(minimap.instantiate())
	else:
		# Build it directly if the scene file isn't there yet
		var mm_script = load("res://scripts/MiniMap.gd")
		var mm = CanvasLayer.new()
		mm.set_script(mm_script)
		add_child(mm)

	# Spawn weather effects
	var weather = Node.new()
	weather.set_script(load("res://scripts/Weather.gd"))
	weather.add_to_group("weather")
	add_child(weather)

	# Wait one frame so the scene is fully loaded
	await get_tree().process_frame

	# Apply the chosen map theme (colours, sky, decorations)
	MapTheme.apply(self)

	# If the player came from the Deploy Screen, spawn their chosen clones
	if game_manager and game_manager.deploy_data.size() > 0:
		spawn_clones_from_deploy(game_manager.deploy_data)
	else:
		# No deploy data — grab whatever clones are already in the scene
		for node in get_tree().get_nodes_in_group("clones"):
			clones_on_field.append(node)

	# Scale enemy health based on difficulty
	var health_mult = get_enemy_health_multiplier()
	for node in get_tree().get_nodes_in_group("enemies"):
		node.health = node.health * health_mult
		enemies_on_field.append(node)
	print("Difficulty: ", game_manager.difficulty if game_manager else "?", "  Enemy health x", health_mult)

	# Every 10 wins, spawn a boss enemy!
	if game_manager and game_manager.total_wins > 0 and game_manager.total_wins % 10 == 0:
		spawn_boss()

	# Multiplayer: give Player 2 control of the second clone
	if game_manager and game_manager.multiplayer_on and clones_on_field.size() >= 2:
		var p2_clone = clones_on_field[1]
		p2_clone.is_player2_controlled = true
		# Tint P2's clone bright blue so you can tell them apart
		for part in p2_clone.body_parts:
			if is_instance_valid(part):
				var mat = StandardMaterial3D.new()
				mat.albedo_color = Color(0.1, 0.4, 0.9)
				mat.roughness = 0.3
				part.set_surface_override_material(0, mat)
		print("🎮 Player 2 is controlling the second clone! (IJKL to move, SPACE to shoot)")

	# Start with the top-down view
	top_down_camera.current = true
	first_person_camera.current = false

	# Start the battle music!
	SoundManager.play_music("battle")

	# Spawn power-ups every 12 seconds
	_start_powerup_timer()

	# If wave mode is on, start the WaveManager instead of using pre-placed enemies
	if game_manager and game_manager.wave_mode:
		wave_manager = Node.new()
		wave_manager.set_script(load("res://scripts/WaveManager.gd"))
		add_child(wave_manager)
		wave_manager.start(self)
	else:
		# Spawn one jeep at the player side
		_spawn_jeep()

	# Spawn traps that were placed on the deploy screen
	_spawn_traps()

	# Reset killstreak for the new battle
	Killstreak.reset()
	Achievements.coins_spent_battle = 0

	# Build the coin + upgrade HUD (top-left corner)
	_build_coin_hud()

	print("Battle started! Your clones: ", clones_on_field.size(), "  Enemies: ", enemies_on_field.size())

func spawn_clones_from_deploy(deploy_data: Array):
	var clone_scene = load("res://scenes/Clone.tscn")
	var unlocked = game_manager.unlocked_weapons if game_manager else ["pistol"]

	for entry in deploy_data:
		var clone = clone_scene.instantiate()
		clone.weapon = entry["weapon"]

		# If it's a sniper, give it the best non-sniper weapon as backup
		if entry["weapon"] == "sniper":
			for w in ["machine_gun", "assault_rifle", "shotgun", "revolver", "pistol"]:
				if unlocked.has(w):
					clone.secondary_weapon = w
					break

		clone.position = entry["position"]
		add_child(clone)
		clones_on_field.append(clone)

	# Apply upgrade bonuses to every spawned clone
	for clone in clones_on_field:
		_apply_upgrades_to_clone(clone)

	print("Spawned ", deploy_data.size(), " clones from deploy screen!")

func _apply_upgrades_to_clone(clone):
	if not GameManager:
		return
	# Tougher clones: +25 HP per level
	clone.health     += GameManager.get_upgrade("tougher_clones") * 25.0
	# Faster legs: +20% speed per level
	clone.move_speed *= 1.0 + GameManager.get_upgrade("faster_legs") * 0.20

	# Apply chosen special ability (now includes Phase 13 classes!)
	var abilities = ["none","berserker","medic","tank","sniper_eye","field_medic","demolitions","engineer"]
	var ability_idx = clamp(GameManager.clone_ability_index, 0, abilities.size()-1)
	clone.special_ability = abilities[ability_idx]
	match clone.special_ability:
		"tank":
			clone.activate_shield(2)
		"sniper_eye":
			clone.shoot_range *= 1.30

	# Apply chosen clone colour
	var colours = [
		Color(0.30,0.38,0.16), Color(0.15,0.30,0.65), Color(0.65,0.10,0.10),
		Color(0.40,0.10,0.55), Color(0.75,0.35,0.05), Color(0.88,0.88,0.88),
		Color(0.85,0.35,0.55), Color(0.80,0.75,0.05),
	]
	var cidx = clamp(GameManager.clone_colour_index, 0, colours.size()-1)
	clone.custom_colour = colours[cidx]

func get_enemy_health_multiplier() -> float:
	var diff = game_manager.difficulty if game_manager else "medium"
	match diff:
		"easy":         return 1.0    # 200 HP
		"medium":       return 1.5    # 300 HP
		"hard":         return 2.0    # 400 HP
		"bloodthirsty": return 3.5    # 700 HP — good luck!
		_:              return 1.5

# -----------------------------------------------
# INPUT — clicking to take control, ESC to leave
# -----------------------------------------------
func _input(event):
	# Press ESCAPE to leave first-person and go back to top-down view
	if event.is_action_pressed("ui_cancel") and controlled_clone != null:
		controlled_clone.release_player_control()
		return

	# Left mouse click — try to click on a clone
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if controlled_clone == null:
			check_if_clone_clicked(event.position)

func check_if_clone_clicked(screen_pos: Vector2):
	var camera = top_down_camera
	var ray_origin = camera.project_ray_origin(screen_pos)
	var ray_end = ray_origin + camera.project_ray_normal(screen_pos) * 200

	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var result = space.intersect_ray(query)

	if result and result.collider.is_in_group("clones"):
		var clicked_clone = result.collider
		controlled_clone = clicked_clone
		clicked_clone.take_player_control()
	elif result and result.collider.is_in_group("jeep"):
		result.collider.enter_jeep()
		print("Jumped in the jeep!")

# -----------------------------------------------
# SWITCHING CAMERA VIEWS
# -----------------------------------------------
func enter_first_person(clone):
	first_person_camera.reparent(clone)
	first_person_camera.position = Vector3(0, 1.6, 0)
	first_person_camera.rotation = Vector3.ZERO
	first_person_camera.current  = true
	top_down_camera.current      = false
	# Show the HUD!
	if hud:
		hud.show_hud(clone)
	print("First-person mode! WASD to move, mouse to look, click to shoot. ESC to go back.")

func exit_first_person():
	first_person_camera.reparent(self)
	first_person_camera.current = false
	top_down_camera.current     = true
	controlled_clone            = null
	# Hide the HUD
	if hud:
		hud.hide_hud()
	print("Back to top-down view. Click a clone to control it!")

# -----------------------------------------------
# WHEN A CLONE DIES
# -----------------------------------------------
func on_clone_died(clone):
	clones_on_field.erase(clone)
	print("Clones remaining: ", clones_on_field.size())

	# If the player was controlling this clone, boot them out
	if controlled_clone == clone:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		exit_first_person()
		print("Your clone was killed! You're back in the overview.")

	# All clones gone — trigger the Last Stand!
	if clones_on_field.is_empty():
		trigger_last_stand()

# -----------------------------------------------
# WHEN AN ENEMY DIES
# -----------------------------------------------
func on_enemy_died(enemy):
	enemies_on_field.erase(enemy)
	print("Enemies remaining: ", enemies_on_field.size())

	# Boss slayer achievement!
	if enemy.is_in_group("boss"):
		Achievements.unlock("boss_slayer")

	# Tell the WaveManager an enemy died (wave mode only)
	if wave_manager and is_instance_valid(wave_manager):
		wave_manager.on_enemy_died()
		return   # In wave mode, WaveManager decides when battle ends

	if enemies_on_field.is_empty():
		battle_won()

# -----------------------------------------------
# THE LAST STAND
# -----------------------------------------------
func trigger_last_stand():
	if last_stand_used:
		battle_lost()
		return

	last_stand_used = true
	SoundManager.play("last_stand")
	print("")
	print("============================")
	print("  *** THE LAST STAND! ***")
	print("============================")
	print("One final clone appears — it's all down to you!")

	# Spawn a last-stand clone at the centre of the field
	var last_clone_scene = load("res://scenes/Clone.tscn")
	var last_clone = last_clone_scene.instantiate()
	last_clone.weapon = get_best_unlocked_weapon()
	last_clone.position = Vector3(0, 0.1, 0)
	add_child(last_clone)
	clones_on_field.append(last_clone)

	# Automatically take control of it
	controlled_clone = last_clone
	last_clone.take_player_control()

# -----------------------------------------------
# SPAWN THE BOSS
# -----------------------------------------------
func spawn_boss():
	var boss_scene = load("res://scenes/BossEnemy.tscn")
	var boss = boss_scene.instantiate()
	# Boss appears at the back of the enemy zone, centre
	boss.position = Vector3(0, 0.1, 12)
	# Scale health by difficulty too
	boss.health = boss.health * get_enemy_health_multiplier()
	add_child(boss)
	enemies_on_field.append(boss)
	print("⚠️  BOSS SPAWNED! Watch out!")

# -----------------------------------------------
# POWER-UPS — spawn one every 12 seconds
# -----------------------------------------------
func _start_powerup_timer():
	var timer = Timer.new()
	timer.wait_time = 12.0
	timer.autostart = true
	timer.timeout.connect(_spawn_random_powerup)
	add_child(timer)

func _spawn_random_powerup():
	if battle_over:
		return
	# Pick a random spot in the middle of the field
	var x = randf_range(-12.0, 12.0)
	var z = randf_range(-8.0, 8.0)

	var types = ["health", "speed", "shield"]
	var chosen = types[randi() % types.size()]

	var pu = load("res://scenes/PowerUp.tscn")
	if pu == null:
		# Build a power-up node directly if the scene doesn't exist yet
		var node = Area3D.new()
		node.set_script(load("res://scripts/PowerUp.gd"))
		node.set("type", chosen)
		node.position = Vector3(x, 0.5, z)
		add_child(node)
	else:
		var inst = pu.instantiate()
		inst.position = Vector3(x, 0.5, z)
		if inst.has_method("set"):
			inst.set("type", chosen)
		add_child(inst)

	print("⚡  Power-up spawned: ", chosen, " at (", x, ", ", z, ")")

func get_best_unlocked_weapon() -> String:
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		var unlocked = game_manager.unlocked_weapons
		return unlocked[unlocked.size() - 1]
	return "pistol"

# -----------------------------------------------
# BATTLE OUTCOMES
# -----------------------------------------------
func show_result(won: bool):
	if battle_over:
		return
	battle_over = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	SoundManager.stop_music()

	if won and game_manager:
		game_manager.add_win()

	# Play a victory or defeat sting!
	if won:
		SoundManager.play("victory_sting")
	else:
		SoundManager.play("defeat_sting")

	# Show the result overlay on top of the battlefield
	var result_scene = load("res://scenes/BattleResult.tscn")
	var result = result_scene.instantiate()
	get_tree().root.add_child(result)
	if won:
		result.show_victory()
	else:
		result.show_defeat()

func battle_won():
	# Check achievements
	Achievements.check_wins()
	if last_stand_used:
		Achievements.unlock("last_stand_win")
	if clones_on_field.size() == 1:
		Achievements.unlock("survivor")
	show_result(true)

func battle_lost():
	show_result(false)

# -----------------------------------------------
# COINS — collected mid-battle to buy upgrades
# -----------------------------------------------
func collect_coin(value: int):
	battle_coins += value
	_update_coin_label()

func _update_coin_label():
	if _coin_label and is_instance_valid(_coin_label):
		_coin_label.text = "💰 " + str(battle_coins) + " coins"

func _build_coin_hud():
	var canvas = CanvasLayer.new()
	canvas.layer = 4
	add_child(canvas)

	# Coin counter (top left)
	var bg = Panel.new()
	bg.set_anchor(SIDE_LEFT, 0); bg.set_anchor(SIDE_RIGHT, 0)
	bg.set_anchor(SIDE_TOP,  0); bg.set_anchor(SIDE_BOTTOM, 0)
	bg.offset_left = 10; bg.offset_right = 180
	bg.offset_top  = 10; bg.offset_bottom = 42
	canvas.add_child(bg)

	_coin_label = Label.new()
	_coin_label.text = "💰 0 coins"
	_coin_label.add_theme_font_size_override("font_size", 14)
	_coin_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	_coin_label.position = Vector2(8, 4)
	_coin_label.size     = Vector2(160, 28)
	_coin_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(_coin_label)

	# Upgrade buttons (below the coin counter)
	var upgrades = [
		{"label": "❤ +50 HP  (3💰)",   "cost": 3, "action": "buy_health"},
		{"label": "⚡ Speed    (4💰)",  "cost": 4, "action": "buy_speed"},
		{"label": "🛡 Shield    (5💰)", "cost": 5, "action": "buy_shield"},
	]
	for i in upgrades.size():
		var u = upgrades[i]
		var btn = Button.new()
		btn.text = u["label"]
		btn.add_theme_font_size_override("font_size", 12)
		btn.set_anchor(SIDE_LEFT, 0); btn.set_anchor(SIDE_RIGHT, 0)
		btn.set_anchor(SIDE_TOP,  0); btn.set_anchor(SIDE_BOTTOM, 0)
		btn.offset_left  = 10
		btn.offset_right = 180
		btn.offset_top   = 48 + i * 36
		btn.offset_bottom = 80 + i * 36
		var action = u["action"]
		var cost   = u["cost"]
		btn.pressed.connect(func(): _buy_upgrade(action, cost))
		canvas.add_child(btn)

func _buy_upgrade(action: String, cost: int):
	if battle_coins < cost:
		print("Not enough coins! Need ", cost, ", have ", battle_coins)
		return

	battle_coins -= cost
	_update_coin_label()
	SoundManager.play("click")

	Achievements.coins_spent_battle += cost
	if Achievements.coins_spent_battle >= 20:
		Achievements.unlock("rich")

	# Apply the upgrade to ALL living clones
	for clone in clones_on_field:
		if not is_instance_valid(clone):
			continue
		match action:
			"buy_health":
				clone.health = min(clone.health + 50.0, 200.0)
				print("❤ All clones healed +50 HP!")
			"buy_speed":
				clone.move_speed = min(clone.move_speed * 1.4, 12.0)
				print("⚡ All clones got faster!")
			"buy_shield":
				clone.activate_shield(2)
				print("🛡 All clones got a shield!")

# -----------------------------------------------
# JEEP — spawns one jeep near the player zone
# -----------------------------------------------
func _spawn_jeep():
	var jeep = CharacterBody3D.new()
	jeep.set_script(load("res://scripts/Jeep.gd"))
	jeep.position = Vector3(10.0, 0.1, -8.0)
	add_child(jeep)
	print("🚗 A jeep has spawned! Click it to drive.")

# -----------------------------------------------
# TRAPS — spawn walls/spikes saved in GameManager
# -----------------------------------------------
func _spawn_traps():
	if not game_manager:
		return
	var trap_data = game_manager.trap_data if game_manager.has_meta("trap_data") else []
	# trap_data is an array of {type, position}
	for t in trap_data:
		var trap = StaticBody3D.new()
		trap.set_script(load("res://scripts/Trap.gd"))
		trap.set("trap_type", t["type"])
		trap.position = t["position"]
		add_child(trap)

# -----------------------------------------------
# ENEMY DIED — tell WaveManager if wave mode is on
# -----------------------------------------------
