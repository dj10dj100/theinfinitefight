# The Infinite Fight — Claude Handoff Document

This file is for whoever picks up this project next. It covers everything: who Daniel is, what the game is, what's been built, how everything works, and what's left to do.

---

## About Arnold (the game designer)

Arnold is 8 years old and a huge game enthusiast. He is new to coding. **Daniel is Arnold's dad** — Daniel handles things like pushing to GitHub when needed, but Arnold is the one designing the game and talking to Claude.

When helping Arnold:

- **Keep explanations simple and fun** — avoid jargon, use analogies a kid would understand
- **Use short sentences and avoid walls of text**
- **Don't assume he knows coding terms** — explain what things do, not just what they are
- **Ask questions** if something he says is unclear rather than guessing
- **Be enthusiastic about his ideas** — he has great creative instincts
- **Use emojis in chat** (not in code) to keep things friendly
- When something needs pushing to GitHub, tell Arnold to **ask his dad Daniel** to run the terminal command

---

## The Game

**Name:** The Infinite Fight  
**Engine:** Godot 4.6 (GDScript)  
**Genre:** Top-down / first-person strategy action  
**GitHub:** `git@github.com:dj10dj100/theinfinitefight.git`  
**Live web build:** `https://dj10dj100.github.io/theinfinitefight/`  
**Auto-deploy:** GitHub Actions pushes to GitHub Pages on every commit

### What it is

You place plastic army man clones on a battlefield. They fight enemies automatically (AI). You can click any clone to take over in first-person view and control it yourself. The game has waves, upgrades, secret codes, a level editor, and loads more.

---

## How to push changes to GitHub

Arnold's dad **Daniel** handles this. The command is:

```bash
cd ~/ArmyGame/ArmyGame
rm -f .git/index.lock .git/HEAD.lock   # only needed if there's a lock file error
git add .
git commit -m "describe what changed here"
git push
```

The live site updates automatically after a push (takes ~2 minutes).

---

## Project Structure

```
ArmyGame/ArmyGame/
├── project.godot           ← Godot project config + AutoLoads
├── scripts/
│   ├── GameManager.gd      ← AutoLoad: saves/loads data, weapons, wins
│   ├── ArmyManBuilder.gd   ← AutoLoad: builds plastic army man 3D models
│   ├── SoundManager.gd     ← AutoLoad: plays sounds and music
│   ├── MapTheme.gd         ← AutoLoad: sets map colours/fog/lighting
│   ├── Particles.gd        ← AutoLoad: death explosions, muzzle flashes
│   ├── VoiceLines.gd       ← AutoLoad: shouts during battle
│   ├── CloneRank.gd        ← AutoLoad: rank system (kills → promotions)
│   ├── Achievements.gd     ← AutoLoad: 12 achievements, unlock popups
│   ├── Killstreak.gd       ← AutoLoad: streak rewards at 3/5/10 kills
│   ├── SecretCodes.gd      ← AutoLoad: keyboard cheat codes
│   ├── Clone.gd            ← One army man clone (player or AI)
│   ├── Enemy.gd            ← Enemy with smart AI state machine
│   ├── Bullet.gd           ← Bullet projectile
│   ├── Grenade.gd          ← Thrown grenade (area damage)
│   ├── Airstrike.gd        ← Airstrike drop (big area damage)
│   ├── Landmine.gd         ← Planted mine (triggered by enemies)
│   ├── Battlefield.gd      ← Main battle scene controller
│   ├── HUD.gd              ← First-person HUD (health, ammo, crosshair)
│   ├── DeployScreen.gd     ← Drag-and-drop clone placement screen
│   ├── MainMenu.gd         ← Main menu (map, mode, shop, customise)
│   ├── BattleResult.gd     ← Win/lose screen
│   ├── WaveManager.gd      ← Endless wave mode controller
│   ├── Jeep.gd             ← Driveable vehicle
│   ├── Trap.gd             ← Wall/spike traps placed in level editor
│   ├── BattleCoin.gd       ← Spinning coin dropped by enemies
│   ├── LevelEditor.gd      ← Grid-based level editor
│   ├── CloneCustomise.gd   ← Choose clone colour, name, special ability
│   ├── UpgradeShop.gd      ← Spend wins on permanent upgrades
│   ├── Leaderboard.gd      ← Top 10 scores display
│   ├── SettingsScreen.gd   ← Volume, difficulty etc.
│   ├── NameSetup.gd        ← First-run name entry
│   └── IntroCutscene.gd    ← Animated intro sequence
├── scenes/
│   ├── MainMenu.tscn
│   ├── Battlefield.tscn
│   ├── DeployScreen.tscn
│   ├── LevelEditor.tscn
│   ├── BattleResult.tscn
│   ├── CloneCustomise.tscn
│   ├── UpgradeShop.tscn
│   ├── Leaderboard.tscn
│   ├── SettingsScreen.tscn
│   ├── NameSetup.tscn
│   ├── IntroCutscene.tscn
│   └── Bullet.tscn
```

