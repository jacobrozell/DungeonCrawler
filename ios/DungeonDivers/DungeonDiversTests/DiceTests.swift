import XCTest
@testable import DungeonDivers

final class DiceTests: XCTestCase {

    func testHitWhenRollAtLeastChance() {
        // roll 5 >= chance 5 → hit
        XCTAssertTrue(Dice.checkHit(chance: 5, rng: ScriptedRandom([5])))
        // roll 4 < chance 5 → miss
        XCTAssertFalse(Dice.checkHit(chance: 5, rng: ScriptedRandom([4])))
    }

    func testChanceZeroAlwaysHits() {
        // roll 0 >= chance 0 → hit (mirrors the Java "luck 0" edge)
        XCTAssertTrue(Dice.checkHit(chance: 0, rng: ScriptedRandom([0])))
    }

    func testPercentChance() {
        XCTAssertTrue(ScriptedRandom([0]).chance(50))   // 0 < 50
        XCTAssertFalse(ScriptedRandom([50]).chance(50))  // 50 !< 50
        XCTAssertFalse(ScriptedRandom([0]).chance(0))    // 0% never procs
        XCTAssertTrue(ScriptedRandom([99]).chance(100))  // 100% always procs
    }

    func testSeededRandomIsDeterministic() {
        let a = SeededRandom(seed: 42)
        let b = SeededRandom(seed: 42)
        for _ in 0..<50 {
            XCTAssertEqual(a.roll(0..<1000), b.roll(0..<1000))
        }
    }

    func testRollStaysInRange() {
        let rng = SeededRandom(seed: 7)
        for _ in 0..<1000 {
            let v = rng.roll(3..<9)
            XCTAssertTrue((3..<9).contains(v))
        }
    }
}
