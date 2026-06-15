import XCTest
@testable import DungeonDivers

final class PlayerTests: XCTestCase {

    func testBaseStatsMatchJavaOriginal() {
        let p = Player(name: "Hero")
        XCTAssertEqual(p.hp, 60)
        XCTAssertEqual(p.attack, 25)
        XCTAssertEqual(p.defense, 10)
        XCTAssertEqual(p.luck, 3)
        XCTAssertEqual(p.level, 1)
        XCTAssertEqual(p.gold, 0)
    }

    func testEmptyNameFallsBackToDiver() {
        XCTAssertEqual(Player(name: "").name, "Diver")
        XCTAssertEqual(Player(name: "Aria").name, "Aria")
    }

    func testLevelUpAttackBumpsChosenStatMoreAndRestores() {
        let p = Player(name: "Hero")
        p.takeHit(40)                 // hp 20
        p.levelUp(.attack)
        XCTAssertEqual(p.level, 2)
        XCTAssertEqual(p.attack, 35)  // +10 chosen
        XCTAssertEqual(p.defense, 15) // +5 others
        XCTAssertEqual(p.maxHp, 70)   // +10 others
        XCTAssertEqual(p.hp, 70)      // fully restored
    }

    func testLevelUpHealthBumpsHpBy20() {
        let p = Player(name: "Hero")
        p.levelUp(.health)
        XCTAssertEqual(p.maxHp, 80)   // +20 chosen
        XCTAssertEqual(p.attack, 30)  // +5 others
        XCTAssertEqual(p.defense, 15) // +5 others
    }

    func testRestoreHpClampsToMax() {
        let p = Player(name: "Hero")
        p.takeHit(10)
        p.restoreHp(999)
        XCTAssertEqual(p.hp, p.maxHp)
    }

    func testManaSpendAndRestoreClamp() {
        let p = Player(name: "Hero")
        p.spendMana(8)
        XCTAssertEqual(p.mana, 12)
        p.spendMana(999)
        XCTAssertEqual(p.mana, 0)     // never negative
        p.restoreMana(999)
        XCTAssertEqual(p.mana, p.maxMana)
    }

    func testTakeHitFloorsAtZero() {
        let p = Player(name: "Hero")
        p.takeHit(9999)
        XCTAssertEqual(p.hp, 0)
        XCTAssertFalse(p.isAlive)
    }
}
