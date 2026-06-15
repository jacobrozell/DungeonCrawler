# Dungeon Divers — Design Spec: Gold Shop & Status Effects

Future-work design for two features. Nothing here is implemented yet; this
document is the plan. It references the current code so it can be picked up
directly:

- `Models/GameEngine.swift` — `@MainActor` state machine, `Phase`, combat
  resolution, `Player`/`Enemy` ownership.
- `Models/Player.swift`, `Models/Enemy.swift`, `Models/Combatant.swift`.
- `Models/GameEngine.swift` → `Move` enum, `LogLine`, `CombatPopup`, `BestRun`.
- `Views/` — `ContentView` routes on `Phase`; one screen per phase.

---

## Ideas backlog (unscoped — pick and spec before building)

> **Idle/incremental direction:** a dedicated, research-grounded study lives in
> [`idle-design.md`](idle-design.md) — idle-game patterns (generators, prestige,
> offline progress, automation) mapped onto Dungeon Divers, with three adoption
> levels and a build order. Awaiting a pick on how far to pivot.

Candidate additions beyond the current build order, roughly by value:

**Gameplay depth**
- Real audio assets + the `feedback(_:_:)` indirection (finishes Step 5).
- Equipment/relics: persistent passives (lifesteal, thorns, +crit) found or bought.
- More moves & a small cooldown/charge system; enemy-specific abilities
  (healer adds, casters that apply burn, armored foes immune to crit).
- Enemy intent telegraphs ("the dragon is winding up…") for tactical choices.
- Difficulty modes / daily seed (the `RandomSource` seam already supports it).
- Boss mechanics (phases, enrage timers, adds).

**Meta-progression**
- Persistent currency/unlocks across runs (separate from run gold).
- Achievements; a richer stats screen (kills, crits, gold earned).
- Multiple playable classes (mage/rogue/warrior) with different kits/stats.

**Polish & feel**
- Particle/impact effects, parallax dungeon backgrounds per layer.
- Real app icon + launch screen art (currently placeholder asset slots).
- Localization (strings are inline today) and Dynamic Type passes.
- VoiceOver labels on combat state (log already gives full text).

**Technical**
- Wire the unit-test target (see "Testing") + CI (`xcodebuild test`).
- Save/restore an in-progress run (`Codable` snapshot of `GameEngine`).
- SwiftUI previews for each screen; snapshot tests.
- Extract balancing constants into one tunable `Balance` struct.

## Progress log (for the next agent)

Newest first. Update this as you land work so whoever picks up next knows the state.

- **2026-06-15 — Idle pivot = HYBRID (chosen). Part 1: auto-battle tick +
  big-number formatting. DONE.** (Plan: `idle-design.md`.)
  - `Models/Formatting.swift`: `Formatting.short(_:)` (K/M/B/T/aa…). Applied to
    gold in `CombatView` header, `ShopView` (gold + prices), `GameOverView`,
    title best-run.
  - `GameEngine`: `autoBattle` flag, `toggleAuto()`, `tick()` (no-op unless
    `autoBattle && phase == .combat`), and `autoMove()` heuristic (heal when
    <35% HP, else strongest affordable move). The tick pauses outside combat so
    the player still makes level-up / shop / (future) ascension choices — that's
    the hybrid hook.
  - `CombatView`: ~1 Hz `Timer.publish` drives `engine.tick()`; an Auto-Battle
    on/off toggle added above the moves (both portrait & landscape).
  - Registered `Formatting.swift` (pbxproj id 0018). Tests: `FormattingTests`,
    plus auto-tick tests in `GameEngineTests`.
  - **Remaining hybrid parts (next):** (2) offline progress — persist
    `lastSeen: Date`, accrue capped gold at an estimated rate on launch, "while
    you were away" summary; needs (3) `Codable` full save/restore of
    `GameEngine` (only `BestRun` persists today). (4) Prestige/ascension —
    `SoulShards = floor((goldThisRun/K)^0.5)`, `Phase.ascension`, a skill-tree
    screen, permanent ×DPS/×gold/offline-cap multipliers, reset plumbing reusing
    `startGame`. (5) Automation unlocks (auto-advance, auto-buy, auto-descend)
    gated behind the tree. (6) Balancing. See `idle-design.md` §5.
  - The 1 Hz timer always runs; `tick()` guards cheaply. If battery shows up as
    a concern, pause via `scenePhase` and use delta-time on resume.

