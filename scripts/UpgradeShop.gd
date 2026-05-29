extends Control

# -----------------------------------------------
# UPGRADE SHOP
# Spend your wins like coins to buy upgrades!
# Upgrades are permanent and make your clones
# stronger in every battle.
#
# Upgrades available:
#   tougher_clones  — +25 max HP per clone
#   faster_legs     — +20% movement speed
#   bigger_bullets  — +25% bullet damage
#   extra_clone     — deploy 2 extra clones
#   fast_reload     — shoot 20% faster
# -----------------------------------------------

const UPGRADES = [
	{
		"key":   "tougher_clones",
		"name":  "💪 Tougher Clones",
		"desc":  "Each clone gets +25 max health.\nThey can take more hits!",
		"cost":  3,
		"max":   4
	},
	{
		"key":   "faster_legs",
		"name":  "👟 Faster Legs",
		"desc":  "Clones move 20% faster.\nChase down the enemy!",
		"cost":  3,
		"max":   3
	},
	{
		"key":   "bigger_bullets",
		"name":  "🔥 Bigger Bullets",
		"desc":  "All weapons deal 25% more damage.\nShoot harder!",
		"cost":  4,
		"max":   4
	},
	{
		"key":   "extra_clone",
		"name":  "➕ Extra Clone Slot",
		"desc":  "Deploy 2 more clones per battle.\nMore soldiers = more winning!",
		"cost":  5,
		"max":   2
	},
	{
		"key":   "fast_reload",
		"name":  "⚡ Fast Reload",
		"desc":  "Shoot 20% faster with all weapons.\nRapid fire!",
		"cost":  4,
		"max":   3
	},
]

var wins_label: Label = null
var upgrade_panels: Dictionary = {}

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	build_ui()

func build_ui():
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.06, 0.06, 0.10)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Header strip
	var header = ColorRect.new()
	header.color = Color(0.10, 0.08, 0.02)
	header.set_anchor(SIDE_LEFT, 0);   header.set_anchor(SIDE_RIGHT, 1)
	header.set_anchor(SIDE_TOP, 0);    header.set_anchor(SIDE_BOTTOM, 0)
	header.offset_bottom = 72
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(header)

	# Title
	var title = Label.new()
	title.text = "🛒  UPGRADE SHOP"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.15))
	title.set_anchor(SIDE_LEFT, 0);  title.set_anchor(SIDE_RIGHT, 1)
	title.set_anchor(SIDE_TOP, 0);   title.set_anchor(SIDE_BOTTOM, 0)
	title.offset_top = 12;           title.offset_bottom = 62
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	# Wins (currency) display
	wins_label = Label.new()
	wins_label.add_theme_font_size_override("font_size", 18)
	wins_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	wins_label.set_anchor(SIDE_LEFT, 0);  wins_label.set_anchor(SIDE_RIGHT, 1)
	wins_label.set_anchor(SIDE_TOP, 0);   wins_label.set_anchor(SIDE_BOTTOM, 0)
	wins_label.offset_top = 75;           wins_label.offset_bottom = 105
	wins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wins_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wins_label)
	_update_wins_label()

	# Upgrade cards
	var card_w = 190
	var card_h = 195
	var gap    = 18
	var total_w = card_w * UPGRADES.size() + gap * (UPGRADES.size() - 1)

	for i in range(UPGRADES.size()):
		var upg = UPGRADES[i]
		_build_card(upg, i, card_w, card_h, gap, total_w)

	# Back button
	var back_btn = Button.new()
	back_btn.text = "← Back to Deploy"
	back_btn.add_theme_font_size_override("font_size", 20)
	back_btn.set_anchor(SIDE_LEFT, 0.3);    back_btn.set_anchor(SIDE_RIGHT, 0.7)
	back_btn.set_anchor(SIDE_BOTTOM, 1);    back_btn.set_anchor(SIDE_TOP, 1)
	back_btn.offset_top    = -55
	back_btn.offset_bottom = -10
	back_btn.pressed.connect(func():
		SoundManager.play("click")
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	add_child(back_btn)

func _build_card(upg: Dictionary, index: int, card_w: int, card_h: int, gap: int, total_w: int):
	var panel = Panel.new()
	panel.set_anchor(SIDE_LEFT, 0.5);   panel.set_anchor(SIDE_RIGHT, 0.5)
	panel.set_anchor(SIDE_TOP, 0);      panel.set_anchor(SIDE_BOTTOM, 0)
	var x = (index - (UPGRADES.size() - 1) * 0.5) * (card_w + gap)
	panel.offset_left   = x - card_w * 0.5
	panel.offset_right  = x + card_w * 0.5
	panel.offset_top    = 115
	panel.offset_bottom = 115 + card_h
	add_child(panel)
	upgrade_panels[upg["key"]] = panel

	# Upgrade name
	var name_lbl = Label.new()
	name_lbl.text = upg["name"]
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	name_lbl.position = Vector2(6, 8)
	name_lbl.size     = Vector2(card_w - 12, 32)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	panel.add_child(name_lbl)

	# Description
	var desc_lbl = Label.new()
	desc_lbl.text = upg["desc"]
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78))
	desc_lbl.position = Vector2(8, 44)
	desc_lbl.size     = Vector2(card_w - 16, 70)
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	panel.add_child(desc_lbl)

	# Level display (dots)
	var level_lbl = Label.new()
	level_lbl.name = "LevelLabel"
	level_lbl.add_theme_font_size_override("font_size", 13)
	level_lbl.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	level_lbl.position = Vector2(6, 118)
	level_lbl.size     = Vector2(card_w - 12, 22)
	level_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(level_lbl)

	# Cost label
	var cost_lbl = Label.new()
	cost_lbl.name = "CostLabel"
	cost_lbl.add_theme_font_size_override("font_size", 13)
	cost_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	cost_lbl.position = Vector2(6, 140)
	cost_lbl.size     = Vector2(card_w - 12, 22)
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(cost_lbl)

	# Buy button
	var buy_btn = Button.new()
	buy_btn.name = "BuyButton"
	buy_btn.text = "BUY"
	buy_btn.add_theme_font_size_override("font_size", 16)
	buy_btn.position = Vector2(20, 164)
	buy_btn.size     = Vector2(card_w - 40, 26)
	buy_btn.pressed.connect(_on_buy_pressed.bind(upg["key"]))
	panel.add_child(buy_btn)

	_refresh_card(upg["key"])

