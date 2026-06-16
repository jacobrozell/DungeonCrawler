import Foundation

/// Items sold in the between-layers shop. Consumables are flat-priced;
/// permanent upgrades inflate with how many you already own (see
/// `GameEngine.price(_:)`).
enum ShopItem: String, CaseIterable, Identifiable {
    case potion
    case ether
    case whetstone
    case towerShield
    case heartVial
    case luckyCoin

    var id: String { rawValue }

    var name: String {
        switch self {
        case .potion:      return "Potion"
        case .ether:       return "Ether"
        case .whetstone:   return "Whetstone"
        case .towerShield: return "Tower Shield"
        case .heartVial:   return "Heart Vial"
        case .luckyCoin:   return "Lucky Coin"
        }
    }

    /// Emoji icon (kept emoji for parity with the sprite art elsewhere).
    var icon: String {
        switch self {
        case .potion:      return "🧪"
        case .ether:       return "🔮"
        case .whetstone:   return "🗡️"
        case .towerShield: return "🛡️"
        case .heartVial:   return "❤️"
        case .luckyCoin:   return "🍀"
        }
    }

    var blurb: String {
        switch self {
        case .potion:      return "Carry one. Heals 15×level in combat."
        case .ether:       return "Carry one. Refills mana in combat."
        case .whetstone:   return "+5 max Attack (permanent)."
        case .towerShield: return "+5 max Defense (permanent)."
        case .heartVial:   return "+15 max HP, full heal (permanent)."
        case .luckyCoin:   return "Improves your luck (permanent)."
        }
    }

    /// Permanent upgrades scale in price; consumables stay flat.
    var isPermanent: Bool {
        switch self {
        case .potion, .ether: return false
        default:              return true
        }
    }

    var basePrice: Int {
        switch self {
        case .potion:      return 25
        case .ether:       return 20
        case .whetstone:   return 40
        case .towerShield: return 40
        case .heartVial:   return 50
        case .luckyCoin:   return 60
        }
    }
}