- **2026-06-15 — Step 6 (partial): endless rebalance — "score chase". DONE.**
  - Problem: the shop let players snowball into trivial runs. Without the shop,
    enemy HP (+15/layer) already outgrew player per-hit damage (~+5/layer), but
    gold income is **quadratic** (`enemyATK × level`) while shop prices were
    **linear**, so buying out-paced scaling and the game got easier forever.
  - Fix (chosen direction: *endless score chase that always ends in death*):
    - `Enemy` now takes `postGameDepth` (= `layer - 5`, 0 during layers 1–5) and
      applies a **compounding ×1.15^depth** multiplier to HP/ATK/DEF in endless.
      Pre-game (1–5) balance is untouched; the dragon stays fixed 150/100/0.
      Exponential beats any linear/polynomial build → every run terminates.
    - Shop permanent upgrades now priced **geometrically** (`base × 1.7^owned`)
      so quadratic gold can't fully out-buy the curve.
    - Victory/endless copy reframed as "how deep can you go?". Depth is already
      the headline stat in `BestRun` / game-over.
  - **Deliberately did NOT add literal stat soft-caps** (the 4th option mentioned
    them): the exponential enemy curve already guarantees the run ends, and caps
    risk muddying the faithful early game. Easy to add later if endless still
    feels too long — clamp `Player.maxAttack/maxDefense` or add diminishing
    level-up deltas above a threshold.
  - Tuning knobs: enemy `pow(1.15, …)` in `Enemy.init`; shop `pow(1.7, …)` in
    `GameEngine.price`. Lower the enemy base for longer runs, raise for shorter.
  - Tests updated (`EnemyTests` signature + new `testEndlessScalingCompounds…`;
    `GameEngineTests` geometric-price assertion; `StatusEffectTests` helper).
  - Not playtested for the *feel* of the curve (no Xcode) — numbers are a
    first pass; expect to tune `1.15`/`1.7` after a real run.

- **2026-06-15 — Step 5: sound & music (code + wiring). DONE (assets pending).**
  - `Models/SoundManager.swift`: `SFX`/`MusicTrack` enums + a singleton that
    plays via `AVFoundation` **iff** the file is in the bundle, else silent
    no-op. `.ambient` + `.mixWithOthers` session. Toggles read from
    `UserDefaults` (`audio.sfxEnabled`/`audio.musicEnabled`, default on).
  - SFX wired at engine trigger points (swing/crit/magic/poison/playerHurt/
    enemyDie/playerDie/bossAppear/levelUp/victory/purchase/denied), mirroring
    the haptics.
  - Music driven by `ContentView.onChange(of: phase)` → `playMusic` (title /
    combat[+levelUp/shop] / victory / gameover).
  - `Views/SettingsView.swift` (sheet, `@AppStorage` toggles); gear button added
    to `TitleView`.
  - `Audio/CREDITS.md` lists required file names; **no audio ships yet** — the
    authoring env can't generate binaries. Game is fully playable silent. To
    enable: drop files in `DungeonDivers/Audio/…`, add to the target's Copy
    Bundle Resources, fill in the credits table.
  - Registered `SoundManager.swift`/`SettingsView.swift` in pbxproj (ids 0016/0017).
  - ⚠️ No tests for audio (hardware side-effecting). The `feedback(_:_:)`
    indirection from the spec was *not* added — calls are inline next to
    haptics. Add the indirection + a protocol seam if you want to assert cues.

