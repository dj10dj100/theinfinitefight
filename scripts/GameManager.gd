extends Node

# -----------------------------------------------
# GAME MANAGER
# This script keeps track of everything important:
# - How many wins you have
# - Which weapons you've unlocked
# - Your player name and difficulty
# -----------------------------------------------

# Your player info
var player_name: String = ""
var difficulty: String = "easy"   # easy / medium / hard / bloodthirsty

# Win tracking
var total_wins: int = 0

# Has the intro cutscene been shown already?
var intro_seen: bool = false

# Deploy data — set by the Deploy Screen, read by the Battlefield
# Each entry looks like: { "weapon": "pistol", "position": Vector3(...) }
var deploy_data: Array = []

# All the weapons in order. You start with just the pistol!
var all_weapons: Array = ["pistol", "revolver", "shotgun", "assault_rifle", "machine_gun", "sniper"]

# Which weapons you've unlocked so far (starts with just pistol)
var unlocked_weapons: Array = ["pistol"]

# Which map to play on next (chosen on the Deploy Screen)
# Options: "grassland", "jungle", "city", "snow"
var selected_map: String = "grassland"

# Leaderboard — top 10 scores saved as [{name, wins}]
var leaderboard: Array = []

# Called when the game starts
func _ready():
	print("Game Manager is ready!")
	load_player_data()

# Press F11 at any time to toggle fullscreen on/off
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F11:
			var window = get_window()
			if window.mode == Window.MODE_FULLSCREEN:
				window.mode = Window.MODE_WINDOWED
			else:
				window.mode = Window.MODE_FULLSCREEN

# Check if a new weapon should be unlocked after a win
func add_win():
	total_wins += 1
	print("Total wins: ", total_wins)
	check_for_new_unlock()
	update_leaderboard()
	save_player_data()

# Add the player's current wins to the leaderboard if it's a top 10 score
func update_leaderboard():
	# Check if player already has an entry
	var found = false
	for entry in leaderboard:
		if entry["name"] == player_name:
			entry["wins"] = total_wins
			found = true
			break
	if not found:
		leaderboard.append({"name": player_name, "wins": total_wins})
	# Sort by wins descending, keep top 10
	leaderboard.sort_custom(func(a, b): return a["wins"] > b["wins"])
	if leaderboard.size() > 10:
		leaderboard.resize(10)

# Every 5 wins, unlock the next weapon!
func check_for_new_unlock():
	# Work out how many weapons we should have unlocked by now
	var weapons_to_unlock = min(1 + (total_wins / 5), all_weapons.size())

	for i in range(weapons_to_unlock):
		if not unlocked_weapons.has(all_weapons[i]):
			unlocked_weapons.append(all_weapons[i])
			print("NEW WEAPON UNLOCKED: ", all_weapons[i])

# Save your progress so it's still there next time you play
func save_player_data():
	var save_data = {
		"player_name": player_name,
		"difficulty": difficulty,
		"total_wins": total_wins,
		"unlocked_weapons": unlocked_weapons,
		"intro_seen": intro_seen,
		"leaderboard": leaderboard
	}
	var file = FileAccess.open("user://save_data.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))
	file.close()
	print("Game saved!")

# Load your progress when the game starts
func load_player_data():
	if FileAccess.file_exists("user://save_data.json"):
		var file = FileAccess.open("user://save_data.json", FileAccess.READ)
		var data = JSON.parse_string(file.get_as_text())
		file.close()
		if data:
			player_name       = data.get("player_name", "")
			difficulty        = data.get("difficulty", "easy")
			total_wins        = data.get("total_wins", 0)
			unlocked_weapons  = data.get("unlocked_weapons", ["pistol"])
			intro_seen        = data.get("intro_seen", false)
			leaderboard       = data.get("leaderboard", [])
			print("Welcome back, ", player_name, "! Wins: ", total_wins)
	else:
		print("No save found — new player!")