---

## AutoLoad Singletons

These are always available by name from any script:

| Name | What it does |
|---|---|
| `GameManager` | Saves/loads data, tracks wins, holds weapon/upgrade lists |
| `ArmyManBuilder` | Builds the 3D plastic army man body from code (no mesh files) |
| `SoundManager` | `SoundManager.play("sound_name")` — plays any sound |
| `MapTheme` | Applies fog, lighting, and sky colour for the selected map |
| `Particles` | `Particles.death_explosion(pos, colour)`, `Particles.muzzle_flash(pos, dir)` |
| `VoiceLines` | `VoiceLines.say_shoot(pos)`, `VoiceLines.say_hit(pos)`, `VoiceLines.say_death(pos)` |
| `CloneRank` | Tracks kill counts, promotes clones through ranks |
| `Achievements` | `Achievements.unlock("key")` — unlocks and shows popup |
| `Killstreak` | `Killstreak.add_kill(clone)` — tracks streak, triggers rewards |
| `SecretCodes` | Listens for keyboard codes globally, unlocks hidden stuff |

---

## Scene Navigation Flow

```
NameSetup → IntroCutscene → MainMenu
MainMenu → UpgradeShop / CloneCustomise / Leaderboard / SettingsScreen / LevelEditor / DeployScreen
DeployScreen → Battlefield
Battlefield → BattleResult
BattleResult → MainMenu
```

All "back" buttons go to `res://scenes/MainMenu.tscn`.

---

## Weapons System

Weapons unlock every 5 wins. Full list in `GameManager.all_weapons`:

| Weapon key | Display name | Ammo | Damage | Fire rate |
|---|---|---|---|---|
| `pistol` | Pistol | 15 | 15 | moderate |
| `revolver` | Revolver | 6 | 25 | slow |
| `shotgun` | Shotgun | 5 | 30 | slow |
| `assault_rifle` | Assault Rifle | 30 | 10 | fast |
| `sniper` | Sniper Rifle | 1 | 200 | very slow |
| `smg` | SMG | 70 | 5 | very fast |
| `minigun` | Minigun | 1000 | 50 | extremely fast |
| `arnies_raygun` | Arnie's Raygun | ∞ | 10 | moderate |

Ammo and reload are in `Clone.gd` — `get_max_ammo()`, `get_reload_time()`, `get_shoot_cooldown()`, `get_bullet_damage()`.

The HUD shows current ammo / max ammo, turns yellow when low, red when nearly empty, and shows "🔄 RELOADING..." while waiting.

---

## Secret Codes

Type these on the keyboard from anywhere (letters + numbers both work):

| Code | What it unlocks |
|---|---|
| `BIGHEAD` | Big head mode skin |
| `GOLDARMY` | Golden army skin |
| `RAINBOW` | Rainbow skin |
| `GHOST` | Ghost (transparent) skin |
| `LAZER` | Laser gun weapon |
| `SUPERSPEED` | Super speed cheat |
| `INVINCIBLE` | Invincible cheat |
| `DANIELWIN` | Instant win cheat |
| `12367` | **MASTER CODE** — unlocks EVERYTHING |

Handled in `SecretCodes.gd`. Skins stored in `unlocked_skins[]`, cheats in `unlocked_cheats[]`, saved via `GameManager.set_meta("secret_unlocks", ...)`.

---

## Clone Special Abilities

Set in `CloneCustomise.gd` and applied in `Clone.gd._update_ability()`:

| Key | What it does |
|---|---|
| `berserker` | Runs faster below 50% health |
| `medic` | Heals self 2 HP/s |
| `sniper_eye` | Extra shooting range |
| `tank` | Takes 25% less damage |
| `field_medic` | Heals ALL nearby clones 4 HP/s in 6m range |
| `demolitions` | Grenade cooldown halved, grenade damage doubled |
| `engineer` | Shoots twice as fast |

Special abilities in first-person:
- **G** — throw grenade (12s cooldown)
- **A** — call airstrike (25s cooldown)
- **M** — plant landmine (18s cooldown)

---

## Achievements

12 achievements in `Achievements.gd`:

| Key | How to unlock |
|---|---|
| `first_blood` | Win your first battle |
| `survivor` | Win with only 1 clone left |
| `grenade_master` | Kill 3+ enemies with one grenade |
| `airstrike_ace` | Call 5 airstrikes total |
| `landmine_trap` | Enemy triggers your landmine |
| `general` | Reach 10 total wins |
| `ten_wins` | Reach 10 wins (alias) |
| `killstreak_3` | Get a 3-kill streak |
| `killstreak_10` | Get a 10-kill streak |
| `boss_slayer` | Kill a boss enemy |
| `rich` | Spend 20+ coins in one battle |
| `last_stand_win` | Win with only 1 clone AND low health |

