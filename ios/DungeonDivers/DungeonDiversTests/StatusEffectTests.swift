import XCTest
@testable import DungeonDivers

final class StatusEffectTests: XCTestCase {

    private func enemy() -> Enemy {
        Enemy(kind: Bestiary.fodder[0], scaleLevel: 0,
              isBoss: false, isFinalBoss: false, postGameDepth: 0)
    }

    func testApplyStacksPoisonAndRefreshes() {
        let e = enemy()
        e.applyStatus(.poison, turns: 3, magnitude: 2, maxStacks: 5)
        e.applyStatus(.poison, turns: 2, magnitude: 4, maxStacks: 5)
        XCTAssertEqual(e.statuses.count, 1)
        XCTAssertEqual(e.statuses[0].stacks, 2)
        XCTAssertEqual(e.statuses[0].turnsRemaining, 3) // keeps the longer
        XCTAssertEqual(e.statuses[0].magnitude, 4)      // keeps the stronger
    }

    func testTickAppliesDoTBypassingDefenseAndExpires() {
        let e = enemy()                       // defense 5
        e.applyStatus(.burn, turns: 2, magnitude: 5)
        let hp0 = e.hp
        let dot = e.tickStatuses()
        XCTAssertEqual(dot, 5)                // ignores the 5 defense
        XCTAssertEqual(e.hp, hp0 - 5)
        XCTAssertEqual(e.statuses.first?.turnsRemaining, 1)
        _ = e.tickStatuses()                  // second tick → expires
        XCTAssertTrue(e.statuses.isEmpty)
    }

    func testStackedPoisonScalesDamage() {
        let e = enemy()
        e.applyStatus(.poison, turns: 3, magnitude: 3, maxStacks: 5)
        e.applyStatus(.poison, turns: 3, magnitude: 3, maxStacks: 5) // 2 stacks
        XCTAssertEqual(e.damageOverTimeThisTurn(), 6)
    }

    func testStunSurvivesTickAndIsConsumedByAction() {
        let e = enemy()
        e.applyStatus(.stun, turns: 1, magnitude: 0)
        _ = e.tickStatuses()
        XCTAssertTrue(e.isStunned, "stun must not be time-decremented")
        XCTAssertTrue(e.consumeStunIfNeeded())
        XCTAssertFalse(e.isStunned)
        XCTAssertFalse(e.consumeStunIfNeeded()) // nothing left to consume
    }

    @MainActor
    func testPoisonMovePoisonsEnemy() {
        let g = GameEngine(playerName: "Hero", rng: ScriptedRandom(fallback: 9))
        g.startGame(named: "Hero")
        g.enemy.hp = 999                      // ensure it survives the hit + DoT
        g.perform(.poison)
        XCTAssertTrue(g.enemy.statuses.contains { $0.kind == .poison })
    }

    @MainActor
    func testHeavyStunSkipsEnemyRetaliation() {
        // fallback 9 → hit lands, stun (9 < 20%) procs, enemy forfeits its swing.
        let g = GameEngine(playerName: "Hero", rng: ScriptedRandom(fallback: 9))
        g.startGame(named: "Hero")
        g.enemy.hp = 999
        let hpBefore = g.player.hp
        g.perform(.heavy)
        XCTAssertEqual(g.player.hp, hpBefore, "stunned enemy should not retaliate")
    }
}
