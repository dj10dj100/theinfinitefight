extends Node

# -----------------------------------------------
# MEDALS & TROPHIES 🏅
# Awarded at the end of each battle for doing
# something impressive! They're saved forever.
#
# From anywhere:
#   Medals.track_kill()          — call each enemy kill
#   Medals.track_damage(amount)  — call when clone takes damage
#   Medals.battle_start()        — call at start of battle
#   Medals.battle_end(won, clones_alive) — call at end
# -----------------------------------------------

# All medals defined here
const ALL_MEDALS = {
	"speed_demon": {
		"name":  "⚡ Speed Demon",
		"desc":  "Win a battle in under 30 seconds!",
		"icon":  "⚡",
		"rare":  false,
	},
	"untouchable": {
		"name":  "🛡️ Untouchable",
		"desc":  "Win without any clone taking damage!",
		"icon":  "🛡️",
		"rare":  true,
	},
	"killing_machine": {
		"name":  "💀 Killing Machine",
		"desc":  "Get 20 kills in one battle!",
		"icon":  "💀",
		"rare":  false,
	},
	"lone_wolf": {
		"name":  "🐺 Lone Wolf",
		"desc":  "Win with only 1 clone left!",
		"icon":  "🐺",
		"rare":  false,
	},
	"full_squad": {
		"name":  "👥 Full Squad",
		"desc":  "Win with all your clones still alive!",
		"icon":  "👥",
		"rare":  true,
	},
	"lightning_round": {
		"name":  "🌩️ Lightning Round",
		"desc":  "Get 10 kills in under 20 seconds!",
		"icon":  "🌩️",
		"rare":  true,
	},
	"tough_as_nails": {
		"name":  "🔩 Tough as Nails",
		"desc":  "Win after all your clones were below 20 HP!",
		"icon":  "🔩",
		"rare":  true,
	},
	"sharpshooter": {
		"name":  "🎯 Sharpshooter",
		"desc":  "Win a battle with the Sniper Rifle only!",
		"icon":  "🎯",
		"rare":  false,
	},
	"collector": {
		"name":  "🪙 Collector",
		"desc":  "Collect 20 coins in one battle!",
		"icon":  "🪙",
		"rare":  false,
	},
	"legendary": {
		"name":  "🌟 LEGENDARY",
		"desc":  "Win without losing a single clone AND in under 45 seconds!",
		"icon":  "🌟",
		"rare":  true,
	},
}

# Battle tracking
var _battle_start_time: float = 0.0
var _kill_count: int          = 0
var _damage_taken: float      = 0.0
var _kill_timer: float        = 0.0
var _kills_in_window: int     = 0
var _min_clone_hp: float      = 999.0   # Lowest any clone dropped to
var _coins_collected: int     = 0

func _ready():
	print("🏅 Medals system ready!")

func _process(delta):
	if _kill_timer > 0:
		_kill_timer -= delta
	else:
		_kills_in_window = 0

# -----------------------------------------------
# TRACKING — call these from the game
# -----------------------------------------------
func battle_start():
	_battle_start_time  = Time.get_ticks_msec() / 1000.0
	_kill_count         = 0
	_damage_taken       = 0.0
	_kill_timer         = 0.0
	_kills_in_window    = 0
	_min_clone_hp       = 999.0
	_coins_collected    = 0

func track_kill():
	_kill_count      += 1
	_kills_in_window += 1
	_kill_timer       = 20.0   # Reset the 20-second window

func track_damage(amount: float):
	_damage_taken += amount

func track_clone_hp(hp: float):
	_min_clone_hp = min(_min_clone_hp, hp)

func track_coin():
	_coins_collected += 1

func battle_end(won: bool, clones_alive: int, total_clones: int):
	if not won:
		return   # No medals for losing — gotta win 'em!

	var elapsed = (Time.get_ticks_msec() / 1000.0) - _battle_start_time
	var earned: Array = []

	# Check every medal
	if elapsed < 30.0:
		earned.append("speed_demon")
	if _damage_taken == 0.0:
		earned.append("untouchable")
	if _kill_count >= 20:
		earned.append("killing_machine")
	if clones_alive == 1:
		earned.append("lone_wolf")
	if clones_alive == total_clones:
		earned.append("full_squad")
	if _kills_in_window >= 10:
		earned.append("lightning_round")
	if _min_clone_hp < 20.0 and won:
		earned.append("tough_as_nails")
	if _coins_collected >= 20:
		earned.append("collector")
	if _damage_taken == 0.0 and elapsed < 45.0:
		earned.append("legendary")

	# Save and show each earned medal
	for key in earned:
		_unlock_medal(key)

func _unlock_medal(key: String):
	# Don't show it again if already earned before (but still count it)
	var save_key = "medal_" + key
	var already_had = GameManager.has_meta(save_key)
	GameManager.set_meta(save_key, true)

	var medal = ALL_MEDALS[key]
	print("🏅 MEDAL EARNED: ", medal["name"])
	_show_medal_popup(medal, not already_had)

func _show_medal_popup(medal: Dictionary, is_new: bool):
	var canvas = CanvasLayer.new()
	canvas.layer = 20

	var panel = PanelContainer.new()
	panel.set_anchor(SIDE_RIGHT, 1.0)
	panel.set_anchor(SIDE_BOTTOM, 0.0)
	panel.offset_left   = -320
	panel.offset_top    = 20
	panel.offset_right  = -20
	panel.offset_bottom = 100

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.02, 0.92) if not medal["rare"] else Color(0.10, 0.04, 0.18, 0.95)
	style.border_color = Color(1.0, 0.8, 0.1) if not medal["rare"] else Color(0.8, 0.2, 1.0)
	style.border_width_left   = 3; style.border_width_right  = 3
	style.border_width_top    = 3; style.border_width_bottom = 3
	style.corner_radius_top_left    = 10; style.corner_radius_top_right   = 10
	style.corner_radius_bottom_left = 10; style.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)

	var icon_lbl = Label.new()
	icon_lbl.text = medal["icon"]
	icon_lbl.add_theme_font_size_override("font_size", 32)

	var vbox = VBoxContainer.new()
	var title_lbl = Label.new()
	title_lbl.text = ("🆕 " if is_new else "") + medal["name"]
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1) if not medal["rare"] else Color(0.9, 0.5, 1.0))

	var desc_lbl = Label.new()
	desc_lbl.text = medal["desc"]
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

	vbox.add_child(title_lbl)
	vbox.add_child(desc_lbl)
	hbox.add_child(icon_lbl)
	hbox.add_child(vbox)
	panel.add_child(hbox)
	canvas.add_child(panel)
	get_tree().root.add_child(canvas)

	SoundManager.play("victory_sting")

	# Slide in from the right, wait, slide back out
	panel.position.x = 400
	var tw = get_tree().create_tween()
	tw.tween_property(panel, "position:x", 0.0, 0.35)
	tw.tween_interval(3.0)
	tw.tween_property(panel, "position:x", 400.0, 0.35)
	tw.tween_callback(canvas.queue_free)

# How many unique medals earned so far?
func total_earned() -> int:
	var count = 0
	for key in ALL_MEDALS:
		if GameManager.has_meta("medal_" + key):
			count += 1
	return count
