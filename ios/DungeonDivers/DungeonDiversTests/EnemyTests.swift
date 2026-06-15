import XCTest
@testable import DungeonDivers

final class EnemyTests: XCTestCase {

    private func make(scale: Int = 0, isBoss: Bool = false,
                      isFinal: Bool = false, postGameDepth: Int = 0) -> Enemy {
        Enemy(kind: Bestiary.fodder[0], scaleLevel: scale,
              isBoss: isBoss, isFinalBoss: isFinal, postGameDepth: postGameDepth)
    }

    func testBaseStatsMatchJavaOriginal() {
        let e = make()
        XCTAssertEqual(e.hp, 50)
        XCTAssertEqual(e.attack, 15)
        XCTAssertEqual(e.defense, 5)
        XCTAssertEqual(e.luck, 5)
        XCTAssertEqual(e.level, 1)
    }

    func testScalingAddsPerGroup() {
        let e = make(scale: 2)
        XCTAssertEqual(e.hp, 50 + 30)
        XCTAssertEqual(e.attack, 15 + 30)
        XCTAssertEqual(e.defense, 5 + 10)
        XCTAssertEqual(e.level, 3)
    }

    func testLuckTightensAtScale3AndPostGame() {
        XCTAssertEqual(make(scale: 3).luck, 3)   // bestiary "level 4"
        XCTAssertEqual(make(postGameDepth: 1).luck, 1)
    }

    func testEndlessScalingCompoundsAndOutgrows() {
        let base = make(scale: 5)                       // a layer-6-ish fodder, pre-mult
        let deep = make(scale: 5, postGameDepth: 1)     // same, first post-game layer
        let deeper = make(scale: 5, postGameDepth: 12)  // far into endless
        XCTAssertGreaterThan(deep.attack, base.attack)  // post-game multiplier kicks in
        XCTAssertGreaterThan(deeper.attack, deep.attack * 3) // compounds hard
        XCTAssertGreaterThan(deeper.hp, deep.hp * 3)
    }

    func testFinalBossFixedStatBlock() {
        let dragon = make(isBoss: true, isFinal: true)
        XCTAssertEqual(dragon.hp, 150)
        XCTAssertEqual(dragon.attack, 100)
        XCTAssertEqual(dragon.defense, 0)
    }

    func testNormalBossBump() {
        let boss = make(scale: 0, isBoss: true)
        XCTAssertEqual(boss.hp, 50 + 15)
        XCTAssertEqual(boss.attack, 15 + 10)
        XCTAssertEqual(boss.defense, 0)   // 5 - 5
    }

    func testGenerateGoldIsAttackTimesLevel() {
        let e = make(scale: 1)            // attack 30, level 2
        XCTAssertEqual(e.generateGold(), 30 * 2)
    }
}