- **2026-06-15 — Step 4: gold shop. DONE.**
  - `Models/ShopItem.swift`: consumables (potion/ether) + permanent upgrades
    (whetstone/towerShield/heartVial/luckyCoin) with name/icon/blurb/price.
  - `Player`: `spendGold`, `potions`/`ethers`, `usePotion`/`useEther`,
    `upgradeAttack/Defense/MaxHp`, `improveLuck`.
  - `GameEngine`: new `Phase.shop`; `chooseUpgrade` now routes level-up →
    `.shop`; `enterNextEncounter()` extracted (spawn + combat/victory);
    `price`/`canAfford`/`buy`/`leaveShop`; in-combat `usePotion`/`useEther`
    (cost the turn). `purchaseCounts` drives linear price scaling and resets
    each run.
  - `Views/ShopView.swift` (card grid, gold header, dive button); routed in
    `ContentView`. `CombatView` gains a `consumablesRow` (potions/ethers).
  - Registered `ShopItem.swift`/`ShopView.swift` in the pbxproj (ids 0014/0015).
  - Tests added to `GameEngineTests` (shop flow, scaling, broke-guard, potion
    use). Updated the old level-up test for the new shop hop.
  - Flow is `boss → levelUp → shop → (victory once) → combat`. Note the shop
    currently appears *before* the victory screen on the final-boss clear — fine,
    but reorder in `enterNextEncounter` if that feels off.

- **2026-06-15 — Steps 2 & 3: status effects + poison move/boss debuffs. DONE.**
  - `Models/StatusEffect.swift`: `StatusKind` (burn/poison/stun/guardUp/focus)
    with badge/label, and `StatusEffect` (turns/magnitude/stacks).
  - `Combatant` now requires `statuses: [StatusEffect]`; extension adds
    `applyStatus` (refresh + stack), `isStunned`, `consumeStunIfNeeded`,
    `damageOverTimeThisTurn`, and `tickStatuses()`. **Stun is consumed by
    action, not time** — `tickStatuses` deliberately does not decrement stun.
  - `GameEngine`: `perform` handles a stunned hero; `endRound()` runs the DoT
    tick (enemy then player) and then `resolveDeaths()` — all death detection
    stays centralized. DoT bypasses defense and surfaces via the existing
    popup/log/flash.
  - Application: Magic→burn (35%), Heavy→stun (20%), new **Poison Dagger**
    move (`Move.poison`, 4 mana, stacks poison up to ×5), bosses→poison on the
    player (25%). `guardUp`/`focus` buff hooks exist in `enemyRetaliates`/
    `rollCrit` but nothing applies them yet (reserved for shop items).
  - UI: `StatusBadges` row under each combatant; Poison Dagger added to the
    (now 6-button, 2-column) move grid + `buttonColor`.
  - Tests: `DungeonDiversTests/StatusEffectTests.swift` (model + 2 engine
    integration tests).
  - `RandomSource.swift` and `StatusEffect.swift` were added to the app target
    in the hand-written pbxproj (FR/BF/Sources/Models group) — see "Adding new
    source files". Test files are in the (still-unwired) test target.
  - Note: a heavy-strike stun lands on the enemy *before* its same-turn
    retaliation, so in practice it negates that immediate counterattack. This is
    intentional and consistent ("skip your next action"). Nothing currently
    stuns the *player*, so the hero-stun branch in `perform` is reserved.

- **2026-06-15 — Step 1: injectable RNG + combat-math tests. DONE.**
  - Added `Models/RandomSource.swift`: `RandomSource` protocol with `roll(_:)`,
    plus `chance(_:)` / `element(_:)` helpers, `SystemRandom` (production), and
    `SeededRandom` (SplitMix64, deterministic).
  - `Dice.checkHit` now takes `rng:`. `GameEngine` owns
    `private let rng: RandomSource` (init param defaults to `SystemRandom()`);
    all probability — `checkHit`, `rollCrit`, and enemy/boss selection
    (`rng.element`) — routes through it. No `Int.random`/`randomElement()` left
    in game logic.
  - Tests written under `DungeonDivers/DungeonDiversTests/` (`TestSupport.swift`
    with `ScriptedRandom`, plus `Dice`/`Player`/`Enemy`/`GameEngine` tests).
  - ⚠️ **Test target not yet wired into the project** — see "Testing" below.
    The test files exist and compile against the app module; they just need a
    target. Do this before relying on `xcodebuild test`.
  - Not build-verified (no Xcode in the authoring environment).

