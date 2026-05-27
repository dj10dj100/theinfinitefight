extends Control

# -----------------------------------------------
# FRIENDS SYSTEM
# Add friends by typing their exact player name.
# Since every player name is unique, it's easy to
# find someone — just type what they chose!
# Friends are saved locally on your device.
# -----------------------------------------------

var friends_list: Array = []   # List of friend names
var name_input: LineEdit
var friends_container: VBoxContainer
var status_label: Label

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	load_friends()
	build_ui()

# -----------------------------------------------
# BUILD THE UI
# -----------------------------------------------
func build_ui():
	# Dark background
	var bg = ColorRect.new()
	bg.color = Color(0.07, 0.08, 0.11)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Title
	var title = Label.new()
	title.text = "👥  FRIENDS"
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	title.set_anchor(SIDE_LEFT, 0);   title.set_anchor(SIDE_RIGHT,  1)
	title.set_anchor(SIDE_TOP, 0);    title.set_anchor(SIDE_BOTTOM, 0)
	title.offset_top = 30;            title.offset_bottom = 80
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	# Your own name display
	var your_name_lbl = Label.new()
	var my_name = GameManager.player_name if GameManager else "???"
	your_name_lbl.text = "Your name:  " + my_name + "  (share this with your friends!)"
	your_name_lbl.add_theme_font_size_override("font_size", 16)
	your_name_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	your_name_lbl.set_anchor(SIDE_LEFT, 0);   your_name_lbl.set_anchor(SIDE_RIGHT, 1)
	your_name_lbl.set_anchor(SIDE_TOP, 0);    your_name_lbl.set_anchor(SIDE_BOTTOM, 0)
	your_name_lbl.offset_top = 88;            your_name_lbl.offset_bottom = 112
	your_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	your_name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(your_name_lbl)

	# Divider
	var div = ColorRect.new()
	div.color = Color(0.3, 0.3, 0.3)
	div.set_anchor(SIDE_LEFT, 0.05); div.set_anchor(SIDE_RIGHT, 0.95)
	div.set_anchor(SIDE_TOP, 0);     div.set_anchor(SIDE_BOTTOM, 0)
	div.offset_top = 118;            div.offset_bottom = 120
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(div)

	# ---- ADD FRIEND section ----
	var add_label = Label.new()
	add_label.text = "Add a friend by their name:"
	add_label.add_theme_font_size_override("font_size", 18)
	add_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	add_label.set_anchor(SIDE_LEFT, 0.1);  add_label.set_anchor(SIDE_RIGHT, 0.9)
	add_label.set_anchor(SIDE_TOP, 0);     add_label.set_anchor(SIDE_BOTTOM, 0)
	add_label.offset_top = 135;            add_label.offset_bottom = 162
	add_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(add_label)

	# Name input row
	name_input = LineEdit.new()
	name_input.placeholder_text = "Type their name (max 10 chars)..."
	name_input.max_length = 10
	name_input.set_anchor(SIDE_LEFT, 0.1);  name_input.set_anchor(SIDE_RIGHT, 0.7)
	name_input.set_anchor(SIDE_TOP, 0);     name_input.set_anchor(SIDE_BOTTOM, 0)
	name_input.offset_top = 168;            name_input.offset_bottom = 206
	name_input.add_theme_font_size_override("font_size", 18)
	name_input.text_submitted.connect(_on_add_pressed)
	add_child(name_input)

	var add_btn = Button.new()
	add_btn.text = "Add Friend"
	add_btn.add_theme_font_size_override("font_size", 16)
	add_btn.set_anchor(SIDE_LEFT, 0.71);  add_btn.set_anchor(SIDE_RIGHT, 0.9)
	add_btn.set_anchor(SIDE_TOP, 0);      add_btn.set_anchor(SIDE_BOTTOM, 0)
	add_btn.offset_top = 168;             add_btn.offset_bottom = 206
	add_btn.pressed.connect(func(): _on_add_pressed(name_input.text))
	add_child(add_btn)

	# Status message (shows success or errors)
	status_label = Label.new()
	status_label.text = ""
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.set_anchor(SIDE_LEFT, 0.1);  status_label.set_anchor(SIDE_RIGHT, 0.9)
	status_label.set_anchor(SIDE_TOP, 0);     status_label.set_anchor(SIDE_BOTTOM, 0)
	status_label.offset_top = 210;            status_label.offset_bottom = 232
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(status_label)

	# ---- FRIENDS LIST ----
	var list_label = Label.new()
	list_label.text = "Your friends:"
	list_label.add_theme_font_size_override("font_size", 18)
	list_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	list_label.set_anchor(SIDE_LEFT, 0.1);  list_label.set_anchor(SIDE_RIGHT, 0.9)
	list_label.set_anchor(SIDE_TOP, 0);     list_label.set_anchor(SIDE_BOTTOM, 0)
	list_label.offset_top = 245;            list_label.offset_bottom = 272
	list_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(list_label)

	# Scrollable friends list
	var scroll = ScrollContainer.new()
	scroll.set_anchor(SIDE_LEFT, 0.1);   scroll.set_anchor(SIDE_RIGHT, 0.9)
	scroll.set_anchor(SIDE_TOP, 0);      scroll.set_anchor(SIDE_BOTTOM, 1)
	scroll.offset_top = 278;             scroll.offset_bottom = -70
	add_child(scroll)

	friends_container = VBoxContainer.new()
	friends_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	friends_container.add_theme_constant_override("separation", 6)
	scroll.add_child(friends_container)

	rebuild_friends_list()

	# Back button
	var back_btn = Button.new()
	back_btn.text = "← Back to Deploy"
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.set_anchor(SIDE_LEFT, 0.3);   back_btn.set_anchor(SIDE_RIGHT, 0.7)
	back_btn.set_anchor(SIDE_TOP, 1);      back_btn.set_anchor(SIDE_BOTTOM, 1)
	back_btn.offset_top = -58;             back_btn.offset_bottom = -12
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/DeployScreen.tscn"))
	add_child(back_btn)

