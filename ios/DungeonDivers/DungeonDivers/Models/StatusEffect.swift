import Foundation

/// Kinds of status effect a combatant can carry. `burn`/`poison` are
/// damage-over-time (tick at end of round, bypass defense); `stun` skips the
/// afflicted's next action; `guardUp`/`focus` are timed player buffs.
enum StatusKind: String {
    case burn
    case poison
    case stun
    case guardUp
    case focus

    var label: String {
        switch self {
        case .burn:    return "Burn"
        case .poison:  return "Poison"
        case .stun:    return "Stun"
        case .guardUp: return "Guard"
        case .focus:   return "Focus"
        }
    }

    /// Emoji used for the small status badge in the combat UI.
    var badge: String {
        switch self {
        case .burn:    return "🔥"
        case .poison:  return "☠️"
        case .stun:    return "💫"
        case .guardUp: return "🛡️"
        case .focus:   return "🎯"
        }
    }

    var isDamageOverTime: Bool { self == .burn || self == .poison }
}

/// A status instance on a combatant. `magnitude` is damage/turn for DoT (or a
/// stat delta for buffs); `stacks` currently only grows for poison.
struct StatusEffect: Identifiable, Equatable {
    let id = UUID()
    let kind: StatusKind
    var turnsRemaining: Int
    var magnitude: Int
    var stacks: Int = 1
}
