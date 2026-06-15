import Foundation
import SwiftUI

/// The five combat actions. The first three (Attack / Dodge / Heal) are the
/// original Java moves; Heavy Strike and Magic Bolt are new to the iOS clone.
enum Move: String, CaseIterable, Identifiable {
    case attack      = "Attack"
    case heavy       = "Heavy Strike"
    case magic       = "Magic Bolt"
    case poison      = "Poison Dagger"
    case dodge       = "Dodge"
    case heal        = "Heal"

    var id: String { rawValue }

    var sfSymbol: String {
        // SF Symbols that are guaranteed to exist across iOS versions.
        switch self {
        case .attack: return "burst.fill"
        case .heavy:  return "hammer.fill"
        case .magic:  return "sparkles"
        case .poison: return "drop.triangle.fill"
        case .dodge:  return "figure.run"
        case .heal:   return "cross.case.fill"
        }
    }

    var manaCost: Int {
        switch self {
        case .magic:  return 8
        case .heavy:  return 5
        case .poison: return 4
        default:      return 0
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

/// A transient number/word that floats up over a combatant (e.g. "−42", "CRIT!",
/// "Miss", "+30"). The view layer watches `GameEngine.popup` and animates it.
struct CombatPopup: Identifiable, Equatable {
    enum Flavor { case damage, crit, heal, miss }
    let id = UUID()
    let text: String
    let flavor: Flavor
    let onPlayer: Bool   // shown over the player panel vs. the enemy sprite
}

/// Best run achieved so far, persisted across launches via `UserDefaults`.
struct BestRun: Equatable {
    var layer: Int
    var level: Int
    var gold: Int

    static let empty = BestRun(layer: 1, level: 1, gold: 0)
    var hasRecord: Bool { layer > 1 || level > 1 || gold > 0 }

    private enum Key {
        static let layer = "best.layer"
        static let level = "best.level"
        static let gold = "best.gold"
    }

    static func load() -> BestRun {
        let d = UserDefaults.standard
        return BestRun(layer: max(1, d.integer(forKey: Key.layer)),
                       level: max(1, d.integer(forKey: Key.level)),
                       gold: d.integer(forKey: Key.gold))
    }

    func save() {
        let d = UserDefaults.standard
        d.set(layer, forKey: Key.layer)
        d.set(level, forKey: Key.level)
        d.set(gold, forKey: Key.gold)
    }
}

/// High-level phases that drive which screen is shown.
enum Phase: Equatable {
    case title
    case combat
    case levelUp
    case shop        // spend gold between layers
    case ascension   // prestige / "Descend into the Abyss"
    case defeat
    case victory     // reached after felling the Imperial Red Dragon
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
    @Published var shakeTrigger = 0
    @Published var spawnCounter = 0      // bumps whenever a new enemy appears
    @Published var popup: CombatPopup?   // latest floating combat number/word

    /// Best run so far, and whether the last finished run set a new record.
    @Published private(set) var best: BestRun
    @Published private(set) var setNewRecord = false

    /// Set when offline auto-battle earned gold; the view shows a summary sheet.
    @Published var offlineReport: OfflineReport?

    /// When the app was last backgrounded (for warm-resume offline accrual).
    private var backgroundedAt: Date?

    /// Prestige: Soul Shards persist across runs; each grants +2% to starting
    /// power and gold income. `runGoldEarned` feeds the shard payout on descent.
    @Published private(set) var totalShards: Int
    @Published private(set) var runGoldEarned = 0

    /// +2% per shard, applied to starting stats and gold gain.
    var prestigeMultiplier: Double { 1 + 0.02 * Double(totalShards) }

    /// Shards awarded for descending now: `floor(sqrt(runGoldEarned / 100))`.
    var pendingShards: Int { Int((Double(runGoldEarned) / 100).squareRoot()) }

    /// How many of each permanent upgrade have been bought (drives price scaling).
    @Published private(set) var purchaseCounts: [ShopItem: Int] = [:]

    /// Hybrid idle: when on, a periodic `tick()` auto-plays combat. The player
    /// still steps in for level-up / shop / ascension choices (tick pauses
    /// outside `.combat`).
    @Published var autoBattle = false

    private var scaleLevel = 0                       // cumulative enemy strengthening
    private var victoryShown = false                 // celebrate the dragon only once

    /// Injectable randomness — `SystemRandom` in the app, `SeededRandom`/stub in tests.
    private let rng: RandomSource

    init(playerName: String = "Diver", rng: RandomSource = SystemRandom()) {
        self.rng = rng
        let p = Player(name: playerName)
        self.player = p
        self.enemy = Enemy(kind: Bestiary.fodder[0], scaleLevel: 0,
                           isBoss: false, isFinalBoss: false, postGameDepth: 0)
        self.best = BestRun.load()
        self.totalShards = PrestigeStore.load()
        loadIfAvailable()
    }

    // MARK: - Lifecycle

    func startGame(named name: String) {
        SaveStore.clear()
        player = Player(name: name)
        player.applyStartingMultiplier(prestigeMultiplier)
        runGoldEarned = 0
        layer = 1
        enemyIndex = 0
        scaleLevel = 0
        clearedFinalBoss = false
        victoryShown = false
        setNewRecord = false
        autoBattle = false
        offlineReport = nil
        popup = nil
        purchaseCounts = [:]
        log = []
        append("Welcome to Dungeon Divers, \(player.name)!", .system)
        append("Clear 5 enemies per layer. Every 5th is a boss.", .info)
        append("Reach Layer 5 and slay the Imperial Red Dragon to win.", .info)
        spawnNextEnemy()
        phase = .combat
    }

    // MARK: - Spawning (ports the num/layer bookkeeping from GameDriver)

    private func spawnNextEnemy(advance: Bool = true) {
        if advance {
            enemyIndex += 1
            if enemyIndex > 5 {
                enemyIndex = 1
                // A new group of fodder: the bestiary permanently strengthens.
                scaleLevel += 1
            }
        }
        // 0 during layers 1–5; drives the endless exponential scaling after.
        let postGameDepth = max(0, layer - 5)

        let isBoss = enemyIndex == 5
        let isFinalBoss = isBoss && layer == 5

        let kind: EnemyKind
        if isFinalBoss {
            kind = Bestiary.finalBoss
        } else if isBoss {
            kind = rng.element(Bestiary.bosses)!
        } else {
            kind = rng.element(Bestiary.fodder)!
        }

        enemy = Enemy(kind: kind, scaleLevel: scaleLevel,
                      isBoss: isBoss, isFinalBoss: isFinalBoss, postGameDepth: postGameDepth)
        spawnCounter += 1

        append("— Layer \(layer): Enemy \(enemyIndex) of 5 —", .system)
        append("A \(enemy.name) appears! \(enemy.sprite)", isBoss ? .danger : .info)
        if isBoss { SoundManager.shared.play(.bossAppear) }
    }

    // MARK: - Idle tick

    func toggleAuto() { autoBattle.toggle() }

    /// Automation (auto-resolve level-up & shop so idle doesn't stall) unlocks
    /// after the first prestige — early runs stay hands-on.
    var automationUnlocked: Bool { totalShards >= 1 }

    /// Driven by the view's timeline (~1 Hz). With auto-battle on: plays a combat
    /// action, and — once automation is unlocked — also clears the between-layer
    /// level-up/shop so the run keeps diving unattended.
    func tick() {
        guard autoBattle else { return }
        switch phase {
        case .combat:
            perform(autoMove())
        case .levelUp where automationUnlocked:
            chooseUpgrade(autoUpgrade())
        case .shop where automationUnlocked:
            autoShop()
        default:
            break
        }
    }

    /// Round-robin stat picks keep the build balanced under automation.
    private func autoUpgrade() -> Player.Upgrade {
        switch player.level % 3 {
        case 0:  return .health
        case 1:  return .attack
        default: return .defense
        }
    }

    /// Buy each affordable permanent upgrade once, then dive on.
    private func autoShop() {
        for item in [ShopItem.whetstone, .towerShield, .heartVial, .luckyCoin]
        where canAfford(item) {
            buy(item)
        }
        leaveShop()
    }

    /// Simple auto-battle heuristic: heal when hurt, otherwise spend mana on the
    /// strongest move available, else a basic attack.
    private func autoMove() -> Move {
        if player.hp * 100 / max(1, player.maxHp) < 35 && player.hp < player.maxHp {
            return .heal
        }
        if player.mana >= Move.magic.manaCost { return .magic }
        if player.mana >= Move.poison.manaCost { return .poison }
        if player.mana >= Move.heavy.manaCost { return .heavy }
        return .attack
    }

    // MARK: - Player actions

    func perform(_ move: Move) {
        guard phase == .combat else { return }

        // A stunned hero loses the turn; the enemy still gets to act.
        if player.consumeStunIfNeeded() {
            append("You are stunned and skip your turn! 💫", .danger)
            enemyRetaliates(bonusChance: 0)
            endRound()
            return
        }

        guard player.mana >= move.manaCost else {
            append("Not enough mana for \(move.rawValue)!", .miss)
            return
        }
        player.spendMana(move.manaCost)

        switch move {
        case .attack: resolveAttack(multiplier: 1.0, label: "strike", stunChance: 0)
        case .heavy:  resolveAttack(multiplier: 1.8, label: "heavy blow", stunChance: 20)
        case .magic:  resolveMagic()
        case .poison: resolvePoison()
        case .dodge:  resolveDodge()
        case .heal:   resolveHeal()
        }

        endRound()
    }

    /// End-of-round upkeep: damage-over-time ticks (enemy then player), then
    /// centralized death handling. All death detection stays in `resolveDeaths`.
    private func endRound() {
        applyTick(to: enemy, onPlayer: false)
        applyTick(to: player, onPlayer: true)
        resolveDeaths()
    }

    /// Tick one combatant's statuses and surface any DoT as a popup + log line.
    /// The model's `tickStatuses()` applies the damage and decrements durations;
    /// this wrapper keeps the UI/feedback in the engine so the model stays clean.
    private func applyTick(to combatant: Combatant, onPlayer: Bool) {
        guard combatant.isAlive else { return }
        let burning = combatant.statuses.contains { $0.kind == .burn }
        let dot = combatant.tickStatuses()
        guard dot > 0 else { return }
        showPopup("−\(dot)", .damage, onPlayer: onPlayer)
        if onPlayer { flashPlayer() } else { flashEnemy() }
        let icon = burning ? "🔥" : "☠️"
        let who = onPlayer ? "You take" : "\(combatant.name) takes"
        append("\(icon) \(who) \(dot) from lingering effects.", onPlayer ? .enemyHit : .playerHit)
    }

    /// Standard / heavy attack. Heavy hits harder and can stun, but a lethal
    /// hit skips the enemy's retaliation — matching the original where a lethal
    /// hit `break`s out before the enemy can swing back.
    private func resolveAttack(multiplier: Double, label: String, stunChance: Int) {
        if Dice.checkHit(chance: player.luck, rng: rng) {
            let crit = rollCrit()
            let critMult = crit ? 2.0 : 1.0
            let raw = Int(Double(player.attack) * multiplier * critMult) - enemy.defense
            let dmg = max(1, raw)
            enemy.takeHit(dmg)
            flashEnemy()
            if crit {
                showPopup("CRIT! −\(dmg)", .crit, onPlayer: false)
                append("Critical \(label)! \(enemy.name) takes \(dmg)! 💥", .playerHit)
                Haptics.play(.medium)
                SoundManager.shared.play(.crit)
            } else {
                showPopup("−\(dmg)", .damage, onPlayer: false)
                append("Your \(label) hits \(enemy.name) for \(dmg)! 💥", .playerHit)
                SoundManager.shared.play(.swing)
            }
            if !enemy.isAlive { return }
            if stunChance > 0, rng.chance(stunChance) {
                enemy.applyStatus(.stun, turns: 1, magnitude: 0)
                append("\(enemy.name) is dazed and will lose its next turn! 💫", .reward)
            }
        } else {
            showPopup("Miss", .miss, onPlayer: false)
            append("You missed!", .miss)
        }
        enemyRetaliates(bonusChance: 0)
    }

    /// Magic Bolt: ignores enemy defense, always lands, and may set the enemy
    /// ablaze (burn DoT). Costs mana.
    private func resolveMagic() {
        let dmg = max(1, player.attack + 5)
        enemy.takeHit(dmg)
        flashEnemy()
        showPopup("−\(dmg)", .damage, onPlayer: false)
        append("✨ Your Magic Bolt sears \(enemy.name) for \(dmg)!", .playerHit)
        SoundManager.shared.play(.magic)
        if !enemy.isAlive { return }
        if rng.chance(35) {
            enemy.applyStatus(.burn, turns: 3, magnitude: max(2, player.level))
            append("\(enemy.name) catches fire! 🔥", .reward)
        }
        enemyRetaliates(bonusChance: 0)
    }

    /// Poison Dagger: a light direct hit that stacks poison DoT. Cheap mana.
    private func resolvePoison() {
        if Dice.checkHit(chance: player.luck, rng: rng) {
            let dmg = max(1, player.attack / 2 - enemy.defense)
            enemy.takeHit(dmg)
            flashEnemy()
            showPopup("−\(dmg)", .damage, onPlayer: false)
            enemy.applyStatus(.poison, turns: 3, magnitude: max(1, player.level), maxStacks: 5)
            append("Poison Dagger bites \(enemy.name) for \(dmg) and poisons it! ☠️", .playerHit)
            SoundManager.shared.play(.poison)
            if !enemy.isAlive { return }
        } else {
            showPopup("Miss", .miss, onPlayer: false)
            append("Your Poison Dagger misses!", .miss)
        }
        enemyRetaliates(bonusChance: 0)
    }

    /// Dodge, ported from case 'D': harder for the enemy to connect; on a clean
    /// dodge you recover a little HP and some mana.
    private func resolveDodge() {
        append("You brace and watch for the opening…", .info)
        if Dice.checkHit(chance: enemy.luck + 3, rng: rng) {
            let dmg = max(0, enemy.attack - player.defense)
            player.takeHit(dmg)
            flashPlayer()
            showPopup("−\(dmg)", .damage, onPlayer: true)
            append("\(enemy.name) still landed \(dmg)!", .enemyHit)
        } else {
            let healed = 5 * player.level
            player.restoreHp(healed)
            player.restoreMana(4)
            showPopup("Dodge +\(healed)", .heal, onPlayer: true)
            append("Dodged! You recover \(healed) HP and focus. 🌀", .reward)
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
        showPopup("+\(amount)", .heal, onPlayer: true)
        append("You quaff a potion and restore \(amount) HP. ❤️", .reward)
        enemyRetaliates(bonusChance: 1)
    }

    /// Enemy's swing back, ported from the shared `e1.checkHit` blocks.
    /// A stunned enemy forfeits the swing. Bosses may inflict poison on a hit.
    private func enemyRetaliates(bonusChance: Int) {
        guard enemy.isAlive else { return }
        if enemy.consumeStunIfNeeded() {
            append("\(enemy.name) is stunned and can't strike! 💫", .reward)
            return
        }
        if Dice.checkHit(chance: enemy.luck + bonusChance, rng: rng) {
            // Guard buff softens incoming hits while active.
            let guardBonus = player.statuses.contains { $0.kind == .guardUp } ? 5 : 0
            let dmg = max(0, enemy.attack - player.defense - guardBonus)
            player.takeHit(dmg)
            flashPlayer()
            showPopup("−\(dmg)", .damage, onPlayer: true)
            append("\(enemy.name) hits you for \(dmg)!", .enemyHit)
            if enemy.isBoss, player.isAlive, rng.chance(25) {
                player.applyStatus(.poison, turns: 2, magnitude: max(1, enemy.level), maxStacks: 3)
                append("\(enemy.name)'s strike leaves you poisoned! ☠️", .danger)
            }
        } else {
            showPopup("Miss", .miss, onPlayer: true)
            append("\(enemy.name) missed!", .miss)
        }
    }

    /// Crit chance leans on luck: in this game a *lower* luck value lands hits
    /// more often, so it also crits more. Player luck 3 → ~21%. A `focus` buff
    /// adds a flat bonus while active.
    private func rollCrit() -> Bool {
        let focusBonus = player.statuses.contains { $0.kind == .focus } ? 25 : 0
        return rng.chance(max(5, (10 - player.luck) * 3) + focusBonus)
    }

    // MARK: - Death handling

    private func resolveDeaths() {
        // Player death takes precedence — if a lethal end-of-round DoT drops both
        // the hero and the enemy in the same tick, it's still a defeat (rather
        // than silently advancing at 0 HP).
        if !player.isAlive {
            append("You died on Layer \(layer)… 💀", .danger)
            append("Final gold: \(player.gold). Reached level \(player.level).", .info)
            Haptics.play(.error)
            SoundManager.shared.play(.playerDie)
            recordRun()
            SaveStore.clear()        // run over — next launch starts fresh
            phase = .defeat
            return
        }

        if !enemy.isAlive {
            let gold = Int((Double(enemy.generateGold()) * prestigeMultiplier).rounded())
            player.addGold(gold)
            runGoldEarned += gold
            append("You gained \(Formatting.short(gold)) gold! 🪙", .reward)
            append("The \(enemy.name) was slain!", .reward)
            Haptics.play(.success)
            SoundManager.shared.play(.enemyDie)

            recordRun()
            if enemyIndex == 5 {
                handleBossDefeated()
            } else {
                spawnNextEnemy()
            }
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
            append("★ Dungeon Divers complete! ★ Endless mode unlocked — "
                   + "enemies now scale relentlessly. How deep can you go?", .system)
            SoundManager.shared.play(.victory)
        }

        append("You leveled up! Choose an upgrade.", .system)
        SoundManager.shared.play(.levelUp)
        phase = .levelUp
    }

    /// Called by the level-up screen; then opens the shop before the next layer.
    func chooseUpgrade(_ upgrade: Player.Upgrade) {
        player.levelUp(upgrade)
        append("Upgraded \(upgrade.label)! Now level \(player.level).", .reward)
        phase = .shop
    }

    /// Spawn the next enemy and resume combat — or show the victory screen once.
    private func enterNextEncounter() {
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

    // MARK: - Prestige / ascension

    /// Open the ascension screen (from combat). Auto-battle pauses there.
    func enterAscension() {
        guard phase == .combat else { return }
        phase = .ascension
    }

    /// Back out of the ascension screen without descending.
    func cancelAscension() {
        guard phase == .ascension else { return }
        phase = .combat
    }

    /// Descend: bank `pendingShards`, then restart the run with the new, higher
    /// prestige multiplier baked into starting stats.
    func ascend() {
        guard phase == .ascension else { return }
        let gained = pendingShards
        totalShards += gained
        PrestigeStore.save(totalShards)
        startGame(named: player.name)
        append("You descended into the Abyss and absorbed \(gained) Soul Shards. 🔮", .system)
        append("Permanent power is now ×\(String(format: "%.2f", prestigeMultiplier)).", .system)
    }

    // MARK: - Shop

    /// Current price for an item. Consumables are flat; permanent upgrades
    /// inflate *geometrically* per copy owned (1.7× each) so gold — which grows
    /// quadratically with depth — can't fully out-buy the endless scaling.
    func price(_ item: ShopItem) -> Int {
        guard item.isPermanent else { return item.basePrice }
        let owned = purchaseCounts[item, default: 0]
        return Int((Double(item.basePrice) * pow(1.7, Double(owned))).rounded())
    }

    func canAfford(_ item: ShopItem) -> Bool { player.gold >= price(item) }

    /// Attempt to buy an item; applies its effect and logs the result.
    func buy(_ item: ShopItem) {
        guard phase == .shop else { return }
        let cost = price(item)
        guard player.spendGold(cost) else {
            append("Not enough gold for \(item.name).", .miss)
            Haptics.play(.warning)
            SoundManager.shared.play(.denied)
            return
        }

        switch item {
        case .potion:      player.addPotions(1)
        case .ether:       player.addEthers(1)
        case .whetstone:   player.upgradeAttack()
        case .towerShield: player.upgradeDefense()
        case .heartVial:   player.upgradeMaxHp()
        case .luckyCoin:   player.improveLuck()
        }
        if item.isPermanent {
            purchaseCounts[item, default: 0] += 1
        }
        append("Bought \(item.name) for \(cost)g. \(item.icon)", .reward)
        Haptics.play(.success)
        SoundManager.shared.play(.purchase)
    }

    /// Leave the shop and dive into the next layer.
    func leaveShop() {
        enterNextEncounter()
    }

    // MARK: - Consumables (used during combat)

    func usePotion() {
        guard phase == .combat, player.isAlive, player.potions > 0 else { return }
        let before = player.hp
        player.usePotion()
        let healed = player.hp - before
        showPopup("+\(healed)", .heal, onPlayer: true)
        append("You quaff a potion (+\(healed) HP). 🧪", .reward)
        enemyRetaliates(bonusChance: 1)
        endRound()
    }

    func useEther() {
        guard phase == .combat, player.isAlive, player.ethers > 0 else { return }
        player.useEther()
        showPopup("Mana", .heal, onPlayer: true)
        append("You drink an ether and restore mana. 🔮", .reward)
        enemyRetaliates(bonusChance: 1)
        endRound()
    }

    // MARK: - Persistence & offline progress

    /// App moved to the background: stamp the time and persist.
    func backgrounded() {
        backgroundedAt = Date()
        save()
    }

    /// App returned to the foreground: accrue offline gold since backgrounding.
    func foregrounded() {
        if let t = backgroundedAt {
            grantOffline(since: t)
            backgroundedAt = nil
        }
    }

    /// Persist the run, but only while it's live and resumable.
    func save() {
        switch phase {
        case .combat, .levelUp, .shop:
            SaveStore.write(snapshot())
        default:
            break
        }
    }

    private func snapshot() -> GameSave {
        var counts: [String: Int] = [:]
        for (item, n) in purchaseCounts { counts[item.rawValue] = n }
        let phaseStr: String
        switch phase {
        case .levelUp: phaseStr = "levelUp"
        case .shop:    phaseStr = "shop"
        default:       phaseStr = "combat"
        }
        return GameSave(
            name: player.name, hp: player.hp, maxHp: player.maxHp,
            attack: player.attack, maxAttack: player.maxAttack,
            defense: player.defense, maxDefense: player.maxDefense,
            luck: player.luck, level: player.level, gold: player.gold,
            mana: player.mana, maxMana: player.maxMana,
            potions: player.potions, ethers: player.ethers,
            layer: layer, enemyIndex: enemyIndex, scaleLevel: scaleLevel,
            clearedFinalBoss: clearedFinalBoss, victoryShown: victoryShown,
            purchaseCounts: counts, phase: phaseStr, autoBattle: autoBattle,
            runGoldEarned: runGoldEarned, lastSeen: Date())
    }

    private func loadIfAvailable() {
        guard let save = SaveStore.read() else { return }
        restore(from: save)
    }

    private func restore(from save: GameSave) {
        player = Player(restoring: save)
        layer = save.layer
        enemyIndex = save.enemyIndex
        scaleLevel = save.scaleLevel
        clearedFinalBoss = save.clearedFinalBoss
        victoryShown = save.victoryShown
        autoBattle = save.autoBattle
        runGoldEarned = save.runGoldEarned

        var counts: [ShopItem: Int] = [:]
        for (raw, n) in save.purchaseCounts {
            if let item = ShopItem(rawValue: raw) { counts[item] = n }
        }
        purchaseCounts = counts

        log = []
        append("Welcome back, \(player.name)!", .system)
        spawnNextEnemy(advance: false)   // rebuild a fresh enemy at the saved spot

        switch save.phase {
        case "levelUp": phase = .levelUp
        case "shop":    phase = .shop
        default:        phase = .combat
        }

        grantOffline(since: save.lastSeen)
    }

    /// Grant capped, reduced-rate gold for time spent away — only if the run was
    /// idling (auto-battle on). Estimates income from current DPS vs. the foe.
    private func grantOffline(since lastSeen: Date) {
        guard autoBattle, phase == .combat else { return }
        let elapsed = Date().timeIntervalSince(lastSeen)
        guard elapsed > 60 else { return }            // ignore brief gaps

        let cap: TimeInterval = 8 * 3600              // 8h cap
        let effective = min(elapsed, cap)
        let dps = Double(max(1, player.attack))
        let killsPerSec = dps / Double(max(1, enemy.maxHp))
        let goldPerSec = killsPerSec * Double(max(1, enemy.generateGold()))
        let gold = Int(goldPerSec * effective * 0.5 * prestigeMultiplier)  // 50% efficiency
        guard gold > 0 else { return }

        player.addGold(gold)
        runGoldEarned += gold
        recordRun()
        offlineReport = OfflineReport(gold: gold, duration: elapsed)
        append("While away, auto-battle earned \(Formatting.short(gold)) gold. 🪙", .reward)
    }

    // MARK: - Records

    /// Roll the current progress into the persisted best run, flagging when this
    /// run set a new record (shown on the game-over screen).
    private func recordRun() {
        var updated = best
        var improved = false
        if layer > updated.layer { updated.layer = layer; improved = true }
        if player.level > updated.level { updated.level = player.level; improved = true }
        if player.gold > updated.gold { updated.gold = player.gold; improved = true }
        if improved {
            best = updated
            best.save()
            setNewRecord = true
        }
    }

    // MARK: - Log + animation helpers

    /// Publish a floating combat number/word. The view animates and then calls
    /// `clearPopup(_:)` to remove it (only if it's still the same one).
    private func showPopup(_ text: String, _ flavor: CombatPopup.Flavor, onPlayer: Bool) {
        popup = CombatPopup(text: text, flavor: flavor, onPlayer: onPlayer)
    }

    func clearPopup(_ id: UUID) {
        if popup?.id == id { popup = nil }
    }

    private func append(_ text: String, _ kind: LogLine.Kind) {
        log.append(LogLine(text: text, kind: kind))
        if log.count > 80 { log.removeFirst(log.count - 80) }
    }

    private func flashEnemy() {
        enemyFlash = true
        shakeTrigger += 1
        Haptics.play(.light)
    }

    private func flashPlayer() {
        playerFlash = true
        shakeTrigger += 1
        Haptics.play(.heavy)
        SoundManager.shared.play(.playerHurt)
    }
}
