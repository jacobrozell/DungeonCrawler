import Foundation
import SwiftUI

/// The five combat actions. The first three (Attack / Dodge / Heal) are the
/// original Java moves; Heavy Strike and Magic Bolt are new to the iOS clone.
enum Move: String, CaseIterable, Identifiable {
    case attack      = "Attack"
    case heavy       = "Heavy Strike"
    case magic       = "Magic Bolt"
    case dodge       = "Dodge"
    case heal        = "Heal"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .attack: return "sword.fill"      // falls back gracefully if missing
        case .heavy:  return "hammer.fill"
        case .magic:  return "sparkles"
        case .dodge:  return "figure.run"
        case .heal:   return "cross.vial.fill"
        }
    }

    var sfSymbol: String {
        // SF Symbols that are guaranteed to exist across iOS versions.
        switch self {
        case .attack: return "burst.fill"
        case .heavy:  return "hammer.fill"
        case .magic:  return "sparkles"
        case .dodge:  return "figure.run"
        case .heal:   return "cross.case.fill"
        }
    }

    var manaCost: Int {
        switch self {
        case .magic: return 8
        case .heavy: return 5
        default:     return 0
        }
    }
}

/// A single line in the scrolling combat log, with a flavour for colouring.
struct LogLine: Identifiable {
    enum Kind { case info, playerHit, enemyHit, miss, reward, system, danger }
    let id = UUID()
    let text: String
    let kind: Kind
}

/// High-level phases that drive which screen is shown.
enum Phase: Equatable {
    case title
    case combat
    case levelUp
    case defeat
    case victory   // reached after felling the Imperial Red Dragon
}

/// Observable port of `GameDriver`'s main loop.
@MainActor
final class GameEngine: ObservableObject {
    @Published private(set) var player: Player
    @Published private(set) var enemy: Enemy
    @Published private(set) var phase: Phase = .title
    @Published private(set) var log: [LogLine] = []

    @Published private(set) var layer = 1
    @Published private(set) var enemyIndex = 0      // 1...5 within a layer ("num")
    @Published private(set) var clearedFinalBoss = false

    /// Lightweight animation hooks for the view layer.
    @Published var playerFlash = false
    @Published var enemyFlash = false
    @Published var screenShake = false

    private var scaleLevel = 0                       // cumulative enemy strengthening
    private var victoryShown = false                 // celebrate the dragon only once

    init(playerName: String = "Diver") {
        let p = Player(name: playerName)
        self.player = p
        self.enemy = Enemy(kind: Bestiary.fodder[0], scaleLevel: 0,
                           isBoss: false, isFinalBoss: false, postGame: false)
    }

    // MARK: - Lifecycle

    func startGame(named name: String) {
        player = Player(name: name)
        layer = 1
        enemyIndex = 0
        scaleLevel = 0
        clearedFinalBoss = false
        victoryShown = false
        log = []
        append("Welcome to Dungeon Divers, \(player.name)!", .system)
        append("Clear 5 enemies per layer. Every 5th is a boss.", .info)
        append("Reach Layer 5 and slay the Imperial Red Dragon to win.", .info)
        spawnNextEnemy()
        phase = .combat
    }

    // MARK: - Spawning (ports the num/layer bookkeeping from GameDriver)

    private func spawnNextEnemy() {
        enemyIndex += 1
        let postGame = layer > 5

        if enemyIndex > 5 {
            enemyIndex = 1
            // A new group of fodder: the bestiary permanently strengthens.
            scaleLevel += 1
        }

        let isBoss = enemyIndex == 5
        let isFinalBoss = isBoss && layer == 5

        let kind: EnemyKind
        if isFinalBoss {
            kind = Bestiary.finalBoss
        } else if isBoss {
            kind = Bestiary.bosses.randomElement()!
        } else {
            kind = Bestiary.fodder.randomElement()!
        }

        enemy = Enemy(kind: kind, scaleLevel: scaleLevel,
                      isBoss: isBoss, isFinalBoss: isFinalBoss, postGame: postGame)

        append("— Layer \(layer): Enemy \(enemyIndex) of 5 —", .system)
        append("A \(enemy.name) appears! \(enemy.sprite)", isBoss ? .danger : .info)
    }

    // MARK: - Player actions

    func perform(_ move: Move) {
        guard phase == .combat else { return }
        guard player.mana >= move.manaCost else {
            append("Not enough mana for \(move.rawValue)!", .miss)
            return
        }
        player.spendMana(move.manaCost)

        switch move {
        case .attack: resolveAttack(multiplier: 1.0, label: "strike")
        case .heavy:  resolveAttack(multiplier: 1.8, label: "heavy blow")
        case .magic:  resolveMagic()
        case .dodge:  resolveDodge()
        case .heal:   resolveHeal()
        }

        resolveDeaths()
    }

