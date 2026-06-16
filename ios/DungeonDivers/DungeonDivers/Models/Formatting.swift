import Foundation

/// Idle-style big-number formatting: 1,234 → "1.23K", 5e6 → "5.00M", etc.
/// Keeps small numbers exact and compresses large ones (K/M/B/T then aa, ab…).
enum Formatting {
    private static let units = ["", "K", "M", "B", "T",
                                "aa", "ab", "ac", "ad", "ae", "af", "ag"]

    static func short(_ value: Int) -> String { short(Double(value)) }

    static func short(_ value: Double) -> String {
        guard value >= 1000 else { return String(Int(value.rounded())) }
        var n = value
        var i = 0
        while n >= 1000 && i < units.count - 1 {
            n /= 1000
            i += 1
        }
        // 2 decimals under 10, 1 under 100, none otherwise — the classic look.
        let format = n < 10 ? "%.2f%@" : (n < 100 ? "%.1f%@" : "%.0f%@")
        return String(format: format, n, units[i])
    }
}
