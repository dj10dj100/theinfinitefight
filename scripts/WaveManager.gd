extends Node

# -----------------------------------------------
# WAVE MANAGER
# Runs the endless wave mode!
# Each wave spawns more enemies than the last.
# Between waves you get 10 seconds to breathe.
# -----------------------------------------------

var current_wave: int = 0
var wave_active: bool = false
var enemies_alive: int = 0
var _wave_label = null
var _wave_canvas = null
var battlefield = null

func start(bf):
	battlefield = bf
	current_wave = 0
	_build_wave_hud()
	_start_next_wave()

func _build_wave_hud():
	_wave_canvas = CanvasLayer.new()
	_wave_canvas.layer = 6
	battlefield.add_child(_wave_canvas)

	var bg = Panel.new()
	bg.set_anchor(SIDE_LEFT, 0.5); bg.set_anchor(SIDE_RIGHT, 0.5)
	bg.set_anchor(SIDE_TOP,  0);   bg.set_anchor(SIDE_BOTTOM, 0)
	bg.offset_left  = -120; bg.offset_right  = 120
	bg.offset_top   = 10;   bg.offset_bottom = 48
	_wave_canvas.add_child(bg)

	_wave_label = Label.new()
	_wave_label.text = "Wave 1"
	_wave_label.add_theme_font_size_override("font_size", 20)
	_wave_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_wave_label.position = Vector2(0, 4)
	_wave_label.size     = Vector2(240, 34)
	_wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wave_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(_wave_label)

func _start_next_wave():
	current_wave += 1
	wave_active = true

	_wave_label.text = "⚔ WAVE " + str(current_wave) + "!"

	# How many enemies this wave? Starts at 3, grows each wave
	var count = 3 + (current_wave - 1) * 2

	# Every 5 waves, add a boss!
	var spawn_boss = (current_wave % 5 == 0)

	print("=== WAVE ", current_wave, " — ", count, " enemies! ===")
	_flash_wave_message("⚔  WAVE " + str(current_wave) + "  ⚔")

	await get_tree().create_timer(1.5).timeout

	# Spawn the enemies
	enemies_alive = count
	for i in count:
		await get_tree().create_timer(0.3).timeout
		_spawn_wave_enemy()

	if spawn_boss:
		await get_tree().create_timer(0.5).timeout
		_spawn_wave_boss()
		enemies_alive += 1

func _spawn_wave_enemy():
	var enemy_scene = load("res://scenes/Enemy.tscn")
	var enemy = enemy_scene.instantiate()

	# Spawn randomly along the enemy zone back line
	var x = randf_range(-15.0, 15.0)
	enemy.position = Vector3(x, 0.1, 14.0)

	# Scale health with wave number
	var health_mult = 1.0 + (current_wave - 1) * 0.25
	enemy.health = 200.0 * health_mult

	battlefield.add_child(enemy)
	battlefield.enemies_on_field.append(enemy)

func _spawn_wave_boss():
	var boss_scene = load("res://scenes/BossEnemy.tscn")
	var boss = boss_scene.instantiate()
	boss.position = Vector3(0, 0.1, 14.0)
	boss.health = 1000.0 * (1.0 + (current_wave - 1) * 0.2)
	battlefield.add_child(boss)
	battlefield.enemies_on_field.append(boss)
	_flash_wave_message("⚠  BOSS INCOMING!  ⚠")

# Called by Battlefield when an enemy dies
func on_enemy_died():
	enemies_alive -= 1
	if enemies_alive <= 0 and wave_active:
		wave_active = false
		_wave_cleared()

func _wave_cleared():
	SoundManager.play("victory_sting")
	_flash_wave_message("✅  WAVE " + str(current_wave) + " CLEARED!")
	print("Wave ", current_wave, " cleared!")

	# Heal all clones a bit between waves (reward for surviving!)
	for clone in battlefield.clones_on_field:
		if is_instance_valid(clone):
			clone.health = min(clone.health + 30.0, 200.0)

	# Give some battle coins too!
	battlefield.collect_coin(current_wave)
	print("Healed all clones +30 HP and gave ", current_wave, " coins!")

	# 10-second break before the next wave
	_wave_label.text = "Next wave in 10s..."
	await get_tree().create_timer(10.0).timeout

	if not battlefield.battle_over:
		_start_next_wave()

func _flash_wave_message(text: String):
	var canvas = CanvasLayer.new()
	canvas.layer = 9
	get_tree().root.add_child(canvas)

	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 42)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.1))
	lbl.set_anchor(SIDE_LEFT, 0.5); lbl.set_anchor(SIDE_RIGHT, 0.5)
	lbl.set_anchor(SIDE_TOP, 0.5);  lbl.set_anchor(SIDE_BOTTOM, 0.5)
	lbl.offset_left  = -300; lbl.offset_right  = 300
	lbl.offset_top   = -120; lbl.offset_bottom = -40
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(lbl)

	var tween = get_tree().create_tween()
	tween.tween_property(lbl, "modulate:a", 1.0, 0.2)
	tween.tween_interval(2.0)
	tween.tween_property(lbl, "modulate:a", 0.0, 0.5)
	tween.tween_callback(canvas.queue_free)