    /// Standard / heavy attack. Heavy hits harder but never retaliates if the
    /// enemy dies first — matching the original where a lethal hit `break`s out
    /// before the enemy can swing back.
    private func resolveAttack(multiplier: Double, label: String) {
        if Dice.checkHit(chance: player.luck) {
            let raw = Int(Double(player.attack) * multiplier) - enemy.defense
            let dmg = max(1, raw)
            enemy.takeHit(dmg)
            flashEnemy()
            append("Your \(label) hits \(enemy.name) for \(dmg)! 💥", .playerHit)
            if !enemy.isAlive { return }
        } else {
            append("You missed!", .miss)
        }
        enemyRetaliates(bonusChance: 0)
    }

    /// Magic Bolt: ignores enemy defense and always lands, but costs mana.
    private func resolveMagic() {
        let dmg = max(1, player.attack + 5)
        enemy.takeHit(dmg)
        flashEnemy()
        append("✨ Your Magic Bolt sears \(enemy.name) for \(dmg)!", .playerHit)
        if !enemy.isAlive { return }
        enemyRetaliates(bonusChance: 0)
    }

    /// Dodge, ported from case 'D': harder for the enemy to connect; on a clean
    /// dodge you recover a little HP and some mana.
    private func resolveDodge() {
        append("You brace and watch for the opening…", .info)
        if Dice.checkHit(chance: enemy.luck + 3) {
            let dmg = max(0, enemy.attack - player.defense)
            player.takeHit(dmg)
            flashPlayer()
            append("\(enemy.name) still landed \(dmg)!", .enemyHit)
        } else {
            player.restoreHp(5 * player.level)
            player.restoreMana(4)
            append("Dodged! You recover \(5 * player.level) HP and focus. 🌀", .reward)
        }
    }

    /// Heal, ported from case 'H': restore 10×level HP, then the enemy gets a
    /// slightly-better-than-normal swing. No-op (and no retaliation) at full HP.
    private func resolveHeal() {
        if player.hp >= player.maxHp {
            append("You are already at full health!", .info)
            return
        }
        let amount = 10 * player.level
        player.restoreHp(amount)
        append("You quaff a potion and restore \(amount) HP. ❤️", .reward)
        enemyRetaliates(bonusChance: 1)
    }

    /// Enemy's swing back, ported from the shared `e1.checkHit` blocks.
    private func enemyRetaliates(bonusChance: Int) {
        guard enemy.isAlive else { return }
        if Dice.checkHit(chance: enemy.luck + bonusChance) {
            let dmg = max(0, enemy.attack - player.defense)
            player.takeHit(dmg)
            flashPlayer()
            append("\(enemy.name) hits you for \(dmg)!", .enemyHit)
        } else {
            append("\(enemy.name) missed!", .miss)
        }
    }

    // MARK: - Death handling

    private func resolveDeaths() {
        if !enemy.isAlive {
            let gold = enemy.generateGold()
            player.addGold(gold)
            append("You gained \(gold) gold! 🪙", .reward)
            append("The \(enemy.name) was slain!", .reward)

            if enemyIndex == 5 {
                handleBossDefeated()
            } else {
                spawnNextEnemy()
            }
            return
        }

        if !player.isAlive {
            append("You died on Layer \(layer)… 💀", .danger)
            append("Final gold: \(player.gold). Reached level \(player.level).", .info)
            phase = .defeat
        }
    }

    private func handleBossDefeated() {
        let wasFinal = (layer == 5)
        layer += 1

        if layer == 2 {
            append("Enemies get tougher each layer — but so do you.", .system)
        }
        if wasFinal {
            clearedFinalBoss = true
            append("You felled the Imperial Red Dragon! 🐉", .reward)
            append("★ Dungeon Divers complete! ★ Endless mode unlocked.", .system)
        }

        append("You leveled up! Choose an upgrade.", .system)
        phase = .levelUp
    }

    /// Called by the level-up screen; resumes combat (or shows victory once).
    func chooseUpgrade(_ upgrade: Player.Upgrade) {
        player.levelUp(upgrade)
        append("Upgraded \(upgrade.label)! Now level \(player.level).", .reward)

        spawnNextEnemy()
        if clearedFinalBoss && !victoryShown {
            // Show the victory celebration once, then continue endlessly.
            victoryShown = true
            phase = .victory
        } else {
            phase = .combat
        }
    }

    /// From the victory screen: dive on into endless mode.
    func continueEndless() {
        phase = .combat
    }

    // MARK: - Log + animation helpers

    private func append(_ text: String, _ kind: LogLine.Kind) {
        log.append(LogLine(text: text, kind: kind))
        if log.count > 80 { log.removeFirst(log.count - 80) }
    }

    private func flashEnemy() {
        enemyFlash = true
        screenShake = true
    }

    private func flashPlayer() {
        playerFlash = true
        screenShake = true
    }
}
