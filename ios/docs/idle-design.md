# Dungeon Divers — Idle / Incremental Design Study

Research-grounded plan for adopting idle-game behavior. **Spec only — nothing
here is implemented.** Decide the adoption level (§4) before building; the three
levels differ hugely in scope.

Sources surveyed (June 2026): the "Math of Idle Games" series (Game Developer /
Kongregate), idle best-practice writeups, and current top-titles roundups —
Cookie Clicker, Clicker Heroes, AdVenture Capitalist, Melvor Idle, Revolution
Idle, Legend of Mushroom, NGU/Antimatter Dimensions lineage. Links at the bottom.

---

## 1. What the popular idle games actually do

Common DNA across the genre:

1. **Automated resource generation** — income accrues on a timer without input;
   "clicker" games start with active taps that you later automate.
2. **Generators/producers you buy** — each costs more the more you own;
   production stacks. The whole game is "buy producer → income rises → afford
   bigger producer".
3. **Exponential cost vs. polynomial production** — costs must outrun production
   so there's always a next goal. Costs grow geometrically; production grows
   (roughly) linearly/polynomially per tier but compounds across tiers.
4. **Milestone multipliers** — owning 25/50/100/… of a producer doubles its
   output; flat global multipliers from upgrades.
5. **Prestige / ascension** — reset progress for a permanent multiplier currency.
   The core "ladder climb": you blow past old walls faster each reset. This is
   *the* defining modern mechanic (popularized by Cookie Clicker).
6. **Offline progress** — accrue (usually capped, sometimes reduced-rate) income
   while the app is closed; collect on return.
7. **Automation unlocks** — auto-buyers, auto-prestige, "managers" (AdVenture
   Capitalist) that remove the last bits of manual work.
8. **Big-number presentation** — K/M/B/T → aa/ab/… or scientific notation, with
   satisfying roll-ups.

## 2. The core math (concrete constants)

- **Generator cost:** `cost(n) = base · r^n`, where `n` = count already owned and
  `r` ≈ **1.07–1.15** (Cookie Clicker uses 1.15; gentler curves use ~1.07).
- **Generator production:** `out = baseOut · count · ∏(multipliers)`. Total
  income/sec = Σ over all generator tiers.
- **Cost must outpace production:** keep production growth polynomial while cost
  growth stays exponential, so each purchase buys *less* time than the last —
  that's the treadmill that makes prestige necessary.
- **Milestone bonus:** ×2 output every 25 (then 50, 100…) of a generator.
- **Prestige currency (Cookie-Clicker style):**
  `prestige = floor( (totalEarnedThisRun / K)^0.5 )` — square-root scaling means
  each additional prestige point needs ~quadratically more earnings. Each point
  grants a permanent global multiplier (e.g. **+1–2% per point**, multiplicative
  or additive).
- **Offline gain:** on launch, `elapsed = now − lastSeen`; grant
  `incomePerSec · min(elapsed, cap) · efficiency`. Typical `cap` 2–12h (upgrade
  to extend); `efficiency` 50–100%.

## 3. Mapping idle patterns onto Dungeon Divers

The current game is a turn-based RPG: hero vs. one enemy at a time, 5 enemies per
layer, bosses, gold, level-ups, a shop, status effects (see `docs/future-work.md`
and the code in `ios/DungeonDivers/DungeonDivers/`). Idle translation:

| Idle concept | Dungeon Divers equivalent |
|---|---|
| Income/sec | **Hero auto-attacks on a timer**; DPS derived from `attack`, crit %, move kit. Killing the current enemy yields its `generateGold()`. |
| "Buy a generator" | Buy/upgrade **combat stats & party members** (see below) — each purchase raises DPS or gold-per-kill. |
| Generator tiers | **Mercenaries/party**: hire Goblin Slayer, Mage, etc.; each adds flat DPS, milestone-doubles at 25/50/100. (Mirrors Clicker Heroes heroes.) |
| Cost scaling | Reuse the existing geometric shop price (`base · 1.7^owned`) — tune toward `1.07–1.15` for idle pacing. |
| Zones / level treadmill | **Layers** become the depth treadmill; enemy HP already scales (`postGameDepth` exponential we just added). Deeper layer = more gold/kill but tankier foes. |
| Boss timers | Optional Clicker-Heroes-style **timed boss** every 5th enemy (kill within N s or retreat). |
| Prestige / ascension | **"Descend into the Abyss"**: reset layers + gold + hired party for **Soul Shards** = `floor((goldEarnedThisRun / K)^0.5)`. Shards buy a permanent skill tree (global ×DPS, ×gold, offline cap, auto-buy). Maps cleanly onto the existing `BestRun`/run-reset plumbing. |
| Offline progress | On launch, compute `elapsed`; auto-resolve kills at current DPS vs. current layer, award gold (capped). Show a "While you were away…" summary. |
| Automation | Auto-attack (always on in idle), **auto-advance layers**, **auto-buy** cheapest upgrade, **auto-descend** at a threshold — each unlocked via the shard tree. |
| Big numbers | Add a `Formatting` helper (K/M/B/T/aa…); gold, DPS, shards all use it. Existing `contentTransition(.numericText())` still gives roll-ups. |

