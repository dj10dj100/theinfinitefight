extends Control

# -----------------------------------------------
# LEADERBOARD SCREEN
# Shows the top 10 commanders by total wins!
# Your score is highlighted in gold.
# -----------------------------------------------

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	build_ui()

func build_ui():
	# Dark background
	var bg = ColorRect.new()
	bg.color = Color(0.06, 0.07, 0.10)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Trophy decoration strip at top
	var deco = ColorRect.new()
	deco.color = Color(0.18, 0.14, 0.02)
	deco.set_anchor(SIDE_LEFT, 0);  deco.set_anchor(SIDE_RIGHT, 1)
	deco.set_anchor(SIDE_TOP, 0);   deco.set_anchor(SIDE_BOTTOM, 0)
	deco.offset_bottom = 70
	deco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(deco)

	# Title
	var title = Label.new()
	title.text = "🏆  LEADERBOARD  🏆"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.15))
	title.set_anchor(SIDE_LEFT, 0);  title.set_anchor(SIDE_RIGHT, 1)
	title.set_anchor(SIDE_TOP, 0);   title.set_anchor(SIDE_BOTTOM, 0)
	title.offset_top = 12;           title.offset_bottom = 62
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	# Column headers
	_add_row("RANK", "COMMANDER", "WINS", 80, Color(0.6, 0.8, 1.0), true)

	# Divider line
	var line = ColorRect.new()
	line.color = Color(0.3, 0.3, 0.3)
	line.set_anchor(SIDE_LEFT, 0.08);  line.set_anchor(SIDE_RIGHT, 0.92)
	line.set_anchor(SIDE_TOP, 0);      line.set_anchor(SIDE_BOTTOM, 0)
	line.offset_top = 115;             line.offset_bottom = 117
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(line)

	# Fill in the scores
	var board = GameManager.leaderboard if GameManager else []
	var my_name = GameManager.player_name if GameManager else ""

	if board.is_empty():
		var empty = Label.new()
		empty.text = "No scores yet — go win some battles!"
		empty.add_theme_font_size_override("font_size", 18)
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		empty.set_anchor(SIDE_LEFT, 0);  empty.set_anchor(SIDE_RIGHT, 1)
		empty.set_anchor(SIDE_TOP, 0);   empty.set_anchor(SIDE_BOTTOM, 0)
		empty.offset_top = 160;          empty.offset_bottom = 195
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(empty)
	else:
		for i in range(board.size()):
			var entry = board[i]
			var rank_str = _rank_label(i)
			var is_me = entry["name"] == my_name
			var colour = Color(1.0, 0.85, 0.2) if is_me else Color(0.85, 0.85, 0.85)
			if i == 0:
				colour = Color(1.0, 0.85, 0.2)  # Gold for 1st
			elif i == 1:
				colour = Color(0.8, 0.8, 0.85)  # Silver for 2nd
			elif i == 2:
				colour = Color(0.8, 0.55, 0.2)  # Bronze for 3rd
			_add_row(rank_str, entry["name"], str(entry["wins"]), 125 + i * 46, colour, false, is_me)

	# Your current score (shown even if not in top 10)
	var my_wins = GameManager.total_wins if GameManager else 0
	var footer_lbl = Label.new()
	footer_lbl.text = "Your current score: " + my_name + "  —  " + str(my_wins) + " wins"
	footer_lbl.add_theme_font_size_override("font_size", 15)
	footer_lbl.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
	footer_lbl.set_anchor(SIDE_LEFT, 0);    footer_lbl.set_anchor(SIDE_RIGHT, 1)
	footer_lbl.set_anchor(SIDE_BOTTOM, 1);  footer_lbl.set_anchor(SIDE_TOP, 1)
	footer_lbl.offset_top    = -95
	footer_lbl.offset_bottom = -65
	footer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(footer_lbl)

	# Back button
	var back_btn = Button.new()
	back_btn.text = "← Back to Deploy"
	back_btn.add_theme_font_size_override("font_size", 20)
	back_btn.set_anchor(SIDE_LEFT, 0.3);    back_btn.set_anchor(SIDE_RIGHT, 0.7)
	back_btn.set_anchor(SIDE_BOTTOM, 1);    back_btn.set_anchor(SIDE_TOP, 1)
	back_btn.offset_top    = -58
	back_btn.offset_bottom = -10
	back_btn.pressed.connect(func():
		SoundManager.play("click")
		get_tree().change_scene_to_file("res://scenes/DeployScreen.tscn")
	)
	add_child(back_btn)

# -----------------------------------------------
# HELPERS
# -----------------------------------------------
func _rank_label(i: int) -> String:
	match i:
		0: return "🥇 1st"
		1: return "🥈 2nd"
		2: return "🥉 3rd"
		_: return "   " + str(i + 1) + "th"

func _add_row(rank: String, name: String, wins: String, top: int,
			  colour: Color, is_header: bool, highlight: bool = false):
	var row_h = 38 if is_header else 42

	# Highlight background for the player's own row
	if highlight:
		var hl = ColorRect.new()
		hl.color = Color(0.18, 0.22, 0.10, 0.9)
		hl.set_anchor(SIDE_LEFT, 0.07);  hl.set_anchor(SIDE_RIGHT, 0.93)
		hl.set_anchor(SIDE_TOP, 0);      hl.set_anchor(SIDE_BOTTOM, 0)
		hl.offset_top = top - 4;         hl.offset_bottom = top + row_h + 2
		hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(hl)

	var font_size = 16 if is_header else 18

	var rank_lbl = Label.new()
	rank_lbl.text = rank
	rank_lbl.add_theme_font_size_override("font_size", font_size)
	rank_lbl.add_theme_color_override("font_color", colour)
	rank_lbl.set_anchor(SIDE_LEFT, 0.08);  rank_lbl.set_anchor(SIDE_RIGHT, 0.28)
	rank_lbl.set_anchor(SIDE_TOP, 0);      rank_lbl.set_anchor(SIDE_BOTTOM, 0)
	rank_lbl.offset_top = top;             rank_lbl.offset_bottom = top + row_h
	rank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	rank_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rank_lbl)

	var name_lbl = Label.new()
	name_lbl.text = name
	name_lbl.add_theme_font_size_override("font_size", font_size)
	name_lbl.add_theme_color_override("font_color", colour)
	name_lbl.set_anchor(SIDE_LEFT, 0.28);  name_lbl.set_anchor(SIDE_RIGHT, 0.72)
	name_lbl.set_anchor(SIDE_TOP, 0);      name_lbl.set_anchor(SIDE_BOTTOM, 0)
	name_lbl.offset_top = top;             name_lbl.offset_bottom = top + row_h
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(name_lbl)

	var wins_lbl = Label.new()
	wins_lbl.text = wins
	wins_lbl.add_theme_font_size_override("font_size", font_size)
	wins_lbl.add_theme_color_override("font_color", colour)
	wins_lbl.set_anchor(SIDE_LEFT, 0.72);  wins_lbl.set_anchor(SIDE_RIGHT, 0.92)
	wins_lbl.set_anchor(SIDE_TOP, 0);      wins_lbl.set_anchor(SIDE_BOTTOM, 0)
	wins_lbl.offset_top = top;             wins_lbl.offset_bottom = top + row_h
	wins_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	wins_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wins_lbl)