func _refresh_card(key: String):
	var upg = null
	for u in UPGRADES:
		if u["key"] == key:
			upg = u
			break
	if upg == null:
		return

	var panel    = upgrade_panels[key]
	var level    = GameManager.upgrades.get(key, 0) if GameManager else 0
	var max_lvl  = upg["max"]
	var cost     = upg["cost"]
	var wins     = GameManager.total_wins if GameManager else 0
	var spent    = GameManager.wins_spent if GameManager else 0
	var balance  = wins - spent
	var maxed    = level >= max_lvl
	var can_buy  = not maxed and balance >= cost

	# Level dots: ● filled, ○ empty
	var level_lbl = panel.get_node("LevelLabel")
	var dots = ""
	for i in range(max_lvl):
		dots += "● " if i < level else "○ "
	level_lbl.text = "Level: " + dots.strip_edges()

	# Cost
	var cost_lbl = panel.get_node("CostLabel")
	if maxed:
		cost_lbl.text = "✅ MAXED OUT!"
		cost_lbl.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	else:
		cost_lbl.text = "Cost: " + str(cost) + " wins"
		cost_lbl.add_theme_color_override("font_color",
			Color(0.4, 1.0, 0.5) if can_buy else Color(0.8, 0.3, 0.3))

	# Buy button
	var buy_btn = panel.get_node("BuyButton")
	buy_btn.disabled = not can_buy
	buy_btn.text = "MAXED" if maxed else "BUY (" + str(cost) + " wins)"

	# Dim the whole card if maxed
	panel.modulate = Color(0.6, 0.7, 0.6) if maxed else Color(1, 1, 1)

func _on_buy_pressed(key: String):
	var upg = null
	for u in UPGRADES:
		if u["key"] == key:
			upg = u
			break
	if upg == null or GameManager == null:
		return

	var level   = GameManager.upgrades.get(key, 0)
	var balance = GameManager.total_wins - GameManager.wins_spent

	if level >= upg["max"] or balance < upg["cost"]:
		return

	SoundManager.play("victory_sting")
	GameManager.upgrades[key]  = level + 1
	GameManager.wins_spent     += upg["cost"]
	GameManager.save_player_data()

	print("Bought upgrade: ", key, " → level ", level + 1)

	_update_wins_label()
	for u in UPGRADES:
		_refresh_card(u["key"])

func _update_wins_label():
	if GameManager == null:
		return
	var balance = GameManager.total_wins - GameManager.wins_spent
	wins_label.text = "💰  Wins to spend: " + str(balance) + "   (Total wins: " + str(GameManager.total_wins) + ")"
