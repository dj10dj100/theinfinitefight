extends Node3D

# -----------------------------------------------
# CAPTURE THE FLAG 🚩
# Phase 18c!
#
# Green flag = YOUR flag (defend it!)
# Red flag   = ENEMY flag (steal it!)
#
# Walk a clone onto the red flag to pick it up.
# Carry it all the way back to YOUR green flag to score!
# Enemies try to grab your green flag too.
# First team to 3 captures WINS!
# -----------------------------------------------

const CAPTURES_TO_WIN = 3

var player_score: int = 0
var enemy_score:  int = 0

# Flag state
var _player_flag_pos: Vector3   = Vector3(-14, 0, -8)   # Near player base
var _enemy_flag_pos:  Vector3   = Vector3( 14, 0,  8)   # Near enemy base

var _player_flag_node: Node3D = null   # The actual flag object
var _enemy_flag_node:  Node3D = null

var _enemy_flag_carrier  = null   # Clone carrying the enemy flag (null = on ground)
var _player_flag_carrier = null   # Enemy carrying the player flag (null = on ground)

var _score_label: Label = null
var _hud_canvas:  CanvasLayer = null

func _ready():
	_spawn_flag("player", _player_flag_pos)
	_spawn_flag("enemy",  _enemy_flag_pos)
	_build_score_hud()
	print("🚩 CAPTURE THE FLAG MODE! Grab the red flag and bring it back to your green flag. First to 3 wins!")

# -----------------------------------------------
# Build a flag pole with a coloured flag on top
# -----------------------------------------------
func _spawn_flag(team: String, pos: Vector3):
	var flag_node = Node3D.new()
	flag_node.position = pos
	add_child(flag_node)

	# Pole
	var pole = MeshInstance3D.new()
	var pm = CylinderMesh.new()
	pm.top_radius    = 0.04
	pm.bottom_radius = 0.04
	pm.height        = 2.5
	pole.mesh = pm
	var pmat = StandardMaterial3D.new()
	pmat.albedo_color = Color(0.7, 0.7, 0.7)
	pmat.roughness    = 0.4
	pole.set_surface_override_material(0, pmat)
	pole.position = Vector3(0, 1.25, 0)
	flag_node.add_child(pole)

	# Flag cloth
	var cloth = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(0.7, 0.45, 0.06)
	cloth.mesh = bm
	var cmat = StandardMaterial3D.new()
	cmat.albedo_color     = Color(0.1, 0.9, 0.2) if team == "player" else Color(0.9, 0.1, 0.1)
	cmat.emission_enabled = true
	cmat.emission         = (Color(0.0, 0.5, 0.0) if team == "player" else Color(0.5, 0.0, 0.0))
	cmat.roughness        = 0.8
	cloth.set_surface_override_material(0, cmat)
	cloth.position = Vector3(0.38, 2.35, 0)
	flag_node.add_child(cloth)

	# Glow light
	var light = OmniLight3D.new()
	light.light_color  = Color(0.1, 1.0, 0.1) if team == "player" else Color(1.0, 0.1, 0.1)
	light.light_energy = 1.5
	light.omni_range   = 4.0
	light.position     = Vector3(0, 2.0, 0)
	flag_node.add_child(light)

	# Pickup zone (Area3D)
	var area = Area3D.new()
	var shape = CollisionShape3D.new()
	shape.shape = CylinderShape3D.new()
	shape.shape.radius = 1.2
	shape.shape.height = 2.0
	shape.position = Vector3(0, 1.0, 0)
	area.add_child(shape)
	area.body_entered.connect(func(body): _on_flag_zone_entered(body, team))
	flag_node.add_child(area)

	if team == "player":
		_player_flag_node = flag_node
	else:
		_enemy_flag_node = flag_node

# -----------------------------------------------
# Score HUD — shows 🟢 2 – 1 🔴 at the top
# -----------------------------------------------
func _build_score_hud():
	_hud_canvas = CanvasLayer.new()
	_hud_canvas.layer = 12
	get_tree().root.add_child(_hud_canvas)

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.55)
	bg.set_anchor(SIDE_LEFT,  0.35); bg.set_anchor(SIDE_RIGHT,  0.65)
	bg.set_anchor(SIDE_TOP,   0.0);  bg.set_anchor(SIDE_BOTTOM, 0.0)
	bg.offset_top    = 6
	bg.offset_bottom = 46
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_canvas.add_child(bg)

	_score_label = Label.new()
	_score_label.add_theme_font_size_override("font_size", 24)
	_score_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_score_label.set_anchor(SIDE_LEFT,  0.0); _score_label.set_anchor(SIDE_RIGHT,  1.0)
	_score_label.set_anchor(SIDE_TOP,   0.0); _score_label.set_anchor(SIDE_BOTTOM, 1.0)
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(_score_label)

	_update_hud()

