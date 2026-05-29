extends Node

# -----------------------------------------------
# KILLSTREAK
# AutoLoad — tracks consecutive kills and gives
# rewards for big streaks!
# -----------------------------------------------

var current_streak: int = 0
var _streak_label = null   # On-screen streak counter

# Called every time a clone kills an enemy
func add_kill(clone):
	current_streak += 1
	_update_display()

	match current_streak:
		3:
			_reward_speed(clone)
			Achievements.unlock("killstreak_3")
		5:
			_reward_shield(clone)
		10:
			_reward_explosion(clone)
			Achievements.unlock("killstreak_10")

# Called when a clone dies or the battle ends — resets the streak
func reset():
	current_streak = 0
	_update_display()

func _reward_speed(clone):
	if not is_instance_valid(clone):
		return
	SoundManager.play("victory_sting")
	_show_streak_popup("🔥 3 KILLS — SPEED BOOST!", Color(1.0, 0.6, 0.1))
	# Double the clone's move speed for 8 seconds
	clone.move_speed *= 2.0
	await get_tree().create_timer(8.0).timeout
	if is_instance_valid(clone):
		clone.move_speed /= 2.0

func _reward_shield(clone):
	if not is_instance_valid(clone):
		return
	SoundManager.play("victory_sting")
	_show_streak_popup("⚡ 5 KILLS — SHIELD ACTIVATED!", Color(0.3, 0.7, 1.0))
	clone.activate_shield(3)

func _reward_explosion(clone):
	if not is_instance_valid(clone):
		return
	SoundManager.play("death")
	_show_streak_popup("💀 10 KILLS — SHOCKWAVE!", Color(1.0, 0.2, 0.9))
	# Massive area explosion — hurts all nearby enemies
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var dist = clone.global_position.distance_to(enemy.global_position)
		if dist <= 10.0:
			enemy.take_damage(150.0)
	Particles.death_explosion(clone.global_position + Vector3(0, 1, 0), Color(1.0, 0.3, 1.0))

func _show_streak_popup(text: String, colour: Color):
	var canvas = CanvasLayer.new()
	canvas.layer = 10

	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", colour)
	lbl.set_anchor(SIDE_LEFT, 0.5); lbl.set_anchor(SIDE_RIGHT, 0.5)
	lbl.set_anchor(SIDE_TOP, 0.5);  lbl.set_anchor(SIDE_BOTTOM, 0.5)
	lbl.offset_left  = -300; lbl.offset_right  = 300
	lbl.offset_top   = -80;  lbl.offset_bottom = -20
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(lbl)
	get_tree().root.add_child(canvas)

	var tween = get_tree().create_tween()
	tween.tween_property(lbl, "position:y", lbl.position.y - 40, 1.5)
	tween.parallel().tween_interval(1.0)
	tween.tween_property(lbl, "modulate:a", 0.0, 0.5)
	tween.tween_callback(canvas.queue_free)

func _update_display():
	# Show the streak count in the top-left corner during a battle
	if _streak_label == null or not is_instance_valid(_streak_label):
		_streak_label = null
		return

	if current_streak >= 2:
		_streak_label.text = "🔥 " + str(current_streak) + " kill streak!"
		_streak_label.visible = true
	else:
		_streak_label.visible = false

# Call this from Battlefield to register the label
func register_label(lbl):
	_streak_label = lbl
