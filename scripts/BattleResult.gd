extends Control

# -----------------------------------------------
# BATTLE RESULT SCREEN
# Shown after every battle — win or lose.
# Shows your win count, and celebrates if you
# just unlocked a new weapon!
# -----------------------------------------------

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

# Call this from Battlefield.gd when the battle ends
func show_victory():
	build_result_ui(true)

func show_defeat():
	build_result_ui(false)

func build_result_ui(won: bool):
	# Semi-transparent dark overlay
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.78)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	# Big WIN / LOSE title
	var title = Label.new()
	title.add_theme_font_size_override("font_size", 64)
	title.set_anchor(SIDE_LEFT, 0);   title.set_anchor(SIDE_RIGHT,  1)
	title.set_anchor(SIDE_TOP, 0);    title.set_anchor(SIDE_BOTTOM, 0)
	title.offset_top = 120;           title.offset_bottom = 200
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if won:
		title.text = "🏆  VICTORY!"
		title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	else:
		title.text = "💀  DEFEAT!"
		title.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
	add_child(title)

	# Win count
	var wins = GameManager.total_wins if GameManager else 0
	var win_label = Label.new()
	win_label.text = "Total wins: " + str(wins)
	win_label.add_theme_font_size_override("font_size", 24)
	win_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	win_label.set_anchor(SIDE_LEFT, 0);   win_label.set_anchor(SIDE_RIGHT,  1)
	win_label.set_anchor(SIDE_TOP, 0);    win_label.set_anchor(SIDE_BOTTOM, 0)
	win_label.offset_top = 210;           win_label.offset_bottom = 250
	win_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(win_label)

	# Show "NEW WEAPON UNLOCKED!" if the win count just hit a milestone
	if won and GameManager and wins > 0 and wins % 5 == 0:
		var unlocked = GameManager.unlocked_weapons
		var new_weapon = unlocked[unlocked.size() - 1]
		var weapon_names = {
			"pistol":        "Pistol",
			"revolver":      "Revolver",
			"shotgun":       "Shotgun",
			"assault_rifle": "Assault Rifle",
			"machine_gun":   "Machine Gun",
			"sniper":        "Sniper Rifle"
		}
		var unlock_lbl = Label.new()
		unlock_lbl.text = "🔓  NEW WEAPON UNLOCKED!\n" + weapon_names.get(new_weapon, new_weapon.capitalize())
		unlock_lbl.add_theme_font_size_override("font_size", 28)
		unlock_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
		unlock_lbl.set_anchor(SIDE_LEFT, 0);   unlock_lbl.set_anchor(SIDE_RIGHT,  1)
		unlock_lbl.set_anchor(SIDE_TOP, 0);    unlock_lbl.set_anchor(SIDE_BOTTOM, 0)
		unlock_lbl.offset_top = 260;           unlock_lbl.offset_bottom = 330
		unlock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		unlock_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(unlock_lbl)

	# Next unlock hint (if not maxed out)
	if GameManager:
		var wins_to_next = 5 - (GameManager.total_wins % 5)
		if GameManager.unlocked_weapons.size() < GameManager.all_weapons.size() and wins_to_next != 5:
			var next_lbl = Label.new()
			next_lbl.text = str(wins_to_next) + " more wins until next unlock!"
			next_lbl.add_theme_font_size_override("font_size", 16)
			next_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
			next_lbl.set_anchor(SIDE_LEFT, 0);   next_lbl.set_anchor(SIDE_RIGHT,  1)
			next_lbl.set_anchor(SIDE_TOP, 0);    next_lbl.set_anchor(SIDE_BOTTOM, 0)
			next_lbl.offset_top = 340;           next_lbl.offset_bottom = 365
			next_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			next_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(next_lbl)

	# Buttons
	if won:
		var deploy_btn = Button.new()
		deploy_btn.text = "⚔  Fight Again!"
		deploy_btn.add_theme_font_size_override("font_size", 22)
		deploy_btn.set_anchor(SIDE_LEFT,  0.25); deploy_btn.set_anchor(SIDE_RIGHT, 0.5)
		deploy_btn.set_anchor(SIDE_TOP,   0);    deploy_btn.set_anchor(SIDE_BOTTOM, 0)
		deploy_btn.offset_top = 400;             deploy_btn.offset_bottom = 455
		deploy_btn.pressed.connect(_go_to_deploy)
		add_child(deploy_btn)

		var menu_btn2 = Button.new()
		menu_btn2.text = "🏠  Main Menu"
		menu_btn2.add_theme_font_size_override("font_size", 22)
		menu_btn2.set_anchor(SIDE_LEFT,  0.5);  menu_btn2.set_anchor(SIDE_RIGHT, 0.75)
		menu_btn2.set_anchor(SIDE_TOP,   0);    menu_btn2.set_anchor(SIDE_BOTTOM, 0)
		menu_btn2.offset_top = 400;             menu_btn2.offset_bottom = 455
		menu_btn2.pressed.connect(_go_to_menu)
		add_child(menu_btn2)
	else:
		var retry_btn = Button.new()
		retry_btn.text = "🔄  Try Again"
		retry_btn.add_theme_font_size_override("font_size", 22)
		retry_btn.set_anchor(SIDE_LEFT,  0.25); retry_btn.set_anchor(SIDE_RIGHT, 0.5)
		retry_btn.set_anchor(SIDE_TOP,   0);    retry_btn.set_anchor(SIDE_BOTTOM, 0)
		retry_btn.offset_top = 400;             retry_btn.offset_bottom = 455
		retry_btn.pressed.connect(_go_to_deploy)
		add_child(retry_btn)

		var quit_btn = Button.new()
		quit_btn.text = "🚪  Main Menu"
		quit_btn.add_theme_font_size_override("font_size", 22)
		quit_btn.set_anchor(SIDE_LEFT,  0.5);  quit_btn.set_anchor(SIDE_RIGHT, 0.75)
		quit_btn.set_anchor(SIDE_TOP,   0);    quit_btn.set_anchor(SIDE_BOTTOM, 0)
		quit_btn.offset_top = 400;             quit_btn.offset_bottom = 455
		quit_btn.pressed.connect(_go_to_menu)
		add_child(quit_btn)

# -----------------------------------------------
# NAVIGATION — properly clean up before switching
# -----------------------------------------------
func _go_to_deploy():
	SoundManager.play("click")
	# Remove this result screen first, THEN change scene
	# (otherwise it floats on top of the new screen!)
	queue_free()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _go_to_menu():
	SoundManager.play("click")
	queue_free()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