func _update_hud():
	if _score_label:
		_score_label.text = "🟢 %d  –  %d 🔴" % [player_score, enemy_score]

# -----------------------------------------------
# Flag zone entered
# -----------------------------------------------
func _on_flag_zone_entered(body, flag_team: String):
	if flag_team == "enemy":
		# A clone walks into the enemy flag zone — pick it up!
		if body.is_in_group("clones") and _enemy_flag_carrier == null:
			_enemy_flag_carrier = body
			_enemy_flag_node.visible = false
			SoundManager.play("victory_sting")
			_show_banner("🚩 FLAG GRABBED! Run back to your base!", Color(1.0, 0.85, 0.1))
			print("🚩 Flag picked up by ", body.clone_name if body.has_method("_add_name_label") else "a clone")

	elif flag_team == "player":
		# An enemy walks into the player flag zone
		if body.is_in_group("enemies") and _player_flag_carrier == null:
			_player_flag_carrier = body
			_player_flag_node.visible = false
			SoundManager.play("hit")
			_show_banner("⚠️ YOUR FLAG WAS STOLEN! Stop them!", Color(1.0, 0.2, 0.2))
			print("⚠️ Enemy grabbed your flag!")

		# A clone returns to base while carrying the enemy flag — SCORE!
		if body.is_in_group("clones") and _enemy_flag_carrier != null:
			_player_score_point()

# -----------------------------------------------
# Every frame — check carrier positions
# -----------------------------------------------
func _process(_delta):
	# Drop enemy flag if carrier died
	if _enemy_flag_carrier != null and not is_instance_valid(_enemy_flag_carrier):
		_drop_enemy_flag()

	# Drop player flag if carrier died
	if _player_flag_carrier != null and not is_instance_valid(_player_flag_carrier):
		_drop_player_flag()

	# Check if enemy carrier reached their base
	if _player_flag_carrier != null and is_instance_valid(_player_flag_carrier):
		if _player_flag_carrier.global_position.distance_to(_enemy_flag_pos) < 2.5:
			_enemy_score_point()

func _drop_enemy_flag():
	_enemy_flag_carrier = null
	_enemy_flag_node.visible = true
	_show_banner("🚩 Flag dropped! Pick it up!", Color(1.0, 0.85, 0.1))

func _drop_player_flag():
	_player_flag_carrier = null
	_player_flag_node.visible = true
	_show_banner("🟢 Your flag is back at base!", Color(0.3, 1.0, 0.3))

func _player_score_point():
	player_score += 1
	_enemy_flag_carrier = null
	_enemy_flag_node.global_position = _enemy_flag_pos
	_enemy_flag_node.visible = true
	_update_hud()
	SoundManager.play("victory_sting")
	_show_banner("✅ YOU SCORED! 🟢 %d – %d 🔴" % [player_score, enemy_score], Color(0.2, 1.0, 0.3))
	print("🟢 Player scores! %d – %d" % [player_score, enemy_score])
	if player_score >= CAPTURES_TO_WIN:
		_end_game(true)

func _enemy_score_point():
	enemy_score += 1
	_player_flag_carrier = null
	_player_flag_node.global_position = _player_flag_pos
	_player_flag_node.visible = true
	_update_hud()
	SoundManager.play("hit")
	_show_banner("❌ ENEMY SCORED! 🟢 %d – %d 🔴" % [player_score, enemy_score], Color(1.0, 0.2, 0.2))
	print("🔴 Enemy scores! %d – %d" % [player_score, enemy_score])
	if enemy_score >= CAPTURES_TO_WIN:
		_end_game(false)

func _end_game(player_won: bool):
	if player_won:
		_show_banner("🏆 YOU WIN! Captured the flag 3 times!", Color(1.0, 0.85, 0.1))
		await get_tree().create_timer(2.0).timeout
		get_tree().call_group("battlefield", "battle_won")
	else:
		_show_banner("💀 YOU LOSE! The enemy captured your flag 3 times!", Color(1.0, 0.2, 0.2))
		await get_tree().create_timer(2.0).timeout
		get_tree().call_group("battlefield", "battle_lost")

func _show_banner(text: String, colour: Color):
	var canvas = CanvasLayer.new()
	canvas.layer = 20
	get_tree().root.add_child(canvas)

	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color", colour)
	lbl.set_anchor(SIDE_LEFT,  0.0); lbl.set_anchor(SIDE_RIGHT,  1.0)
	lbl.set_anchor(SIDE_TOP,   0.15); lbl.set_anchor(SIDE_BOTTOM, 0.3)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.modulate.a = 0.0
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(lbl)

	var tw = get_tree().create_tween()
	tw.tween_property(lbl, "modulate:a", 1.0, 0.3)
	tw.tween_interval(2.5)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.4)
	tw.tween_callback(canvas.queue_free)

func cleanup():
	if _hud_canvas:
		_hud_canvas.queue_free()
