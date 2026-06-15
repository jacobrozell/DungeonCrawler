import Foundation

/// Permanent prestige upgrades bought with Soul Shards (see `SkillTreeView`).
/// Shards are earned by descending; spending them here boosts every future run.
enum SkillNode: String, CaseIterable, Identifiable {
    case might      // +attack
    case fortune    // +gold
    case vitality   // +max HP
    case patience   // +offline cap & efficiency

    var id: String { rawValue }

    var name: String {
        switch self {
        case .might:    return "Might"
        case .fortune:  return "Fortune"
        case .vitality: return "Vitality"
        case .patience: return "Patience"
        }
    }

    var icon: String {
        switch self {
        case .might:    return "⚔️"
        case .fortune:  return "💰"
        case .vitality: return "❤️"
        case .patience: return "⏳"
        }
    }

    var blurb: String {
        switch self {
        case .might:    return "+5% starting Attack per level."
        case .fortune:  return "+8% gold earned per level."
        case .vitality: return "+6% starting max HP per level."
        case .patience: return "+1h offline cap & +5% offline rate per level."
        }
    }

    var maxLevel: Int { 25 }

    private var baseCost: Int {
        switch self {
        case .patience: return 3
        default:        return 1
        }
    }

    /// Shard cost to buy the level after `currentLevel` (geometric growth).
    func cost(currentLevel: Int) -> Int {
        Int((Double(baseCost) * pow(1.6, Double(currentLevel))).rounded())
    }
}
