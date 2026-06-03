extends Node

# -----------------------------------------------
# BACKPACK SYSTEM 🎒
# Before battle, each clone can carry one backpack.
# Backpacks give a special bonus for the whole fight!
#
# Available backpacks:
#   none         — no backpack (default)
#   ammo_pack    — 2× ammo in every magazine
#   armour_plate — +50 extra HP (starts at 150)
#   jetpack      — press JUMP (Space) to leap high!
#   medkit       — heal 5 HP/s the whole battle
#   grenade_bag  — carry 3 extra grenades (shorter cooldown too)
#
# Usage:
#   Set clone.backpack = "ammo_pack" before battle
#   Call Backpack.apply(clone) in Battlefield after spawn
# -----------------------------------------------

const ALL_BACKPACKS = {
	"none":        {"name": "None",          "icon": "—",  "desc": "No backpack"},
	"ammo_pack":   {"name": "Ammo Pack",     "icon": "🔫", "desc": "Double magazine size"},
	"armour_plate":{"name": "Armour Plate",  "icon": "🛡️", "desc": "+50 bonus HP"},
	"jetpack":     {"name": "Jetpack",       "icon": "🚀", "desc": "Press Space to leap!"},
	"medkit":      {"name": "Medkit",        "icon": "💊", "desc": "Heal 5 HP every second"},
	"grenade_bag": {"name": "Grenade Bag",   "icon": "💣", "desc": "Grenade cooldown -50%"},
}

# Apply a backpack's effect to a clone right after spawning
func apply(clone: Node, backpack_type: String):
	if backpack_type == "none" or backpack_type == "":
		return

	print("🎒 Applying backpack '", backpack_type, "' to clone!")

	match backpack_type:
		"ammo_pack":
			clone.max_ammo = clone.max_ammo * 2
			clone.ammo     = clone.max_ammo

		"armour_plate":
			clone.health = clone.health + 50.0

		"jetpack":
			clone.set_meta("has_jetpack", true)
			# Jetpack logic is handled in Clone.gd via _check_backpack_input()

		"medkit":
			clone.set_meta("medkit_active", true)
			# Healing handled in Clone.gd via _update_ability()

		"grenade_bag":
			# Halve the grenade cooldown constant via a multiplier stored on the clone
			clone.set_meta("grenade_bag", true)

	# Visually attach a little backpack mesh to the clone
	_attach_backpack_mesh(clone, backpack_type)

func _attach_backpack_mesh(clone: Node, bp_type: String):
	var colour = _get_bp_colour(bp_type)
	var pack = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(0.28, 0.35, 0.12)
	pack.mesh = bm
	var mat = StandardMaterial3D.new()
	mat.albedo_color    = colour
	mat.emission_enabled = true
	mat.emission        = colour * 0.3
	mat.roughness       = 0.4
	pack.set_surface_override_material(0, mat)
	# Position on the clone's back
	pack.position = Vector3(0, 0.55, 0.28)
	clone.add_child(pack)

func _get_bp_colour(bp_type: String) -> Color:
	match bp_type:
		"ammo_pack":    return Color(0.8, 0.5, 0.1)
		"armour_plate": return Color(0.4, 0.4, 0.5)
		"jetpack":      return Color(0.1, 0.6, 1.0)
		"medkit":       return Color(0.2, 0.9, 0.3)
		"grenade_bag":  return Color(0.6, 0.2, 0.1)
	return Color(0.4, 0.3, 0.2)

# Which backpack is assigned to each deploy slot?
# Stored in GameManager meta as an array matching deploy_data indices
func get_backpack_for_slot(index: int) -> String:
	if not GameManager.has_meta("deploy_backpacks"):
		return "none"
	var packs = GameManager.get_meta("deploy_backpacks")
	if index < packs.size():
		return packs[index]
	return "none"

func set_backpack_for_slot(index: int, bp_type: String):
	var packs: Array = []
	if GameManager.has_meta("deploy_backpacks"):
		packs = GameManager.get_meta("deploy_backpacks")
	while packs.size() <= index:
		packs.append("none")
	packs[index] = bp_type
	GameManager.set_meta("deploy_backpacks", packs)
