extends Node

# -----------------------------------------------
# CLONE RANK SYSTEM
# Clones earn XP by killing enemies!
# Rank up to become stronger soldiers.
#
# Ranks (XP needed):
#   🪖 Private   — 0 XP   (starting rank)
#   🎖 Corporal  — 1 kill
#   ⭐ Sergeant  — 3 kills
#   🌟 Captain   — 6 kills
#   💫 General   — 10 kills (max!)
#
# Each rank gives:
#   +15 max health
#   +10% damage bonus
#   +5% speed bonus
# -----------------------------------------------

const RANKS = [
	{"name": "🪖 Private",  "kills_needed": 0},
	{"name": "🎖 Corporal", "kills_needed": 1},
	{"name": "⭐ Sergeant", "kills_needed": 3},
	{"name": "🌟 Captain",  "kills_needed": 6},
	{"name": "💫 General",  "kills_needed": 10},
]

# Call this when a clone makes a kill
# Returns the new rank name if they ranked up, else ""
static func add_kill(clone) -> String:
	clone.kills += 1
	var new_rank = _get_rank_index(clone.kills)
	if new_rank > clone.rank_index:
		clone.rank_index = new_rank
		_apply_rank_bonuses(clone, new_rank)
		var rank_name = RANKS[new_rank]["name"]
		print("⭐ ", rank_name, " — a clone ranked up!")
		return rank_name
	return ""

static func _get_rank_index(kills: int) -> int:
	var best = 0
	for i in range(RANKS.size()):
		if kills >= RANKS[i]["kills_needed"]:
			best = i
	return best

static func _apply_rank_bonuses(clone, rank_index: int):
	# Each rank level adds +15 HP, +10% damage, +5% speed
	clone.health      += 15.0
	clone.move_speed  *= 1.05
	# Damage bonus stored so get_bullet_damage() can read it
	clone.rank_damage_bonus = 1.0 + rank_index * 0.10

static func get_rank_name(kills: int) -> String:
	return RANKS[_get_rank_index(kills)]["name"]