What carries over directly: `GameEngine` state machine, `Enemy` scaling, the
shop economy, `Player` stats, `RandomSource`, persistence pattern (`BestRun`).
What's new: a **game tick** (`Timer`/`TimelineView`), **DPS model**, **prestige
layer + skill tree**, **offline delta-time accrual**, **`Codable` full save**,
**number formatting**.

## 4. Adoption levels (pick one — this is the fork)

**A. Idle-flavored meta, manual combat stays (smallest).**
Keep turn-based fights as-is. Add: offline gold accrual, a prestige/ascension
reset between runs for permanent multipliers, exponential meta-upgrade tree, and
big-number formatting. Combat feel unchanged; the *progression* becomes idle.
~Low risk, reuses almost everything. Good if you like the combat.

**B. Hybrid active/idle (medium).**
Keep manual combat as the "active" high-engagement mode, but add an **auto-battle
idle mode** that runs on a tick (and offline), generating gold/kills passively.
Player drops in to play actively for bonuses, or lets it idle. Two loops sharing
one `GameEngine`. Most "modern idle" feel without throwing away the RPG.

**C. Full idle/auto-battler pivot (largest).**
Rebuild around the tick: hero auto-fights, you spend gold on DPS generators /
party, climb zones, descend for shards, automate everything. Combat becomes a
spectacle, not a turn-by-turn decision. This is "Clicker Heroes set in the
Dungeon Divers world." Biggest change; manual `Move` choices become optional
actives/abilities on cooldown.

**Recommendation:** **B (hybrid)** — it banks all the work already done (combat,
status effects, shop, bosses) and layers the idle loop on top, so neither
audience is alienated and we can ship the idle mechanics incrementally (offline +
tick first, then prestige, then automation).

## 5. Build order (once a level is chosen)

Shared foundation (all levels need most of this):
1. **`GameClock`** — a tick (`Timer.publish` / `TimelineView(.periodic)`),
   pausable, drives auto-combat and accrual. Keep the model UI-free; the view
   owns the timeline and calls `engine.tick(dt:)`.
2. **DPS / income model** — derive damage-per-second from stats + kit; define
   `goldPerSecond` for offline math.
3. **Offline progress** — persist `lastSeen: Date`; on launch grant capped
   accrual + a summary screen.
4. **`Codable` save/restore** of the full `GameEngine` (currently only `BestRun`
   persists) — needed so idle progress survives.
5. **`Formatting.short(_:)`** big-number helper.
6. **Prestige layer** — `SoulShards`, ascension reset, a skill-tree screen
   (`Phase.ascension`), permanent multipliers applied in the DPS/gold math.
7. **Automation** unlocks gated behind the tree.
8. **Balancing pass** — set `r` (cost), production curve, prestige `K`, offline
   cap so a session has the classic "bumpy" fast/slow rhythm.

## 6. Risks & notes

- **Genre shift:** idle ≠ the faithful Java port. Level A/B preserve the homage;
  C departs from it. Worth being deliberate.
- **Balancing is the whole game** in idle — expect heavy tuning; the
  injectable-RNG + tests we added help validate the math deterministically.
- **Battery/perf:** cap the tick (e.g. 5–10 Hz), pause when backgrounded and use
  delta-time on resume rather than running a fast timer in the background.
- **Reduce Motion / accessibility:** number roll-ups and any new motion must keep
  honoring `accessibilityReduceMotion` (pattern already established).
- **Offline cap + fairness:** uncapped offline trivializes; cap it and sell
  extensions via prestige (standard genre move).

## Sources

- [The Math of Idle Games, Part I](https://www.gamedeveloper.com/design/the-math-of-idle-games-part-i)
- [The Math of Idle Games, Part III (prestige)](https://www.gamedeveloper.com/design/the-math-of-idle-games-part-iii)
- [Math — the backbone of Idle Games (Medium)](https://medvescekmurovec.medium.com/math-the-backbone-of-idle-games-part-1-f46b54706cf1)
- [Idle Games Best Practices (GridInc)](https://gridinc.co.za/blog/idle-games-best-practices)
- [Incremental game (Grokipedia)](https://grokipedia.com/page/Incremental_game)
- [Best Idle Games 2024 (Videogamer)](https://www.videogamer.com/guides/best-idle-games/)
- [Revolution Idle (Steam)](https://store.steampowered.com/app/2763740/Revolution_Idle/)