**Build order status:** [x] 1 RNG+tests · [x] 2 status effects ·
[x] 3 poison move/boss debuffs · [x] 4 gold shop · [x] 5 sound (code; assets
pending) · [ ] 6 balancing.

### Testing — wiring the unit-test target

The pbxproj is hand-written, so the test target was intentionally **not**
hand-edited (a bad UUID makes the project unopenable, and there's no Xcode here
to verify). To enable the tests:

1. In Xcode: **File ▸ New ▸ Target… ▸ Unit Testing Bundle**, name it
   `DungeonDiversTests`, host application `DungeonDivers`.
2. Delete the auto-created stub file; **add the existing files** in
   `DungeonDiversTests/` to the new target.
3. Ensure the app target builds for testing (`@testable import DungeonDivers`
   needs `ENABLE_TESTABILITY = YES` in Debug — already set).
4. Run with ⌘U or `xcodebuild test -scheme DungeonDivers -destination
   'platform=iOS Simulator,name=iPhone 15'`.

(If a future agent does have a working Xcode/CLI, wiring it directly into the
pbxproj is fine — just verify the project still opens.)

### Adding new source files (hand-written pbxproj)

The `.xcodeproj/project.pbxproj` is maintained by hand (no Xcode here). Adding
an app-target Swift file means four parallel insertions, following the existing
`BF…`/`FR…` numbering (next free id is **0014**):

1. **PBXBuildFile**: `BF00…NN /* X.swift in Sources */ = {… fileRef = FR00…NN …};`
2. **PBXFileReference**: `FR00…NN /* X.swift */ = {… path = X.swift; …};`
3. **PBXGroup** (`Models` `GR…0003` or `Views` `GR…0004`): add the `FR…NN` child.
4. **PBXSourcesBuildPhase** (`SR…0000`): add the `BF…NN` entry.

Keep ids unique and the `/* comments */` consistent so the file stays readable.
If you have Xcode, just drag the file in instead.

---

## 1. Gold Shop

### Goal
Gold is currently meta-only (tracked, shown, saved in `BestRun`) but unspendable.
The shop turns gold into an in-run economy and a meaningful reward loop.

### When it appears
A new `Phase.shop`. The natural cadence is **once per layer, right after the
level-up choice**, so the post-boss flow becomes:

```
boss defeated → .levelUp (choose stat) → .shop (spend gold) → .combat
```

Integration point: in `GameEngine.chooseUpgrade(_:)`, instead of going straight
to `.combat`/`.victory`, transition to `.shop`. The shop's "Continue" button
then performs the existing spawn + `.combat`/`.victory` logic (extract that tail
of `chooseUpgrade` into a `private func enterNextEncounter()` and call it from
the shop exit).

Edge: the victory celebration should still fire once. Keep `victoryShown`
bookkeeping in `enterNextEncounter()` so order is `.levelUp → .shop →
.victory(once) → .combat`.

### Inventory model
Add a consumables inventory to `Player`:

```swift
enum Item: String, CaseIterable, Identifiable {
    case potion        // heal
    case ether         // restore mana
    case whetstone     // +ATK (permanent, this run)
    case tower         // +DEF (permanent, this run)
    case heartVial      // +max HP (permanent, this run)
    case luckyCoin      // -1 luck value (improves hit/crit; floor at 1)
    var id: String { rawValue }
}

// In Player:
private(set) var potions: Int = 0
private(set) var ethers: Int = 0
```

Two item categories:

| Item | Type | Effect | Base price | Notes |
|------|------|--------|-----------|-------|
| Potion | consumable | grants 1 charge; used via the existing **Heal** move OR a new "use potion" combat affordance | 25g | Decide: either gate Heal behind potions, or keep Heal free and make potions a *stronger* instant heal. Recommended: keep Heal free; potions = instant `+ (15 × level)`, no enemy retaliation. |
| Ether | consumable | restores `maxMana` instantly in combat | 20g | Enables more Magic/Heavy in a fight. |
| Whetstone | permanent | `maxAttack += 5; attack = maxAttack` | 40g | Stacks; price scales (see below). |
| Tower Shield | permanent | `maxDefense += 5; defense = maxDefense` | 40g | Stacks. |
| Heart Vial | permanent | `maxHp += 15`, full heal | 50g | Stacks. |
| Lucky Coin | permanent | `luck = max(1, luck - 1)` | 60g | Strong: improves both hit rate and crit. Cap purchases (e.g. luck floor 1). |

Add matching mutators to `Player` (mirroring the clamp style of `levelUp`):
`buyWhetstone()`, `buyTower()`, `buyHeartVial()`, `buyLuckyCoin()`,
`addPotions(_:)`, `addEthers(_:)`, and `spendGold(_:) -> Bool` (returns false if
unaffordable). `gold` becomes spendable; keep `addGold` as-is.

### Pricing / scaling
Permanent upgrades should inflate so gold keeps mattering deep into endless mode.
Track purchase counts and scale price:

```
price(base, owned) = base + base * owned   // linear; or base * pow(1.5, owned) for steeper
```

Consumables (potion/ether) stay flat-priced. Tune against `Enemy.generateGold()`
(= `attack × level`), which grows with `scaleLevel`, so a layer's ~5 kills should
roughly afford one permanent upgrade early on.

### Combat use of consumables
- **Ether**: add `Move.useEther` OR a small inventory bar above the move grid.
  Recommended: an **items row** in `CombatView` (potions × N, ethers × N) so it
  doesn't crowd the `Move` enum. Tapping consumes one, applies effect, and —
  like Heal at full HP — decide whether it costs the turn. Recommended: using an
  item **does** cost the turn (enemy retaliates with `bonusChance: 1`, matching
  Heal) to avoid trivializing fights.
- Persist nothing across runs (consumables reset on `startGame`). Permanent
  upgrades also reset per run — they're roguelite run-scoped, not meta.

### UI: `ShopView`
New file `Views/ShopView.swift`, same visual language (`Panel`, `Theme`,
`PressableButtonStyle`, `ScrollFit` for landscape/short screens):

- Header: current gold (gold-tinted, `contentTransition(.numericText())`).
- A list/grid of item cards: icon (SF Symbol), name, short effect, price.
  Disabled + dimmed when unaffordable (reuse the move-button affordability
  pattern). Tap → `engine.buy(.item)`; play `Haptics.play(.success)` / `.warning`
  on fail.
- "Continue diving" button → `engine.leaveShop()`.

`GameEngine` API:
```swift
@Published private(set) var player  // already
func buy(_ item: Player.Item)       // validates gold, applies, logs, haptics
func leaveShop()                    // → enterNextEncounter()
```

### Balancing knobs
- Starting gold (currently 0 — fine).
- Whether permanent upgrades are capped per run.
- Potion heal strength vs. free Heal move.
- Price curve constant.

### Test hooks
Pure, testable additions: `Player.spendGold`, each `buyX`, `price(base:owned:)`.
Add to a future test target without touching SwiftUI.

---

## 2. Status Effects

### Goal
Add tactical depth: damage-over-time, control, and buffs that play off the
existing Attack/Heavy/Magic/Dodge/Heal kit and the luck-based hit/crit system.

### Model
New `Models/StatusEffect.swift`:

```swift
enum StatusKind: String {
    case burn       // DoT, ignores defense
    case poison     // DoT, scales with stacks
    case stun       // skips the afflicted's next action
    case guard      // +DEF for N turns (player buff via a future move/item)
    case focus      // +crit for N turns (player buff)
}

struct StatusEffect: Identifiable {
    let id = UUID()
    let kind: StatusKind
    var turnsRemaining: Int
    var magnitude: Int        // dmg/turn, or stat delta
    var stacks: Int = 1       // poison stacks; others usually 1
}
```

