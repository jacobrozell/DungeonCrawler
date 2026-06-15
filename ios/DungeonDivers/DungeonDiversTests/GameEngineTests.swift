import XCTest
@testable import DungeonDivers

@MainActor
final class GameEngineTests: XCTestCase {

    /// Always-hit RNG (d10 roll of 9 clears any luck threshold).
    private func engine() -> GameEngine {
        let e = GameEngine(playerName: "Hero", rng: ScriptedRandom(fallback: 9))
        e.startGame(named: "Hero")
        return e
    }

    func testStartGameEntersCombatOnFirstEnemy() {
        let e = engine()
        XCTAssertEqual(e.phase, .combat)
        XCTAssertEqual(e.layer, 1)
        XCTAssertEqual(e.enemyIndex, 1)
        XCTAssertFalse(e.log.isEmpty)
    }

    func testKillAwardsGoldAndSpawnsNext() {
        let e = engine()
        let goldBefore = e.player.gold
        let reward = e.enemy.generateGold()
        e.enemy.hp = 1                 // one hit will kill
        e.perform(.attack)
        XCTAssertEqual(e.player.gold, goldBefore + reward)
        XCTAssertEqual(e.enemyIndex, 2)
        XCTAssertEqual(e.phase, .combat)
    }

    func testFifthKillIsBossAndTriggersLevelUp() {
        let e = engine()
        for _ in 1...5 {
            e.enemy.hp = 1
            e.perform(.attack)
        }
        XCTAssertEqual(e.phase, .levelUp)
        XCTAssertEqual(e.layer, 2)      // advanced after the boss
    }

    func testChooseUpgradeResumesCombat() {
        let e = engine()
        for _ in 1...5 { e.enemy.hp = 1; e.perform(.attack) }
        e.chooseUpgrade(.attack)
        XCTAssertEqual(e.phase, .combat)
        XCTAssertEqual(e.player.level, 2)
        XCTAssertEqual(e.enemyIndex, 1)  // first enemy of the new layer
    }

    func testPlayerDeathEndsRun() {
        let e = engine()
        e.player.hp = 1                  // next enemy swing is lethal
        e.perform(.attack)               // enemy survives (full HP), then retaliates
        XCTAssertEqual(e.phase, .defeat)
        XCTAssertFalse(e.player.isAlive)
    }

    func testMagicBlockedWithoutMana() {
        let e = engine()
        e.player.spendMana(e.player.mana)   // drain to 0
        let countBefore = e.log.count
        e.perform(.magic)
        XCTAssertTrue(e.log.last?.text.contains("Not enough mana") == true)
        // Only the rejection line was added; no combat resolved.
        XCTAssertEqual(e.log.count, countBefore + 1)
    }
}
