import Foundation

/// Central tuning knobs. One place to balance the whole game.
///
/// Target feel (the numbers below aim for these; adjust after a real playtest):
/// - **Fights:** ~3–8 turns to kill a normal enemy; mana regen keeps the full
///   move kit usable instead of degrading to basic attacks.
/// - **Campaign (layers 1–5):** a focused ~10–20 min climb, beatable but with a
///   threatening Imperial Red Dragon.
/// - **Endless:** stats compound so a run always ends; depth is the score.
///   Gentle growth (≈1.12/layer) makes deep runs feel earned, not abrupt.
/// - **Prestige:** clearing the campaign yields a satisfying handful of Soul
///   Shards; each descent + tree spend visibly blows past the old wall.
/// - **Offline:** a few hours away pays out meaningfully; capped so it never
///   trivializes an active session.
enum Balance {

    // MARK: Combat
    /// Mana regained at the end of every combat round (keeps abilities flowing).
    static let manaRegenPerTurn = 2
    static let critMultiplier = 2.0
    /// Minimum crit chance (%); the rest scales with luck in `rollCrit`.
    static let minCritChancePercent = 5

    // MARK: Moves
    static let heavyManaCost = 5
    static let magicManaCost = 8
    static let poisonManaCost = 4
    static let heavyDamageMultiplier = 1.8
    static let magicFlatBonus = 5            // added to attack, ignores defense
    static let heavyStunChancePercent = 20
    static let magicBurnChancePercent = 35
    static let bossPoisonChancePercent = 25

    // MARK: Enemy scaling
    /// Per-layer compounding multipliers applied in endless (post-dragon).
    /// HP grows faster than ATK so deep fights get *tankier* (a DPS race) rather
    /// than one-shotting you — which keeps survival prestige meaningful.
    static let enemyEndlessHpGrowth = 1.10
    static let enemyEndlessAtkGrowth = 1.06

    // MARK: Shop
    /// Geometric price growth per permanent upgrade owned.
    static let shopPriceGrowth = 1.6

    // MARK: Prestige
    /// Shards on descent = floor(sqrt(runGoldEarned / this)).
    static let prestigeShardDivisor = 100.0
    static let mightAttackPerLevel = 0.05      // +5% starting attack / level
    static let fortuneGoldPerLevel = 0.08      // +8% gold / level
    static let vitalityHpPerLevel = 0.06       // +6% starting max HP / level
    static let wardReductionPerLevel = 0.03    // +3% damage reduction / level
    static let maxDamageReduction = 0.60       // Ward caps here (keeps deaths possible)
    static let patienceHoursPerLevel = 1       // +1h offline cap / level
    static let patienceEfficiencyPerLevel = 0.05
    /// Automation (auto-resolve level-up/shop) unlocks at this many shards.
    static let automationUnlockShards = 1

    // MARK: Offline
    static let baseOfflineHours = 8.0
    static let baseOfflineEfficiency = 0.5
    static let maxOfflineEfficiency = 1.0

    // MARK: Idle
    static let tickSeconds = 1.0
}
