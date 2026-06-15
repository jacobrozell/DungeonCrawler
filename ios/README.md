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
| **Attack** | original | Standard hit (`ATK − enemy DEF`), can miss via the d10 luck roll. |
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
  combat log, dark dungeon theme.
- **Mana** resource powering the two new moves (Heavy Strike, Magic Bolt).
- Larger **bestiary** (10 fodder types, 7 mid-bosses) with per-enemy sprites
  and colours.
- Dodge now also restores a little mana on success.
- Endless mode after the dragon, plus a run-summary screen.
