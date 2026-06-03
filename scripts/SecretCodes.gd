extends Node

# -----------------------------------------------
# SECRET CODES
# AutoLoad — type these codes anywhere on the
# main menu to unlock hidden stuff!
# Just type the letters on your keyboard.
# -----------------------------------------------

# All the secret codes and what they unlock
const CODES = {
	"BIGHEAD":    {"type": "skin",    "key": "bighead",    "msg": "👀 BIG HEAD MODE unlocked!"},
	"GOLDARMY":   {"type": "skin",    "key": "golden",     "msg": "✨ GOLDEN ARMY skin unlocked!"},
	"RAINBOW":    {"type": "skin",    "key": "rainbow",    "msg": "🌈 RAINBOW skin unlocked!"},
	"GHOST":      {"type": "skin",    "key": "ghost",      "msg": "👻 GHOST skin unlocked!"},
	"LAZER":      {"type": "weapon",  "key": "laser",      "msg": "🔴 LASER GUN unlocked!"},
	"SUPERSPEED": {"type": "cheat",   "key": "superspeed", "msg": "💨 SUPER SPEED cheat activated!"},
	"INVINCIBLE": {"type": "cheat",   "key": "invincible", "msg": "🛡 INVINCIBLE cheat activated!"},
	"DANIELWIN":  {"type": "cheat",   "key": "instant_win","msg": "🏆 INSTANT WIN cheat activated!"},
	"12367":      {"type": "master",  "key": "master",     "msg": "🌟 MASTER CODE — EVERYTHING UNLOCKED!"},
	"2345":       {"type": "allguns", "key": "allguns",    "msg": "🔫 ALL GUNS UNLOCKED!"},
}

var _typed: String = ""          # Letters typed so far
var unlocked_skins: Array = []   # e.g. ["golden", "rainbow"]
var unlocked_cheats: Array = []  # e.g. ["superspeed"]
var active_skin: String = ""     # Currently equipped secret skin

func _ready():
	_load()

func _load():
	if GameManager and GameManager.has_meta("secret_unlocks"):
		var data = GameManager.get_meta("secret_unlocks")
		unlocked_skins  = data.get("skins",  [])
		unlocked_cheats = data.get("cheats", [])
		active_skin     = data.get("active_skin", "")
	# Always make sure laser is in weapons list if unlocked
	if "laser" in unlocked_skins and GameManager:
		if not GameManager.all_weapons.has("laser"):
			GameManager.all_weapons.append("laser")
		if not GameManager.unlocked_weapons.has("laser"):
			GameManager.unlocked_weapons.append("laser")

func _save():
	if GameManager:
		GameManager.set_meta("secret_unlocks", {
			"skins":       unlocked_skins,
			"cheats":      unlocked_cheats,
			"active_skin": active_skin,
		})

# -----------------------------------------------
# Called every frame from MainMenu to listen for
# key presses (we watch for code sequences)
# -----------------------------------------------
func _input(event):
	if not event is InputEventKey or not event.pressed:
		return
	# Only listen when no text field is focused
	var c = char(event.unicode).to_upper()
	if c.length() == 1 and ((c >= "A" and c <= "Z") or (c >= "0" and c <= "9")):
		_typed += c
		# Keep only the last 12 characters (longest code is 11)
		if _typed.length() > 12:
			_typed = _typed.right(12)
		_check_codes()

func _check_codes():
	for code in CODES:
		if _typed.ends_with(code):
			_typed = ""
			_trigger(code)
			break

func _trigger(code: String):
	var info = CODES[code]

	# Already unlocked?
	if info["type"] == "skin" or info["type"] == "weapon":
		if info["key"] in unlocked_skins:
			_show_banner("You already have this! 😄")
			return

	match info["type"]:
		"skin":
			unlocked_skins.append(info["key"])
			if info["key"] == "laser":
				# Also add it as a weapon
				if GameManager and not GameManager.unlocked_weapons.has("laser"):
					GameManager.unlocked_weapons.append("laser")
		"weapon":
			unlocked_skins.append(info["key"])
			if GameManager and not GameManager.unlocked_weapons.has("laser"):
				GameManager.unlocked_weapons.append("laser")
		"cheat":
			if not info["key"] in unlocked_cheats:
				unlocked_cheats.append(info["key"])
		"master":
			# Unlock every skin, cheat, and weapon all at once!
			for code2 in CODES:
				var info2 = CODES[code2]
				if info2["type"] in ["skin", "weapon"]:
					if not info2["key"] in unlocked_skins:
						unlocked_skins.append(info2["key"])
				elif info2["type"] == "cheat":
					if not info2["key"] in unlocked_cheats:
						unlocked_cheats.append(info2["key"])
			if GameManager:
				GameManager.unlocked_weapons = GameManager.all_weapons.duplicate()

		"allguns":
			# Unlock every gun — no skins or cheats, just the guns!
			if GameManager:
				GameManager.unlocked_weapons = GameManager.all_weapons.duplicate()
				GameManager.save_player_data()

	_save()
	SoundManager.play("victory_sting")
	_show_banner(info["msg"])
	print("🔓 SECRET UNLOCKED: ", code)

func _show_banner(text: String):
	var canvas = CanvasLayer.new()
	canvas.layer = 20
	get_tree().root.add_child(canvas)

	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.05, 0.18, 0.92)
	bg.set_anchor(SIDE_LEFT, 0.5); bg.set_anchor(SIDE_RIGHT,  0.5)
	bg.set_anchor(SIDE_TOP,  0.5); bg.set_anchor(SIDE_BOTTOM, 0.5)
	bg.offset_left  = -280; bg.offset_right  = 280
	bg.offset_top   = -55;  bg.offset_bottom = 55
	canvas.add_child(bg)

	var title = Label.new()
	title.text = "🔓  SECRET UNLOCKED!"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	title.position = Vector2(0, 8)
	title.size     = Vector2(560, 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(title)

	var msg = Label.new()
	msg.text = text
	msg.add_theme_font_size_override("font_size", 17)
	msg.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8))
	msg.position = Vector2(0, 34)
	msg.size     = Vector2(560, 26)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(msg)

	var tween = get_tree().create_tween()
	tween.tween_interval(3.0)
	tween.tween_property(bg, "modulate:a", 0.0, 0.5)
	tween.tween_callback(canvas.queue_free)

# -----------------------------------------------
# APPLY secret skin colour to a clone
# Called from Battlefield after spawning
# -----------------------------------------------
func get_secret_colour() -> Color:
	match active_skin:
		"golden":  return Color(1.0, 0.82, 0.1)
		"ghost":   return Color(0.9, 0.9, 0.95, 0.5)
		"rainbow": return Color(randf(), randf(), randf())   # Random each clone!
		_:         return Color(-1, -1, -1)   # Sentinel = no secret skin

func is_bighead() -> bool:
	return "bighead" in unlocked_skins and active_skin == "bighead"

func has_cheat(key: String) -> bool:
	return key in unlocked_cheats