# -----------------------------------------------
# ADD A FRIEND
# -----------------------------------------------
func _on_add_pressed(typed_name: String):
	typed_name = typed_name.strip_edges()

	if typed_name.length() == 0:
		show_status("Type a name first!", false)
		return

	var my_name = GameManager.player_name if GameManager else ""
	if typed_name.to_lower() == my_name.to_lower():
		show_status("That's your own name! 😄", false)
		return

	if friends_list.has(typed_name):
		show_status(typed_name + " is already your friend!", false)
		return

	# Add them!
	friends_list.append(typed_name)
	save_friends()
	rebuild_friends_list()
	name_input.text = ""
	show_status("✅  " + typed_name + " added as a friend!", true)

# -----------------------------------------------
# REMOVE A FRIEND
# -----------------------------------------------
func remove_friend(friend_name: String):
	friends_list.erase(friend_name)
	save_friends()
	rebuild_friends_list()
	show_status(friend_name + " removed.", false)

# -----------------------------------------------
# REBUILD THE DISPLAYED FRIENDS LIST
# -----------------------------------------------
func rebuild_friends_list():
	for child in friends_container.get_children():
		child.queue_free()

	if friends_list.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "No friends yet — add one above!"
		empty_lbl.add_theme_font_size_override("font_size", 15)
		empty_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		friends_container.add_child(empty_lbl)
		return

	for friend_name in friends_list:
		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 10)

		var icon = Label.new()
		icon.text = "👤"
		icon.add_theme_font_size_override("font_size", 18)
		icon.custom_minimum_size = Vector2(30, 0)
		row.add_child(icon)

		var name_lbl = Label.new()
		name_lbl.text = friend_name
		name_lbl.add_theme_font_size_override("font_size", 18)
		name_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_lbl)

		var remove_btn = Button.new()
		remove_btn.text = "Remove"
		remove_btn.add_theme_font_size_override("font_size", 13)
		remove_btn.custom_minimum_size = Vector2(80, 0)
		remove_btn.pressed.connect(remove_friend.bind(friend_name))
		row.add_child(remove_btn)

		friends_container.add_child(row)

func show_status(msg: String, success: bool):
	status_label.text = msg
	status_label.add_theme_color_override("font_color",
		Color(0.3, 1.0, 0.45) if success else Color(1.0, 0.4, 0.4))

# -----------------------------------------------
# SAVE / LOAD FRIENDS
# -----------------------------------------------
func save_friends():
	var file = FileAccess.open("user://friends.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(friends_list))
	file.close()

func load_friends():
	if FileAccess.file_exists("user://friends.json"):
		var file = FileAccess.open("user://friends.json", FileAccess.READ)
		var data = JSON.parse_string(file.get_as_text())
		file.close()
		if data is Array:
			friends_list = data
