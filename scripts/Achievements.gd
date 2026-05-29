extends Node

# -----------------------------------------------
# ACHIEVEMENTS
# AutoLoad — tracks cool things the player does
# and pops up a badge when they earn one!
# -----------------------------------------------

# All achievements and whether they've been earned
var earned: Dictionary = {}

# The full list of achievements
const ALL = {
	"first_blood":     {"name": "First Blood",     "icon": "🩸", "desc": "Kill your first enemy"},
	"survivor":        {"name": "Survivor",         "icon": "💪", "desc": "Win a battle with only 1 clone left"},
	"grenade_master":  {"name": "Grenade Master",   "icon": "💣", "desc": "Kill 3 enemies with one grenade"},
	"airstrike_ace":   {"name": "Airstrike Ace",    "icon": "✈️", "desc": "Call 5 airstrikes total"},
	"landmine_trap":   {"name": "Landmine Trap",    "icon": "💥", "desc": "Kill an enemy with a landmine"},
	"general":         {"name": "General!",          "icon": "⭐", "desc": "Reach the rank of General"},
	"ten_wins":        {"name": "Veteran",           "icon": "🎖️", "desc": "Win 10 battles"},
	"killstreak_3":    {"name": "On Fire",           "icon": "🔥", "desc": "Get a 3-kill killstreak"},
	"killstreak_10":   {"name": "Unstoppable",       "icon": "💀", "desc": "Get a 10-kill killstreak"},
	"boss_slayer":     {"name": "Boss Slayer",       "icon": "👑", "desc": "Defeat a Boss enemy"},
	"rich":            {"name": "Big Spender",       "icon": "💰", "desc": "Spend 20 coins in one battle"},
	"last_stand_win":  {"name": "Last Stand Hero",   "icon": "🦸", "desc": "Win the battle during the Last Stand"},
}

# Counters for tracking progress
var airstrike_count: int = 0
var coins_spent_battle: int = 0

func _ready():
	_load()

func _load():
	if not GameManager:
		return
	# Load from GameManager's save data
	if GameManager.has_meta("achievements"):
		earned = GameManager.get_meta("achievements")
	else:
		earned = {}

func _save():
	if GameManager:
		GameManager.set_meta("achievements", earned)

# -----------------------------------------------
# UNLOCK — call this from anywhere to give the
# player an achievement!
# -----------------------------------------------
func unlock(key: String):
	if earned.get(key, false):
		return   # Already got it!
	if not ALL.has(key):
		return

	earned[key] = true
	_save()

	var info = ALL[key]
	_show_popup(info["icon"] + "  " + info["name"], info["desc"])
	SoundManager.play("victory_sting")
	print("🏅 ACHIEVEMENT UNLOCKED: ", info["name"])

func _show_popup(title: String, subtitle: String):
	var canvas = CanvasLayer.new()
	canvas.layer = 10   # On top of everything

	var bg = Panel.new()
	bg.set_anchor(SIDE_RIGHT, 1)
	bg.set_anchor(SIDE_TOP,   0)
	bg.offset_left   = -340
	bg.offset_right  = -20
	bg.offset_top    = 20
	bg.offset_bottom = 90

	var title_lbl = Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.2))
	title_lbl.position = Vector2(12, 8)
	title_lbl.size     = Vector2(300, 28)
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(title_lbl)

	var sub_lbl = Label.new()
	sub_lbl.text = "🏅 ACHIEVEMENT: " + subtitle
	sub_lbl.add_theme_font_size_override("font_size", 12)
	sub_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	sub_lbl.position = Vector2(12, 36)
	sub_lbl.size     = Vector2(300, 22)
	sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(sub_lbl)

	canvas.add_child(bg)
	get_tree().root.add_child(canvas)

	# Slide in from the right, then slide back out after 3 seconds
	bg.offset_left  =  400
	bg.offset_right =  720
	var tween = get_tree().create_tween()
	tween.tween_property(bg, "offset_left",  -340.0, 0.4)
	tween.parallel().tween_property(bg, "offset_right", -20.0, 0.4)
	tween.tween_interval(3.0)
	tween.tween_property(bg, "offset_left",  400.0, 0.4)
	tween.parallel().tween_property(bg, "offset_right", 720.0, 0.4)
	tween.tween_callback(canvas.queue_free)

# -----------------------------------------------
# HELPER — check win-based achievements
# -----------------------------------------------
func check_wins():
	if GameManager and GameManager.total_wins >= 10:
		unlock("ten_wins")
