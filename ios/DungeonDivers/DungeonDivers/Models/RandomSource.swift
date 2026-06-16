import Foundation

/// Injectable randomness so combat math is deterministic under test.
///
/// `GameEngine` owns a `RandomSource` (defaulting to `SystemRandom`); tests pass
/// a `SeededRandom` (or a scripted stub) to force specific hit/crit/proc/spawn
/// outcomes. All probability in the game — `Dice.checkHit`, `rollCrit`, status
/// procs, and enemy/boss selection — must route through this rather than calling
/// `Int.random` / `randomElement()` directly.
protocol RandomSource: AnyObject {
    /// Uniform integer in `range`. `range` must be non-empty.
    func roll(_ range: Range<Int>) -> Int
}

extension RandomSource {
    /// True with probability `percent`/100 (clamped to 0...100).
    func chance(_ percent: Int) -> Bool {
        let p = max(0, min(100, percent))
        return roll(0..<100) < p
    }

    /// Pick a uniformly random element. Returns nil only for an empty array.
    func element<T>(_ array: [T]) -> T? {
        guard !array.isEmpty else { return nil }
        return array[roll(0..<array.count)]
    }
}

/// Production randomness backed by the system generator.
final class SystemRandom: RandomSource {
    func roll(_ range: Range<Int>) -> Int { Int.random(in: range) }
}

/// Deterministic generator for tests (SplitMix64). Same seed → same sequence.
final class SeededRandom: RandomSource {
    private var state: UInt64

    init(seed: UInt64 = 0x9E3779B97F4A7C15) { state = seed }

    private func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    func roll(_ range: Range<Int>) -> Int {
        let count = UInt64(range.count)
        guard count > 0 else { return range.lowerBound }
        return range.lowerBound + Int(next() % count)
    }
}
