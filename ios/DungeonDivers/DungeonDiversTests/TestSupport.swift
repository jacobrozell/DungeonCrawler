import XCTest
@testable import DungeonDivers

/// A `RandomSource` that returns a scripted queue of values, so tests can force
/// exact hit/crit/proc/spawn outcomes. Once the queue is exhausted it returns
/// `fallback` (clamped into the requested range).
final class ScriptedRandom: RandomSource {
    private var queue: [Int]
    private let fallback: Int

    /// - Parameters:
    ///   - values: rolls returned in order (each interpreted within the asked range).
    ///   - fallback: value returned after the queue empties (default 0 → always "hit"
    ///     for `checkHit`, "no crit" for `chance`, first element for `element`).
    init(_ values: [Int] = [], fallback: Int = 0) {
        self.queue = values
        self.fallback = fallback
    }

    func roll(_ range: Range<Int>) -> Int {
        let raw = queue.isEmpty ? fallback : queue.removeFirst()
        guard !range.isEmpty else { return range.lowerBound }
        // Clamp into range so a scripted value can't crash the generator.
        return min(max(raw, range.lowerBound), range.upperBound - 1)
    }
}

extension XCTestCase {
    /// `checkHit` lands when roll >= chance; a roll of 9 (max d10) always lands,
    /// a roll of 0 lands only when chance == 0. These helpers make intent clear.
    func alwaysHitRNG() -> ScriptedRandom { ScriptedRandom(fallback: 9) }
    func alwaysMissRNG() -> ScriptedRandom { ScriptedRandom(fallback: 0) } // misses when chance > 0
}
