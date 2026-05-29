extends Node

# -----------------------------------------------
# WEATHER SYSTEM
# Random weather happens during battle!
# Each map has its own possible weather types.
#
# Weather types:
#   clear   — no effect (default)
#   rain    — dark overlay, clones move 15% slower
#   storm   — heavy rain + lightning flashes!
#   snow    — white particles, clones move 25% slower
#   wind    — bullets drift sideways!
# -----------------------------------------------

const WEATHER_BY_MAP = {
	"grassland": ["clear", "clear", "rain", "storm"],
	"jungle":    ["rain",  "rain",  "storm", "clear"],
	"city":      ["clear", "rain",  "storm", "clear"],
	"snow":      ["snow",  "snow",  "snow",  "clear"],
	"night":     ["clear", "rain",  "storm", "clear"],
}

var current_weather: String = "clear"
var wind_direction:  float  = 0.0   # Degrees, used by bullets
var _overlay:        ColorRect = null
var _label:          Label     = null
var _particles:      Array     = []
var _lightning_timer: float    = 0.0
var _battlefield     = null

func _ready():
	_pick_weather()
	_build_overlay()
	_apply_weather()
	print("⛅ Today's weather: ", current_weather)

func _pick_weather():
	var map    = GameManager.selected_map if GameManager else "grassland"
	var opts   = WEATHER_BY_MAP.get(map, ["clear"])
	current_weather = opts[randi() % opts.size()]
	wind_direction  = randf_range(-35.0, 35.0)

func _build_overlay():
	var canvas = CanvasLayer.new()
	canvas.layer = 2
	add_child(canvas)

	# Semi-transparent tint for rain/snow/storm
	_overlay = ColorRect.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.color       = Color(0, 0, 0, 0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(_overlay)

	# Weather label top-centre
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 17)
	_label.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0, 0.85))
	_label.set_anchor(SIDE_LEFT, 0.5); _label.set_anchor(SIDE_RIGHT, 0.5)
	_label.set_anchor(SIDE_TOP, 0);    _label.set_anchor(SIDE_BOTTOM, 0)
	_label.offset_left   = -120; _label.offset_right  = 120
	_label.offset_top    = 8;    _label.offset_bottom = 36
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(_label)

func _apply_weather():
	match current_weather:
		"clear":
			_label.text = ""
		"rain":
			_overlay.color = Color(0.05, 0.08, 0.15, 0.28)
			_label.text    = "🌧 Rain"
			_spawn_rain_drops(120)
			_slow_clones(0.85)
		"storm":
			_overlay.color = Color(0.02, 0.04, 0.10, 0.45)
			_label.text    = "⛈ Storm!"
			_spawn_rain_drops(220)
			_slow_clones(0.75)
			_lightning_timer = randf_range(3.0, 7.0)
		"snow":
			_overlay.color = Color(0.7, 0.8, 0.9, 0.12)
			_label.text    = "❄️ Snowfall"
			_spawn_snow_flakes(80)
			_slow_clones(0.75)
		"wind":
			_label.text = "💨 Strong Wind  (bullets drift!)"

func _process(delta):
	# Animate rain/snow particles falling
	for p in _particles:
		if is_instance_valid(p):
			p.position.y += p.get_meta("speed") * delta
			p.position.x += p.get_meta("drift") * delta
			# Wrap back to top when off screen
			if p.position.y > 620:
				p.position.y = -10
				p.position.x = randf_range(0, 1280)

	# Lightning flash during storms
	if current_weather == "storm":
		_lightning_timer -= delta
		if _lightning_timer <= 0:
			_lightning_timer = randf_range(4.0, 10.0)
			_do_lightning_flash()

func _slow_clones(multiplier: float):
	# Apply speed reduction to all clones already on the field
	await get_tree().process_frame
	for clone in get_tree().get_nodes_in_group("clones"):
		clone.move_speed *= multiplier

func _spawn_rain_drops(count: int):
	var canvas = get_child(0)   # The CanvasLayer we made
	for i in range(count):
		var drop = ColorRect.new()
		drop.color = Color(0.6, 0.75, 1.0, randf_range(0.3, 0.6))
		drop.size  = Vector2(1.5, randf_range(10, 22))
		drop.position = Vector2(randf_range(0, 1280), randf_range(0, 620))
		drop.set_meta("speed", randf_range(380, 560))
		drop.set_meta("drift", randf_range(-20, -5))
		drop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(drop)
		_particles.append(drop)

func _spawn_snow_flakes(count: int):
	var canvas = get_child(0)
	for i in range(count):
		var flake = ColorRect.new()
		flake.color = Color(0.92, 0.95, 1.0, randf_range(0.5, 0.9))
		var sz = randf_range(3, 7)
		flake.size     = Vector2(sz, sz)
		flake.position = Vector2(randf_range(0, 1280), randf_range(0, 620))
		flake.set_meta("speed", randf_range(60, 130))
		flake.set_meta("drift", randf_range(-18, 18))
		flake.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(flake)
		_particles.append(flake)

func _do_lightning_flash():
	var canvas = get_child(0)
	var flash = ColorRect.new()
	flash.color = Color(0.9, 0.9, 1.0, 0.55)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(flash)
	SoundManager.play("last_stand")
	var tween = get_tree().create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.18)
	tween.tween_callback(flash.queue_free)
