# Dungeon Divers — iOS

A SwiftUI iOS remake of the original one-night Java console game
([`GameDriver.java`](../GameDriver.java), [`Player.java`](../Player.java),
[`Enemy.java`](../Enemy.java)). The turn-based combat math is ported faithfully,
then dressed up with graphics, animation, and a wider move set / bestiary.

## Running it

1. Open `ios/DungeonDivers/DungeonDivers.xcodeproj` in Xcode 15+.
2. Pick an iPhone simulator (iOS 16+) and press **Run** (⌘R).

No third-party dependencies — pure SwiftUI.

## How to play

- Enter your name, then **Begin the Crawl**.
- Each layer has **5 enemies**; the 5th is a **boss**.
- Clear a boss to advance a layer and **level up** (pick a stat to boost).
- Reach **Layer 5** and slay the **Imperial Red Dragon** to win — then keep
  diving in endless mode.
- You lose when your HP hits 0.

## Moves

| Move | Origin | Effect |
|------|--------|--------|
| **Attack** | original | Standard hit (`ATK − enemy DEF`), can miss via the d10 luck roll; can **crit** for 2× (chance scales with luck). |
| **Heavy Strike** | new | ~1.8× damage, costs 5 mana. |
| **Magic Bolt** | new | Ignores enemy defense, always lands, costs 8 mana. |
| **Dodge** | original | Try to avoid the next hit; a clean dodge restores HP + mana. |
| **Heal** | original | Restore `10 × level` HP; enemy gets a slightly better swing. |

A lethal blow skips the enemy's retaliation — just like the original's
`break` out of the combat switch.

## Faithful combat math

- **Hit check** (`Dice.checkHit`): roll a d10 (0–9); the hit lands when the
  roll ≥ the target's `luck`. Higher luck = harder to hit. (Ported verbatim
  from the Java `checkHit`.)
- **Player base stats**: HP 60 / ATK 25 / DEF 10 / luck 3.
- **Enemy base stats**: HP 50 / ATK 15 / DEF 5 / luck 5.
- **Level-up**: the chosen stat rises by the larger amount (HP +20, others
  +10) and every other stat by the smaller amount (HP +10, others +5), then
  the hero is fully restored.
- **Imperial Red Dragon**: fixed HP 150 / ATK 100 / DEF 0.
- **Gold reward**: `enemy attack × enemy level`.
- **Escalating difficulty**: the Java original used `static` enemy maxes, so
  every group of five permanently strengthened the whole bestiary. The clone
  reproduces that with a cumulative `scaleLevel` in `GameEngine` instead of
  globals.

## Project layout

```
ios/DungeonDivers/
├── DungeonDivers.xcodeproj
└── DungeonDivers/
    ├── DungeonDiversApp.swift     // @main entry
    ├── Models/
    │   ├── Combatant.swift         // shared protocol + d10 hit check
    │   ├── Player.swift            // hero stats / level-up
    │   ├── Enemy.swift             // bestiary + scaling
    │   └── GameEngine.swift        // GameDriver port: state machine + combat
    └── Views/
        ├── Theme.swift             // palette, panels, animated stat bars
        ├── ContentView.swift       // phase router + title screen
        ├── CombatView.swift        // sprites, health bars, move buttons, log
        ├── LevelUpView.swift       // stat-choice screen
        └── GameOverView.swift      // victory / defeat + run summary
```

## What's new vs. the Java version

- Graphical UI: emoji sprites, animated HP/mana bars, hit flashes, scrolling
  combat log.
- **Mana** resource powering the two new moves (Heavy Strike, Magic Bolt).
- Larger **bestiary** (10 fodder types, 7 mid-bosses) with per-enemy sprites
  and colours.
- Dodge now also restores a little mana on success.
- **Critical hits** (2× damage, luck-driven) with floating combat numbers.
- Endless mode after the dragon, plus a run-summary screen.
- **Best-run persistence** (layer / level / gold) via `UserDefaults`, shown on
  the title screen and flagged with a "New best run!" badge on game over.

## Presentation

- **Light & Dark mode** — follows the system setting. Dark Mode is a moody
  dungeon; Light Mode switches to a readable "stone tablet" palette. Text uses
  `.primary`/`.secondary` and surface/accent colours adapt via a dynamic
  `UIColor` provider in `Theme`.
- **Portrait & landscape** — combat reflows into a side-by-side layout when the
  height is compact (iPhone landscape); the title, level-up and game-over
  screens scroll-fit so nothing clips on short screens.
- **Safe, lightweight animations** (no extra dependencies):
  - Enemy sprite idle-bob, a spring scale-in when each enemy spawns, and a
    flash + screen shake on every hit.
  - Numeric roll-ups (`contentTransition(.numericText())`) on gold and stats.
  - Floating combat numbers that rise and fade (damage, **CRIT!**, heals, misses).
  - Tactile button presses (`PressableButtonStyle`), a pulsing title crest,
    and spring entrances on the level-up / victory screens.
  - Haptic feedback on hits, kills and death.
  - **Reduce Motion** is honoured throughout: the shake, idle-bob, pulsing,
    spring entrances and floating travel all fall back to still / fade-only.
