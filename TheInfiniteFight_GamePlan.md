# 🎮 THE INFINITE FIGHT — Game Design Plan

> A 3D action strategy game for PC & Mobile
> Designed by Daniel Jenkins

---

## 📖 The Story

Once, you and the enemy soldiers fought side by side as brothers — the same army, the same team.

But one day, a group of soldiers decided they didn't want to follow the rules anymore. They wanted POWER. They secretly built up their own army of rogue clones, trained them in the shadows, and then one night... they turned against everyone.

Now they call themselves **The Rogue** — and they've been spreading across the land, taking over everything in their path.

YOU are what's left of the original army. Your mission is to fight back, level by level, and stop The Rogue before they can't be stopped.

---

## 🎬 The Introduction Cutscene

Before you ever play a single level, the game opens with a short cinematic. Here's what happens:

> *The camera slowly zooms in on a dark tent lit by a single lamp...*
>
> Inside, the Rogue commanders are huddled around a map of the battlefield.
> One of them slams their fist on the table — **"Tonight, we take them down for good."**
> The other commanders nod. They begin marking targets on the map.
> The camera pulls back to show an ENORMOUS army of rogue clones lined up outside, stretching into the darkness...
>
> *Cut to black. The words appear on screen:*
> **"They think you're finished. Prove them wrong."**

This cutscene plays once when you first start the game — and it immediately makes you want to fight back!

---

## 🌟 What Is The Infinite Fight?

You are a commander on a battlefield. You drag your Army clones onto the field and they fight against the enemy Rogue army on the other side.

You watch the battle from above, but at any moment you can TAP one of your clones and play as THEM in first-person — right in the middle of the action!

---

## 👤 Creating Your Profile (First Time Only)

When you first open the game, you'll be asked to set up your profile:

- **Choose a name** — up to 10 characters long
- **Names are unique** — no two players can have the same name, so finding a friend is easy (just type their name!)
- **Choose your difficulty** — this affects how hard battles are AND how fast you unlock new guns

---

## ⚔️ Difficulty Levels

| Level | What It Means |
|-------|--------------|
| 😊 **Easy** | Enemies are weak. Unlocks come quickly! |
| 😐 **Medium** | A fair fight. Good for learning the game. |
| 😤 **Hard** | Enemies hit harder. Unlocks are slower. |
| 🩸 **Bloodthirsty** | Enemies are brutal. Only for the bravest commanders! |

> **Note:** Higher difficulty = harder enemies BUT also more exciting battles!

---

## 🔓 Unlocking Army Clones & Weapons

You **start** with one Army Clone armed with a **Pistol**.

Every **5 wins** you get, you unlock the next gun — and a new clone that carries it! Losses don't count, so every win matters!

### Weapon Unlock Ladder

```
Start   → PISTOL        (your starting weapon — free!)
5 wins  → REVOLVER      (more powerful, slower reload)
10 wins → SHOTGUN       (deadly up close!)
15 wins → ASSAULT RIFLE (fast firing, medium range)
20 wins → MACHINE GUN   (unleash a storm of bullets!)
25 wins → SNIPER RIFLE  (see below — it's special!)
```

### 🎯 The Special Sniper Clone

The Sniper clone is unique — it's the ONLY clone that carries **TWO weapons**:
- Their **Sniper Rifle** (for long-range shots)
- A **secondary weapon** from your unlocked weapons list (for close-up defense)

This makes the Sniper clone the most powerful clone in your army!

---

## 🪖 Deploying Your Army — Drag & Drop!

Before each battle starts, you see your battlefield from above. On the left side of the screen is a **panel showing all your unlocked clones**.

Here's how you deploy them:

1. **Click and drag** a clone from the panel onto your side of the field
2. Place them wherever you want — front line, back row, spread out, bunched up — your choice!
3. You can place a **maximum of 10 clones** at once
4. Once you're happy with your formation, hit **FIGHT!** and the battle begins
5. Your clones will automatically start moving and shooting at the enemy

> 💡 **Strategy tip:** Put Snipers at the back (long range!) and Shotgun clones up front (close range!). Mix it up to find what works!

