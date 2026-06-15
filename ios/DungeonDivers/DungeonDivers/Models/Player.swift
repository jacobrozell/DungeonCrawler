import Foundation

/// The hero, ported from `Player.java`.
///
/// Base stats (HP 60 / ATK 25 / DEF 10 / luck 3) match the Java original.
/// Levelling up bumps the chosen stat by the larger amount and every other
/// stat by the smaller amount, then fully restores the hero — exactly as the
/// original `levelUp(int)` did.
final class Player: Combatant {
    enum Upgrade: CaseIterable {
        case attack, defense, health

        var label: String {
            switch self {
            case .attack: return "Attack"
            case .defense: return "Defense"
            case .health: return "Health"
            }
        }

        var icon: String {
            switch self {
            case .attack: return "burst.fill"
            case .defense: return "shield.lefthalf.filled"
            case .health: return "heart.fill"
            }
        }
    }

    let name: String

    private(set) var maxHp: Int = 60
    private(set) var maxAttack: Int = 25
    private(set) var maxDefense: Int = 10

    var hp: Int = 60
    private(set) var attack: Int = 25
    private(set) var defense: Int = 10
    private(set) var luck: Int = 3
    private(set) var level: Int = 1
    private(set) var gold: Int = 0

    /// Mana powers the expanded Magic / Heavy moves that the iOS clone adds
    /// on top of the original three actions.
    private(set) var maxMana: Int = 20
    var mana: Int = 20

    var statuses: [StatusEffect] = []

    /// Consumables bought in the shop (see `ShopItem`). Run-scoped.
    private(set) var potions: Int = 0
    private(set) var ethers: Int = 0

    init(name: String) {
        self.name = name.isEmpty ? "Diver" : name
    }

    func restoreHp(_ amount: Int) {
        hp += amount
        if hp > maxHp { hp = maxHp }
    }

    func restoreMana(_ amount: Int) {
        mana += amount
        if mana > maxMana { mana = maxMana }
    }

    func spendMana(_ amount: Int) {
        mana = max(0, mana - amount)
    }

    func addGold(_ amount: Int) {
        gold += amount
    }

    // MARK: - Shop economy

    /// Spend gold if affordable; returns whether the purchase went through.
    @discardableResult
    func spendGold(_ amount: Int) -> Bool {
        guard gold >= amount else { return false }
        gold -= amount
        return true
    }

    func addPotions(_ n: Int) { potions += n }
    func addEthers(_ n: Int) { ethers += n }

    /// Quaff a potion: a strong instant heal (`15 × level`). Returns false if none.
    @discardableResult
    func usePotion() -> Bool {
        guard potions > 0 else { return false }
        potions -= 1
        restoreHp(15 * level)
        return true
    }

    /// Drink an ether: refill mana. Returns false if none.
    @discardableResult
    func useEther() -> Bool {
        guard ethers > 0 else { return false }
        ethers -= 1
        restoreMana(maxMana)
        return true
    }

    /// Permanent (run-scoped) upgrades sold in the shop.
    func upgradeAttack(by n: Int = 5) { maxAttack += n; attack = maxAttack }
    func upgradeDefense(by n: Int = 5) { maxDefense += n; defense = maxDefense }
    func upgradeMaxHp(by n: Int = 15) { maxHp += n; hp = maxHp }
    func improveLuck() { luck = max(1, luck - 1) }

    /// Faithful port of the Java level-up: chosen stat +10 (HP +20),
    /// all others +5 (HP +10), then refill to the new maximums. The clone
    /// also tops mana up a little so the new layer starts fresh.
    func levelUp(_ upgrade: Upgrade) {
        level += 1

        maxAttack += (upgrade == .attack) ? 10 : 5
        maxDefense += (upgrade == .defense) ? 10 : 5
        maxHp += (upgrade == .health) ? 20 : 10

        attack = maxAttack
        defense = maxDefense
        hp = maxHp

        maxMana += 5
        mana = maxMana
    }
}
