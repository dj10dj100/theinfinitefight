extends Area3D

# -----------------------------------------------
# BULLET
# A bullet flies forward and disappears when it
# hits an enemy (or a clone if fired by an enemy).
# -----------------------------------------------

var speed: float = 25.0       # How fast the bullet travels
var damage: float = 25.0      # How much damage it deals on hit
var direction: Vector3        # Which way is it flying?
var fired_by: String = ""     # "clones" or "enemies" — stops friendly fire!
var shot_by = null            # Reference to the clone that fired this bullet
var lifetime: float = 3.0     # Bullet disappears after 3 seconds if it hits nothing

func _ready():
	# Connect the "body entered" signal so we know when we hit something
	body_entered.connect(_on_body_entered)

	# Self-destruct after lifetime seconds so bullets don't pile up forever
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _process(delta):
	var old_pos = global_position
	# Wind effect — bullets drift slightly sideways during windy weather
	var weather = get_tree().get_first_node_in_group("weather")
	if weather and weather.current_weather == "wind":
		var drift = Vector3(sin(deg_to_rad(weather.wind_direction)), 0, 0) * 3.0
		position += drift * delta
	# Move the bullet forward every frame
	position += direction * speed * delta
	# Draw a glowing trail behind the bullet
	Particles.bullet_trail(old_pos, global_position)

func _on_body_entered(body):
	# Did we hit an enemy? (bullet fired by a clone)
	if fired_by == "clones" and body.is_in_group("enemies"):
		Particles.hit_sparks(global_position)
		var was_alive = body.health > 0
		body.take_damage(damage)
		# If that shot killed the enemy, give the shooter a rank kill!
		if was_alive and body.health <= 0 and is_instance_valid(shot_by):
			var rank_up = CloneRank.add_kill(shot_by)
			if rank_up != "":
				_show_rank_up(rank_up, shot_by.global_position)
				if rank_up == "General":
					Achievements.unlock("general")
			# Killstreak!
			Killstreak.add_kill(shot_by)
			# Medal tracking!
			Medals.track_kill()
			# First kill ever = achievement
			Achievements.unlock("first_blood")
		queue_free()   # Bullet disappears on hit

	# Did we hit a clone? (bullet fired by an enemy)
	elif fired_by == "enemies" and body.is_in_group("clones"):
		Particles.hit_sparks(global_position)
		body.take_damage(damage)
		queue_free()

func _show_rank_up(rank_name: String, world_pos: Vector3):
	# Show a "RANK UP!" pop-up on screen
	var canvas = CanvasLayer.new()
	var lbl = Label.new()
	lbl.text = "⭐ RANK UP! " + rank_name
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.1))
	lbl.set_anchor(SIDE_LEFT, 0.5);  lbl.set_anchor(SIDE_RIGHT, 0.5)
	lbl.set_anchor(SIDE_TOP, 0.5);   lbl.set_anchor(SIDE_BOTTOM, 0.5)
	lbl.offset_left = -160; lbl.offset_right  = 160
	lbl.offset_top  = -20;  lbl.offset_bottom = 20
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	canvas.add_child(lbl)
	get_tree().root.add_child(canvas)
	SoundManager.play("victory_sting")
	var tween = get_tree().create_tween()
	tween.tween_property(lbl, "position:y", lbl.position.y - 50, 1.8)
	tween.parallel().tween_interval(1.2)
	tween.tween_property(lbl, "modulate:a", 0.0, 0.6)
	tween.tween_callback(canvas.queue_free)