Add to `Combatant`:
```swift
var statuses: [StatusEffect] { get set }
```
…and a default-implemented helper in the protocol extension to add/refresh a
status (stack poison, refresh burn duration, etc.).

### Turn lifecycle
Combat is strictly turn-based in `GameEngine.perform(_:)`. Insert two hooks:

1. **Start of the player's action** (top of `perform`): if the player is
   `stun`-ned, consume the stun, log "You are stunned!", run enemy tick + enemy
   turn, then `return` (player loses the turn). Otherwise proceed.
2. **End of the round** (just before `resolveDeaths()`): call
   `tickStatuses(on: enemy)` then `tickStatuses(on: player)`.

`tickStatuses(on:)`:
- For `burn`/`poison`: apply `magnitude × stacks` damage (burn ignores defense;
  poison too — DoT bypasses DEF), emit a `CombatPopup` (`.damage`) and a
  `.enemyHit`/`.playerHit` `LogLine`, then decrement `turnsRemaining`.
- For timed buffs (`guard`/`focus`): just decrement.
- Remove expired effects (`turnsRemaining <= 0`).
- DoT can kill: after ticking the enemy, the existing `resolveDeaths()` will see
  `!enemy.isAlive` and award gold/advance. After ticking the player, it will see
  `!player.isAlive` → `.defeat`. **Important:** route DoT death through the same
  `resolveDeaths()` so `recordRun()` and phase transitions stay centralized.

Enemy `stun`: if the enemy is stunned at the moment it would retaliate
(`enemyRetaliates`), consume the stun and skip the swing with a log line.

### How effects are applied
Extend the kit rather than rewriting it:

| Source | Applies | Detail |
|--------|---------|--------|
| **Magic Bolt** (`.magic`) | `burn` | e.g. 25% chance, `magnitude = max(2, level)`, 3 turns. Thematic: bolt sears. |
| New **Poison Dagger** move (`Move.poison`, mana 4) | `poison` | weak direct hit + applies/stacks poison (`magnitude = level`, 3 turns, stacks up to 5). |
| **Heavy Strike** (`.heavy`) | `stun` | small chance (e.g. 20%) to stun the enemy's next turn. |
| Certain **bosses** | `poison`/`stun` on the *player* | e.g. a "Warlord Shaman" applies poison on its hit; gate behind `Enemy.isBoss` + an `appliesStatus` field on `EnemyKind`. |
| Shop items / future moves | `guard`, `focus` | optional buffs. |

To add a move, extend the `Move` enum (rawValue label, `sfSymbol`, `manaCost`,
`buttonColor`) and a `case` in `perform`. The grid in `CombatView.moveButtons`
already lays out N moves; adding one is mechanical (watch the 2-column grid +
full-width Heal layout — may want a 3-wide grid if the move count grows).

### UI
- **Status badges**: small pill row under each combatant's name in
  `CombatView.enemyStage` / `playerStatus` — icon + turns left
  (🔥 `burn`, ☠️ `poison ×n`, 💫 `stun`, 🛡️ `guard`, 🎯 `focus`). Tint via
  `Theme`. Keep `.secondary`/adaptive so it reads in light + dark.
- **DoT popups**: reuse `CombatPopup` (`.damage`) so burn/poison ticks float
  numbers like normal hits.
- **Reduce Motion**: status ticks already animate via the existing popup path,
  which honours Reduce Motion.

### Interaction with existing systems
- **Defense**: DoT ignores DEF (design choice — keeps poison/burn relevant vs.
  high-DEF bosses). Direct hits keep `max(1, ATK − DEF)`.
- **Crit**: `focus` buff adds to `rollCrit()` chance for its duration.
- **Dodge**: does it cleanse/avoid DoT? Recommended no — dodge only avoids the
  enemy's direct swing; DoT still ticks. Optionally a future item cleanses.
- **Death ordering**: all death detection must remain in `resolveDeaths()`;
  status ticks only mutate HP and emit popups/logs.

