import Foundation

/// A single enemy archetype: name plus the sprite/colour used to draw it.
struct EnemyKind {
    let name: String
    let sprite: String   // emoji "sprite"
    let tint: String     // asset/colour name hint, resolved in the view layer
}

/// The bestiary. The first five names match the Java original
/// (Goblin, Troll, Pixie, Wolf, Gnoll); the rest are new to the iOS clone
/// to give each layer more variety.
enum Bestiary {
    static let fodder: [EnemyKind] = [
        EnemyKind(name: "Goblin",       sprite: "👺", tint: "green"),
        EnemyKind(name: "Troll",        sprite: "🧌", tint: "green"),
        EnemyKind(name: "Pixie",        sprite: "🧚", tint: "pink"),
        EnemyKind(name: "Wolf",         sprite: "🐺", tint: "gray"),
        EnemyKind(name: "Gnoll",        sprite: "🦴", tint: "brown"),
        EnemyKind(name: "Skeleton",     sprite: "💀", tint: "gray"),
        EnemyKind(name: "Giant Spider", sprite: "🕷️", tint: "purple"),
        EnemyKind(name: "Slime",        sprite: "🟢", tint: "green"),
        EnemyKind(name: "Bat Swarm",    sprite: "🦇", tint: "purple"),
        EnemyKind(name: "Cave Imp",     sprite: "👹", tint: "red"),
    ]

    /// Mid-layer bosses (the original five plus extras).
    static let bosses: [EnemyKind] = [
        EnemyKind(name: "Blue Dragon Boss",           sprite: "🐲", tint: "blue"),
        EnemyKind(name: "Giant Troll Boss",           sprite: "🧌", tint: "green"),
        EnemyKind(name: "Warlord Shaman Boss",        sprite: "🧙", tint: "purple"),
        EnemyKind(name: "Treasure Seeker Goblin Boss", sprite: "🤑", tint: "yellow"),
        EnemyKind(name: "Bloodthirsty Gnoll Boss",    sprite: "🐗", tint: "red"),
        EnemyKind(name: "Lich King Boss",             sprite: "☠️", tint: "purple"),
        EnemyKind(name: "Minotaur Boss",              sprite: "🐂", tint: "brown"),
    ]

    static let finalBoss = EnemyKind(name: "Imperial Red Dragon", sprite: "🐉", tint: "red")
}

/// An enemy instance, ported from `Enemy.java`.
///
/// In the Java version the per-enemy max stats were `static`, so every enemy
/// permanently strengthened the *whole* bestiary as the run went on. The clone
/// reproduces that escalating difficulty by feeding the cumulative scaling in
/// through `scaleLevel` (managed by `GameEngine`) rather than via globals.
final class Enemy: Combatant {
    let name: String
    let sprite: String
    let tint: String

    var hp: Int
    private(set) var maxHp: Int
    private(set) var attack: Int
    private(set) var defense: Int
    private(set) var luck: Int
    private(set) var level: Int
    var statuses: [StatusEffect] = []

    let isBoss: Bool

    /// Base stats match the Java defaults: HP 50 / ATK 15 / DEF 5 / luck 5.
    init(kind: EnemyKind, scaleLevel: Int, isBoss: Bool, isFinalBoss: Bool, postGame: Bool) {
        self.name = kind.name
        self.sprite = kind.sprite
        self.tint = kind.tint
        self.isBoss = isBoss

        // Cumulative scaling: every completed group of 5 added +15/+15/+5 to
        // the static maxes in the original. `scaleLevel` counts those bumps.
        var hpStat = 50 + 15 * scaleLevel
        var atkStat = 15 + 15 * scaleLevel
        var defStat = 5 + 5 * scaleLevel
        var luckStat = 5
        var lvl = 1 + scaleLevel

        // Luck improved (became 3, i.e. easier to hit you) once the bestiary
        // reached level 4 in the original; post-game it was pinned harsher.
        if scaleLevel + 1 >= 4 { luckStat = 3 }
        if postGame { luckStat = 1 }

        if isFinalBoss {
            // The Imperial Red Dragon's fixed stat block from GameDriver.
            hpStat = 150
            atkStat = 100
            defStat = 0
            lvl = max(lvl, 5)
        } else if isBoss {
            // Bosses get a flat bump over the current fodder line.
            if postGame {
                hpStat += 30
                atkStat += 20
            } else {
                hpStat += 15
                atkStat += 10
                defStat = max(0, defStat - 5)
                luckStat += 1
            }
        }

        self.maxHp = hpStat
        self.hp = hpStat
        self.attack = atkStat
        self.defense = defStat
        self.luck = luckStat
        self.level = lvl
    }

    /// Gold reward, ported from `generateGold`: attack × level.
    func generateGold() -> Int {
        attack * level
    }
}
