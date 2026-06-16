import XCTest
@testable import DungeonDivers

/// Pacing / balance regression guards. These drive the *real* `GameEngine`
/// deterministically (seeded RNG, auto-battle) and assert the properties the
/// offline sim uncovered — so a future balance tweak can't silently break the
/// feel. (Enemy *stats* depend only on layer/index/scale, not on which random
/// kind is drawn, so difficulty is reproducible across runs.)
@MainActor
final class BalanceTests: XCTestCase {

    /// Auto-play a full run to death and report how deep it got.
    /// `tree` sets prestige skill levels directly (effects apply regardless of
    /// shards spent). Returns the deepest layer and whether it ended in defeat.
    private func runToDeath(seed: UInt64, tree: [String: Int],
                            maxTicks: Int = 100_000) -> (depth: Int, ended: Bool) {
        SaveStore.clear()
        PrestigeStore.save(1)              // >=1 so automation (auto level-up/shop) is on
        PrestigeStore.saveTree(tree)
        defer { SaveStore.clear(); PrestigeStore.save(0); PrestigeStore.saveTree([:]) }

        let e = GameEngine(playerName: "Bench", rng: SeededRandom(seed: seed))
        e.startGame(named: "Bench")
        e.autoBattle = true

        var deepest = e.layer
        var ticks = 0
        while e.phase != .defeat && ticks < maxTicks {
            switch e.phase {
            case .combat:    e.tick()
            case .levelUp:   e.chooseUpgrade(.attack)   // backstop; automation usually handles it
            case .shop:      e.leaveShop()
            case .victory:   e.continueEndless()
            default:         break
            }
            deepest = max(deepest, e.layer)
            ticks += 1
        }
        return (deepest, e.phase == .defeat)
    }

    func testEveryRunEventuallyEnds() {
        let r = runToDeath(seed: 7, tree: [:])
        XCTAssertTrue(r.ended, "a run must terminate in defeat, not stall forever")
        XCTAssertGreaterThanOrEqual(r.depth, 2, "should make some progress")
    }

    func testStrongPrestigeClearsTheCampaign() {
        // Heavily invested tree should comfortably beat the dragon (layer 5) and
        // push into endless.
        let r = runToDeath(seed: 7, tree: ["might": 12, "vitality": 12, "ward": 12])
        XCTAssertGreaterThanOrEqual(r.depth, 6, "strong prestige should clear the campaign")
    }

    func testWardExtendsTheEndlessLadder() {
        // Summed across seeds to wash out RNG divergence: damage reduction should
        // let a run climb deeper overall. This guards the core idle ladder.
        let seeds: [UInt64] = [1, 2, 3, 4, 5]
        let warded = seeds.reduce(0) { $0 + runToDeath(seed: $1, tree: ["ward": 12]).depth }
        let plain  = seeds.reduce(0) { $0 + runToDeath(seed: $1, tree: [:]).depth }
        XCTAssertGreaterThan(warded, plain, "Ward (damage reduction) should deepen runs")
    }
}
