extends Node

# -----------------------------------------------
# DAILY CHALLENGE 🏆
# Every day a new challenge appears!
# Complete it to earn bonus coins or a secret unlock.
#
# Challenges rotate based on today's date — so every
# day is different, and it resets automatically!
#
# To check the challenge from anywhere:
#   DailyChallenge.get_today()         → challenge dict
#   DailyChallenge.complete()          → mark done, give reward
#   DailyChallenge.is_done_today()     → true/false
# -----------------------------------------------

# All possible daily challenges
const CHALLENGES = [
	{
		"title":       "Pistols Only",
		"description": "Win a battle using only the Pistol!",
		"icon":        "🔫",
		"check":       "pistol_only",
		"reward":      "5 bonus coins",
	},
	{
		"title":       "Speedy Victory",
		"description": "Win a battle in under 60 seconds!",
		"icon":        "⚡",
		"check":       "win_under_60s",
		"reward":      "Lightning Gun unlock hint",
	},
	{
		"title":       "No Losses",
		"description": "Win a battle without losing a single clone!",
		"icon":        "🛡️",
		"check":       "no_clone_lost",
		"reward":      "Shield for all clones next battle",
	},
	{
		"title":       "Grenade Master",
		"description": "Throw 5 grenades in one battle!",
		"icon":        "💣",
		"check":       "grenade_x5",
		"reward":      "Grenade cooldown halved next battle",
	},
	{
		"title":       "Survive the Waves",
		"description": "Survive 5 waves in Wave Mode!",
		"icon":        "🌊",
		"check":       "wave_5",
		"reward":      "Double coins next battle",
	},
	{
		"title":       "Boss Hunter",
		"description": "Defeat the boss enemy!",
		"icon":        "🐉",
		"check":       "boss_slayer",
		"reward":      "Secret skin unlock",
	},
	{
		"title":       "Sharpshooter",
		"description": "Get a 10-kill streak!",
		"icon":        "🎯",
		"check":       "killstreak_10",
		"reward":      "Sniper Rifle ammo doubled next battle",
	},
	{
		"title":       "Helicopter Ace",
		"description": "Kill 3 enemies while flying the helicopter!",
		"icon":        "🚁",
		"check":       "heli_kills_3",
		"reward":      "Helicopter gets a rocket launcher!",
	},
	{
		"title":       "The Tank",
		"description": "Win a battle with just ONE clone!",
		"icon":        "💪",
		"check":       "one_clone_win",
		"reward":      "That clone gets double health next time",
	},
	{
		"title":       "Lightning Round",
		"description": "Kill 10 enemies in 30 seconds!",
		"icon":        "⚡",
		"check":       "10_kills_30s",
		"reward":      "Speed boost for all clones next battle",
	},
	{
		"title":       "Airstrike Ace",
		"description": "Call 3 airstrikes in one battle!",
		"icon":        "✈️",
		"check":       "airstrike_x3",
		"reward":      "Airstrike cooldown halved next battle",
	},
	{
		"title":       "Minefield",
		"description": "Plant 4 landmines in one battle!",
		"icon":        "💥",
		"check":       "mine_x4",
		"reward":      "Mines do double damage next battle",
	},
	{
		"title":       "Collector",
		"description": "Collect 15 battle coins in one battle!",
		"icon":        "🪙",
		"check":       "coins_15",
		"reward":      "Start next battle with 5 free coins",
	},
	{
		"title":       "Rocket Science",
		"description": "Kill 5 enemies with the Rocket Launcher!",
		"icon":        "🚀",
		"check":       "rocket_kills_5",
		"reward":      "Extra rocket ammo next battle",
	},
]

# Runtime tracking for the current battle
var grenade_count:    int = 0
var airstrike_count:  int = 0
var mine_count:       int = 0
var heli_kills:       int = 0
var battle_start_time: float = 0.0
var clones_lost:      int = 0

func _ready():
	print("🏆 Daily Challenge today: ", get_today()["icon"], " ", get_today()["title"])

