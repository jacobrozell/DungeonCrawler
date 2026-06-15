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

    func testChooseUpgradeOpensShopThenCombat() {
        let e = engine()
        for _ in 1...5 { e.enemy.hp = 1; e.perform(.attack) }
        e.chooseUpgrade(.attack)
        XCTAssertEqual(e.phase, .shop)        // shop sits between level-up and combat
        XCTAssertEqual(e.player.level, 2)
        e.leaveShop()
        XCTAssertEqual(e.phase, .combat)
        XCTAssertEqual(e.enemyIndex, 1)       // first enemy of the new layer
    }

    func testBuyPermanentUpgradeChargesAndScales() {
        let e = engine()
        for _ in 1...5 { e.enemy.hp = 1; e.perform(.attack) }
        e.chooseUpgrade(.attack)              // now in .shop
        e.player.addGold(1000)
        let atkBefore = e.player.attack
        let first = e.price(.whetstone)
        e.buy(.whetstone)
        XCTAssertEqual(e.player.attack, atkBefore + 5)
        // Geometric pricing: next copy costs 1.7× the first.
        XCTAssertEqual(e.price(.whetstone), Int((Double(first) * 1.7).rounded()))
    }

    func testBuyBlockedWhenBroke() {
        let e = engine()
        for _ in 1...5 { e.enemy.hp = 1; e.perform(.attack) }
        e.chooseUpgrade(.attack)
        // Drain gold below any price.
        e.player.spendGold(e.player.gold)
        let goldBefore = e.player.gold
        let maxHpBefore = e.player.maxHp
        e.buy(.heartVial)
        XCTAssertEqual(e.player.gold, goldBefore)   // nothing spent
        XCTAssertEqual(e.player.maxHp, maxHpBefore) // unchanged
    }

    func testPotionPurchaseAndUse() {
        let e = engine()
        for _ in 1...5 { e.enemy.hp = 1; e.perform(.attack) }
        e.chooseUpgrade(.attack)
        e.player.addGold(1000)
        e.buy(.potion)
        XCTAssertEqual(e.player.potions, 1)
        e.leaveShop()
        e.player.hp = 1
        e.usePotion()
        XCTAssertEqual(e.player.potions, 0)
        XCTAssertGreaterThan(e.player.hp, 1)
    }

    func testPlayerDeathEndsRun() {
        let e = engine()
        e.player.hp = 1                  // next enemy swing is lethal
        e.perform(.attack)               // enemy survives (full HP), then retaliates
        XCTAssertEqual(e.phase, .defeat)
        XCTAssertFalse(e.player.isAlive)
    }

    func testAutoBattleTickFightsAutomatically() {
        let e = engine()
        e.enemy.hp = 1
        e.autoBattle = true
        e.tick()                          // auto-plays a move that kills the enemy
        XCTAssertEqual(e.enemyIndex, 2)   // advanced without manual input
    }

    func testTickIsNoopWhenAutoOff() {
        let e = engine()
        e.enemy.hp = 1
        let idx = e.enemyIndex
        e.tick()                          // auto-battle off → nothing happens
        XCTAssertEqual(e.enemyIndex, idx)
    }

    func testSaveAndRestoreRoundTrip() {
        SaveStore.clear()
        defer { SaveStore.clear() }
        let a = engine()
        a.enemy.hp = 1
        a.perform(.attack)              // gold gained, advanced to enemy 2
        let gold = a.player.gold
        let idx = a.enemyIndex
        a.save()

        // A fresh engine loads the save in its init.
        let b = GameEngine(playerName: "Ignored", rng: ScriptedRandom(fallback: 9))
        XCTAssertEqual(b.player.gold, gold)
        XCTAssertEqual(b.enemyIndex, idx)
        XCTAssertEqual(b.player.name, "Hero")
        XCTAssertEqual(b.phase, .combat)
    }

    func testAscendBanksShardsAndBoostsStartingPower() {
        SaveStore.clear()
        PrestigeStore.save(0)
        defer { SaveStore.clear(); PrestigeStore.save(0) }

        let e = engine()
        let baseAttack = e.player.attack
        // Drive many kills, auto-resolving the level-up/shop interruptions, so
        // enough gold accrues for shards: floor(sqrt(gold/100)).
        for _ in 0..<40 {
            switch e.phase {
            case .combat:  e.enemy.hp = 1; e.perform(.attack)
            case .levelUp: e.chooseUpgrade(.attack)
            case .shop:    e.leaveShop()
            default:       break
            }
        }
        if e.phase == .levelUp { e.chooseUpgrade(.attack) }
        if e.phase == .shop { e.leaveShop() }
        let expectedShards = e.pendingShards

        e.enterAscension()
        XCTAssertEqual(e.phase, .ascension)
        e.ascend()

        XCTAssertEqual(e.totalShards, expectedShards)
        XCTAssertEqual(e.phase, .combat)        // fresh run begins
        XCTAssertEqual(e.layer, 1)
        if expectedShards > 0 {
            XCTAssertGreaterThan(e.player.attack, baseAttack) // multiplier baked in
        }
    }

    func testAutomationClearsLevelUpWhenUnlocked() {
        SaveStore.clear()
        PrestigeStore.save(5)            // automation unlocked (>= 1 shard)
        defer { SaveStore.clear(); PrestigeStore.save(0) }

        let e = GameEngine(playerName: "Hero", rng: ScriptedRandom(fallback: 9))
        e.startGame(named: "Hero")
        e.autoBattle = true
        for _ in 1...5 { e.enemy.hp = 1; e.perform(.attack) }  // 5th kill → levelUp
        XCTAssertEqual(e.phase, .levelUp)
        e.tick()                          // automation auto-picks the upgrade
        XCTAssertEqual(e.player.level, 2)
        XCTAssertNotEqual(e.phase, .levelUp)
    }

    func testAutomationLockedBeforeFirstPrestige() {
        SaveStore.clear()
        PrestigeStore.save(0)
        let e = engine()                  // 0 shards
        XCTAssertFalse(e.automationUnlocked)
        for _ in 1...5 { e.enemy.hp = 1; e.perform(.attack) }
        XCTAssertEqual(e.phase, .levelUp)
        e.autoBattle = true
        e.tick()                          // must NOT auto-advance
        XCTAssertEqual(e.phase, .levelUp)
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
