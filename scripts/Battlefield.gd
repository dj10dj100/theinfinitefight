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

@onready var top_down_camera = $TopDownCamera
@onready var first_person_camera = $FirstPersonCamera

func _ready():
	add_to_group("battlefield")
	game_manager = get_node_or_null("/root/GameManager")

	# Spawn the HUD (hidden until first-person mode)
	var hud_scene = load("res://scenes/HUD.tscn")
	hud = hud_scene.instantiate()
	add_child(hud)

	# Wait one frame so the scene is fully loaded
	await get_tree().process_frame

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

	# Start with the top-down view
	top_down_camera.current = true
	first_person_camera.current = false

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
	print("Spawned ", deploy_data.size(), " clones from deploy screen!")

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

	if won and game_manager:
		game_manager.add_win()

	# Show the result overlay on top of the battlefield
	var result_scene = load("res://scenes/BattleResult.tscn")
	var result = result_scene.instantiate()
	get_tree().root.add_child(result)
	if won:
		result.show_victory()
	else:
		result.show_defeat()

func battle_won():
	show_result(true)

func battle_lost():
	show_result(false)