# -----------------------------------------------
# Get today's challenge (changes every day!)
# -----------------------------------------------
func get_today() -> Dictionary:
	# Use today's date as a seed so it's the same for everyone on that day
	var t     = Time.get_date_dict_from_system()
	var seed  = t["year"] * 10000 + t["month"] * 100 + t["day"]
	var index = seed % CHALLENGES.size()
	return CHALLENGES[index]

# -----------------------------------------------
# Check if player already completed today's challenge
# -----------------------------------------------
func is_done_today() -> bool:
	var today_key = _today_key()
	return GameManager.has_meta("challenge_done_" + today_key) and \
		   GameManager.get_meta("challenge_done_" + today_key) == true

# -----------------------------------------------
# Mark today's challenge as complete + give reward
# -----------------------------------------------
func complete():
	if is_done_today():
		return   # Already done today!

	var challenge = get_today()
	GameManager.set_meta("challenge_done_" + _today_key(), true)

	print("🏆 DAILY CHALLENGE COMPLETE! ", challenge["title"])
	print("🎁 Reward: ", challenge["reward"])

	# Show a big celebration banner!
	_show_complete_banner(challenge)

# -----------------------------------------------
# Show the challenge on screen (call this from HUD)
# -----------------------------------------------
func show_challenge_popup():
	var c = get_today()
	var canvas = CanvasLayer.new()

	var panel = PanelContainer.new()
	panel.position = Vector2(20, 80)
	panel.size     = Vector2(280, 90)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.15, 0.88)
	style.corner_radius_top_left    = 10
	style.corner_radius_top_right   = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.border_width_left  = 2; style.border_width_right  = 2
	style.border_width_top   = 2; style.border_width_bottom = 2
	style.border_color = Color(1.0, 0.8, 0.0, 0.8)
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	var title_lbl = Label.new()
	title_lbl.text = c["icon"] + " DAILY CHALLENGE"
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))

	var desc_lbl = Label.new()
	desc_lbl.text = c["title"] + ": " + c["description"]
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var reward_lbl = Label.new()
	reward_lbl.text = "🎁 " + c["reward"]
	reward_lbl.add_theme_font_size_override("font_size", 11)
	reward_lbl.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))

	if is_done_today():
		title_lbl.text = "✅ CHALLENGE COMPLETE!"

	vbox.add_child(title_lbl)
	vbox.add_child(desc_lbl)
	vbox.add_child(reward_lbl)
	panel.add_child(vbox)
	canvas.add_child(panel)
	get_tree().root.add_child(canvas)

	# Auto-hide after 5 seconds
	await get_tree().create_timer(5.0).timeout
	if is_instance_valid(canvas):
		canvas.queue_free()

func _show_complete_banner(c: Dictionary):
	var canvas = CanvasLayer.new()
	var lbl = Label.new()
	lbl.text = "🏆 DAILY CHALLENGE DONE!\n" + c["icon"] + " " + c["title"] + "\n🎁 " + c["reward"]
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.1))
	lbl.set_anchor(SIDE_LEFT, 0.5);  lbl.set_anchor(SIDE_RIGHT, 0.5)
	lbl.set_anchor(SIDE_TOP, 0.25);  lbl.set_anchor(SIDE_BOTTOM, 0.25)
	lbl.offset_left = -300; lbl.offset_right = 300
	lbl.offset_top  = -40;  lbl.offset_bottom = 40
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	canvas.add_child(lbl)
	get_tree().root.add_child(canvas)
	SoundManager.play("victory_sting")
	var tw = get_tree().create_tween()
	tw.tween_interval(3.0)
	tw.tween_property(lbl, "modulate:a", 0.0, 1.0)
	tw.tween_callback(canvas.queue_free)

func _today_key() -> String:
	var t = Time.get_date_dict_from_system()
	return str(t["year"]) + "_" + str(t["month"]) + "_" + str(t["day"])