---

## Killstreak Rewards

Handled in `Killstreak.gd`:
- **3 kills** — speed ×2 for 8 seconds
- **5 kills** — activate shield (3 hits)
- **10 kills** — 150 damage to all enemies within 10m

---

## Wave Mode

Toggle on the Main Menu or Deploy Screen. Handled by `WaveManager.gd`:
- Wave 1 starts with 3 enemies
- Each wave adds 2 more enemies
- Enemy health increases 25% per wave
- Boss enemy every 5 waves
- Between waves: all clones heal +30 HP, player gets coins equal to wave number, 10-second break

---

## Battle Coins & Upgrades

Enemies drop spinning gold coins (`BattleCoin.gd`). Collect them by walking over them. Spend in-battle via the upgrade panel (`Battlefield.gd._build_coin_hud()`):
- **+Health** (3 coins) — heals all living clones
- **+Speed** (4 coins) — boosts all clones
- **+Shield** (5 coins) — gives all clones 3 shield hits

---

## Level Editor

In `LevelEditor.gd` — a 17×8 grid (44px cells). Tools: tree, rock, wall, bush, erase. On deploy, grid cells are converted to 3D world positions and saved to `GameManager.set_meta("editor_objects", ...)`. Battlefield reads this and spawns the objects.

---

## Important GDScript Rules (Godot 4.6)

Things that have caused bugs before — do NOT do these:

- ❌ `static func` on AutoLoad singletons — use regular `func`
- ❌ `AudioStreamWAV.FORMAT_16_BIT` — use integer `1` instead
- ❌ `wav.loop_mode = AudioStreamWAV.LOOP_FORWARD` — use integer `1`
- ❌ C-style ternary `condition ? a : b` — GDScript uses `a if condition else b`
- ❌ Adding UI nodes to `get_tree().root` without ever freeing them — always call `queue_free()` before changing scenes
- ❌ `var preview_mesh: MeshInstance3D` when the node is actually a `ColorRect` — type annotations must match

---

## Data Persistence

`GameManager` saves to `user://save_data.json` (wins, weapons, upgrades, name etc.).

Extra runtime data uses `GameManager.set_meta() / get_meta() / has_meta()` for things like:
- `"secret_unlocks"` — secret code skins/cheats
- `"achievements"` — which achievements are earned
- `"editor_objects"` — level editor grid layout
- `"trap_data"` — traps placed before battle

---

## Phases Already Completed

| Phase | What was built |
|---|---|
| 1 | Godot project, battlefield, clone movement |
| 2 | Bullets, damage, first-person mouse look |
| 3 | Drag-and-drop deploy screen |
| 4 | Win counter, unlocks, sniper clone, victory/defeat screens, name setup |
| 5 | Intro cutscene, friends system |
| 6 | Sounds and music system |
| 7 | Levels, power-ups, leaderboard, boss enemies |
| 8 | Animations, particles, voice lines, upgrade shop |
| 9 | Night mode, clone customisation, multiplayer prep |
| 10 | Mini map, weather effects, clone ranks |
| 11 | Special abilities (grenade, airstrike, landmine) |
| 12 | Achievements, battle upgrades (coins), smart enemy AI, killstreaks |
| 13 | Wave mode, clone classes, traps, jeep vehicle |
| 14 | Secret codes, level editor, main menu |
| — | Full weapon system: ammo, reload, 8 weapons with Daniel's exact stats |

---

## Ideas Daniel Has Mentioned (Not Yet Built)

These are things Daniel has talked about wanting — not confirmed phases, just his ideas:
- More gun types (the stats are now all in the game, ready to be used)
- Drag-and-drop on the main menu (mentioned but not built yet)

---

## What to Work on Next

Arnold drives the priorities — ask him what he wants to do next. He'll say something like "Phase 15" or describe a new feature. Typical workflow:

1. Ask a clarifying question if the request is vague
2. Check which files need changing (`GameManager.gd`, `Clone.gd`, `Battlefield.gd` are touched most often)
3. Read the relevant files before editing
4. Make changes one file at a time, explaining what each change does in simple terms
5. Tell Arnold to ask his dad Daniel to push to GitHub

---

## Tone & Style Reminder

Arnold loves this game and has put a lot of work into it. Always match his energy. Use phrases like "cool idea!", explain bugs as puzzles to solve together, and celebrate when features work. He responds well to enthusiasm and clear step-by-step explanations. Remember — you're talking to an 8 year old, not his dad!
