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
    var statuses: [StatusEffect] { get set }
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

    // MARK: - Status effects

    /// Add a status, or refresh/stack an existing one of the same kind.
    /// Refreshing keeps the longer duration and stronger magnitude; `poison`
    /// also accrues stacks up to `maxStacks`.
    func applyStatus(_ kind: StatusKind, turns: Int, magnitude: Int, maxStacks: Int = 1) {
        if let i = statuses.firstIndex(where: { $0.kind == kind }) {
            statuses[i].turnsRemaining = max(statuses[i].turnsRemaining, turns)
            statuses[i].magnitude = max(statuses[i].magnitude, magnitude)
            statuses[i].stacks = min(maxStacks, statuses[i].stacks + 1)
        } else {
            statuses.append(StatusEffect(kind: kind, turnsRemaining: turns,
                                         magnitude: magnitude, stacks: 1))
        }
    }

    var isStunned: Bool { statuses.contains { $0.kind == .stun } }

    /// Removes one stun if present; returns whether the turn should be skipped.
    func consumeStunIfNeeded() -> Bool {
        guard let i = statuses.firstIndex(where: { $0.kind == .stun }) else { return false }
        statuses.remove(at: i)
        return true
    }

    /// Total damage-over-time this round (bypasses defense by design).
    func damageOverTimeThisTurn() -> Int {
        statuses.filter { $0.kind.isDamageOverTime }
                .reduce(0) { $0 + $1.magnitude * $1.stacks }
    }

    /// Apply one round of DoT and decrement timed statuses; drop the expired.
    /// `stun` is *not* time-decremented — it's consumed by the victim's next
    /// action (`consumeStunIfNeeded`), so it survives the end-of-round tick.
    /// Returns the DoT damage dealt (0 if none) for the caller to surface.
    func tickStatuses() -> Int {
        let dot = damageOverTimeThisTurn()
        if dot > 0 { takeHit(dot) }
        for i in statuses.indices where statuses[i].kind != .stun {
            statuses[i].turnsRemaining -= 1
        }
        statuses.removeAll { $0.turnsRemaining <= 0 && $0.kind != .stun }
        return dot
    }
}