### Balancing knobs
- Proc chances and DoT magnitudes (scale with `player.level`).
- Poison stack cap and whether stacks refresh duration.
- Stun chance (keep low; stun is powerful).
- Boss-applied statuses per layer.

### Test hooks
`tickStatuses` and the stack/refresh helper are pure and testable with a
seeded/forced setup (inject a `Combatant` with known statuses, assert HP delta
and remaining turns). Proc chances should funnel through a single injectable
RNG (see below) so tests are deterministic.

---

## Shared prerequisite: injectable RNG

Both features add probability (crit already does, plus procs). Today
`Dice.checkHit` and `rollCrit` call `Int.random` directly, which is untestable.
Recommended refactor before building either feature:

```swift
protocol RandomSource { func roll(_ range: Range<Int>) -> Int }
struct SystemRandom: RandomSource { func roll(_ r: Range<Int>) -> Int { Int.random(in: r) } }
```

Inject a `RandomSource` into `GameEngine` (default `SystemRandom`), route
`Dice`, `rollCrit`, and all new procs through it. Tests pass a stub for
deterministic outcomes. This unblocks a real unit-test target for the combat
math at the same time.

---

## 3. Sound & Music

### Goal
Audio feedback that parallels the existing haptics. The cleanest design is a
`Sound` helper that mirrors `Haptics` (see `Views/Theme.swift`): a single enum
of named cues with a `play(_:)` entry point, called from the same places in
`GameEngine` where `Haptics.play(...)` already fires.

### Audio assets needed

**SFX** (short, < 1s unless noted). Suggested format: `.caf` or `.m4a`
(small, hardware-decoded) — `.wav` is fine too. Mono, 44.1kHz.

| Cue | Trigger (in `GameEngine`) | Pairs with haptic |
|-----|---------------------------|-------------------|
| `swing` | `resolveAttack` / Heavy on a normal landed hit | `.light` |
| `crit` | `resolveAttack` when `rollCrit()` true | `.medium` |
| `miss` | any `checkHit` failure (player or enemy) | — |
| `magic` | `resolveMagic` | `.light` |
| `playerHurt` | `enemyRetaliates` / dodge-fail lands on player | `.heavy` |
| `heal` | `resolveHeal` and clean-dodge recovery | — |
| `enemyDie` | `resolveDeaths` enemy slain | `.success` |
| `bossAppear` | `spawnNextEnemy` when `isBoss` | — |
| `gold` | `resolveDeaths` gold award | — |
| `levelUp` | `handleBossDefeated` → `.levelUp` | — |
| `buttonTap` | move/menu button press (optional, can be subtle) | — |
| `purchase` / `denied` | shop buy success/fail (future §1) | `.success` / `.warning` |
| `playerDie` | `resolveDeaths` player death | `.error` |
| `victory` | final-boss clear (`clearedFinalBoss`) | — |
| `status_burn` / `status_poison` / `status_stun` | DoT ticks / stun (future §2) | — |

**Music** (looping, ~1–2 min loops, `.m4a` AAC to keep size down):

| Track | Where |
|-------|-------|
| `theme_title` | `Phase.title` |
| `theme_combat` | `Phase.combat` (optionally a tenser variant for boss encounters) |
| `theme_boss` | optional: swap in when `enemy.isBoss` |
| `theme_victory` | `Phase.victory` |
| `theme_gameover` | `Phase.defeat` |

### Where assets live
Add an audio folder to the app target and reference by name:

```
DungeonDivers/
  Audio/
    SFX/        swing.caf, crit.caf, … (added to target, "Copy Bundle Resources")
    Music/      theme_title.m4a, theme_combat.m4a, …
```

`pbxproj`: add the files as `PBXFileReference`s under a new `Audio` group and to
the existing `Resources` build phase (`RS00000000000000000000`), exactly like
`Assets.xcassets` is wired today. Load with `Bundle.main.url(forResource:withExtension:)`.

### `Sound` helper (new file `Models/SoundManager.swift`)

