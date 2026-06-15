import Foundation

/// Shared combat math used by both the player and enemies.
///
/// Ported from the original Java `checkHit` in `Player.java` / `Enemy.java`:
/// a d10 is rolled (0...9) and the attack lands when the roll is at least
/// the supplied `chance`. Higher `chance` therefore means a *harder* hit.
/// The roll comes from an injected `RandomSource` so it's testable.
enum Dice {
    static func checkHit(chance: Int, rng: RandomSource) -> Bool {
        rng.roll(0..<10) >= chance
    }
}

/// Anything that can fight: tracks pooled stats and clamps them sanely.
protocol Combatant: AnyObject {
    var name: String { get }
    var hp: Int { get set }
    var maxHp: Int { get }
    var attack: Int { get }
    var defense: Int { get }
    var luck: Int { get }
    var level: Int { get }
}

extension Combatant {
    var isAlive: Bool { hp > 0 }

    /// 0...1 health fraction for progress bars.
    var healthFraction: Double {
        guard maxHp > 0 else { return 0 }
        return max(0, min(1, Double(hp) / Double(maxHp)))
    }

    func takeHit(_ amount: Int) {
        // Mirror the original: only positive damage is meaningful, never
        // drop below zero.
        hp -= max(0, amount)
        if hp < 0 { hp = 0 }
    }
}