---

## 👆 Taking Control of a Clone

Once the battle starts:

1. **CLICK or TAP** any of your clones on the battlefield
2. The view switches to **FIRST-PERSON** — you're now inside that clone!
3. Fight as hard as you can — aim, shoot, dodge!
4. ⚠️ **WARNING:** If YOUR clone dies while you're in first-person, that's it — you don't swap to another clone. You're out of first-person until the battle ends!

> This makes choosing WHICH clone to jump into a big decision. Don't pick one that's already surrounded!

---

## 🏳️ The Last Stand! (When All Clones Fall)

If ALL 10 of your Army clones are defeated in a battle:

**You get ONE final chance — THE LAST STAND!**

- A single lone clone appears, armed with your best unlocked weapon
- It's just YOU vs whatever enemies are still standing
- Win this and you survive the battle — lose and it's game over, try again!

---

## 🎯 The Enemy (The Rogue Army)

The Rogue Army waits on the other side of the field. What weapons they carry **depends on your difficulty setting**:

| Your Difficulty | Enemy Weapons |
|-----------------|--------------|
| Easy | Mostly pistols and basic weapons |
| Medium | Match your unlocked weapons roughly |
| Hard | Better weapons than you — stay sharp! |
| Bloodthirsty | Top-tier weapons from the start. Good luck! |

Enemies also have more clones on harder difficulties — and they're smarter too!

---

## 🗺️ Level Structure

- Levels get harder as you go
- Every 5 **wins** = a new weapon unlocked + new clone type joins your army
- Some levels have **boss enemies** — one giant, tough Rogue commander you have to take down
- After each level you see your **score, time taken, and how many clones you lost**

---

## 👫 Friends System

Since every player name is unique (max 10 characters), finding friends is simple:

1. Go to the **Friends** menu
2. Type your friend's **exact player name**
3. Send a friend request!
4. Once they accept, you can see each other's level and progress

---

## 🛠️ How We'll Build It

Since you want it to work on **both PC and Mobile** and look **3D**, we'll use:

**Engine: Godot 4** (free, beginner-friendly, used for loads of real games!)
- It can build for PC AND mobile at the same time
- Has great 3D tools built right in
- Easier to learn than most other game engines

**Language: GDScript** (Godot's own coding language)
- It looks a lot like plain English — really easy to learn!
- Don't worry — we'll learn it step by step!

### Building Phases (Our Roadmap)

```
Phase 1 — The Basics
  ✅ Set up Godot project
  ✅ Create a flat battlefield
  ✅ Add one Army Clone that can move and shoot

Phase 2 — The Battle System
  ✅ Add the enemy Rogue army
  ✅ Make clones fight automatically
  ✅ Add click/tap-to-control first-person view

Phase 3 — Drag & Deploy
  ✅ Build the pre-battle clone placement screen
  ✅ Add drag-and-drop to place up to 10 clones
  ✅ Add the FIGHT! button to start the battle

Phase 4 — Progression
  ✅ Add the win counter system
  ✅ Add weapon unlocks every 5 wins
  ✅ Add the Sniper clone with dual weapons

Phase 5 — Story & Game Feel
  ✅ Create the intro cutscene
  ✅ Add difficulty settings
  ✅ Add the Last Stand mechanic
  ✅ Add player name + friend system

Phase 6 — Polish & Release
  ✅ Add sound effects and music
  ✅ Add menus and nice graphics
  ✅ Test on phone AND computer
```

---

## 💡 Cool Extra Ideas (For Later!)

Once the basics are working, here are some fun things we could add:

- 🏆 **Leaderboard** — who has reached the highest level worldwide?
- 🎨 **Clone Skins** — change what your army looks like
- 🗺️ **Different Maps** — forest, desert, snow battlefield
- 💥 **Special Abilities** — each clone type gets a superpower
- 🏅 **Achievements** — earn medals for doing cool things in battle
- 📺 **More Cutscenes** — story moments between big levels

---

*Plan created: May 2026*
*Let's build something amazing! 🚀*