```swift
import AVFoundation

enum SFX: String {
    case swing, crit, miss, magic, playerHurt, heal, enemyDie,
         bossAppear, gold, levelUp, buttonTap, purchase, denied,
         playerDie, victory, statusBurn, statusPoison, statusStun
    var resource: String { rawValue }     // file name without extension
    var ext: String { "caf" }
}

enum Music: String {
    case title, combat, boss, victory, gameover
}

@MainActor
final class SoundManager: ObservableObject {
    static let shared = SoundManager()

    @AppStorage("audio.sfxEnabled") var sfxEnabled = true
    @AppStorage("audio.musicEnabled") var musicEnabled = true

    private var players: [String: AVAudioPlayer] = [:]   // preloaded SFX
    private var musicPlayer: AVAudioPlayer?

    private init() { configureSession(); preload() }

    func play(_ sfx: SFX) { /* guard sfxEnabled; play preloaded, reset to 0 */ }
    func playMusic(_ track: Music) { /* guard musicEnabled; crossfade, numberOfLoops = -1 */ }
    func stopMusic() {}
    // react to toggles: stop/resume music when musicEnabled flips.
}
```

Design notes:
- **Preload** SFX into `AVAudioPlayer` instances at init and call
  `prepareToPlay()` so first-hit latency is low. For overlapping rapid SFX,
  either keep a tiny pool per cue or set `player.currentTime = 0` before
  `play()` (turn-based combat rarely overlaps, so single instances are fine).
- **Audio session**: configure `.ambient` with `.mixWithOthers` so the game
  doesn't stop the user's music, and respects the hardware mute switch
  (`.ambient` honours the silent switch — desirable for a casual game).
- **Music**: `numberOfLoops = -1`; do a short manual volume crossfade on track
  change (Timer or `setVolume(_:fadeDuration:)`).

### Integration points
Mirror the haptics calls. In `GameEngine`, alongside each `Haptics.play(...)`
add `SoundManager.shared.play(.x)`. To avoid scattering, consider routing both
through one place:

```swift
private func feedback(_ haptic: Haptics.Feel?, _ sfx: SFX?) {
    if let h = haptic { Haptics.play(h) }
    if let s = sfx { SoundManager.shared.play(s) }
}
```

…then call `feedback(.light, .swing)` etc. from `flashEnemy`/`flashPlayer`/
`resolveDeaths`. Music transitions are driven by `Phase` changes — easiest to
trigger from the view layer via `.onChange(of: engine.phase)` in `ContentView`
(keeps `AVFoundation` out of the model), calling `SoundManager.shared.playMusic`.

### Settings UI
Add a small settings affordance (gear button on the title screen, or a sheet)
exposing the two `@AppStorage` toggles. `@AppStorage` persists automatically and
needs no `GameEngine` changes. Mute defaults: both on.

### Accessibility / etiquette
- Respect the silent switch (via `.ambient` session) and never duck/stop other
  audio (`.mixWithOthers`).
- Keep SFX short and non-fatiguing; provide the mute toggles above.
- No audio-only information — every cue already has a visual + log counterpart,
  so the game is fully playable muted (and for VoiceOver users).

### Asset sourcing
Sounds are binary assets this repo doesn't generate. Options: royalty-free packs
(e.g. Kenney.nl game audio, freesound.org CC0), or commissioned chiptune.
Document license/attribution in `Audio/CREDITS.md`.

### Test hooks
`SoundManager` is side-effecting (hardware), so keep `GameEngine` free of
`AVFoundation`. The `feedback(_:_:)` indirection can be made injectable
(a protocol) if you want to assert "death plays `playerDie`" in tests, but
that's optional — the combat-math tests (shared RNG section) are the priority.

---

## Suggested build order
1. Injectable RNG refactor (+ first combat-math tests).
2. Status effects (model, tick lifecycle, Magic→burn + Heavy→stun, badges).
3. Poison Dagger move + boss-applied statuses.
4. Gold shop (`Phase.shop`, `ShopView`, `Player` economy, consumables row).
5. Sound & music (`SoundManager`, asset wiring, settings toggles).
6. Balancing pass across pricing, proc rates, DoT magnitudes, and audio mix.
