import SwiftUI

struct CombatView: View {
    @EnvironmentObject var engine: GameEngine
    @Environment(\.verticalSizeClass) private var vSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// On iPhone, landscape reports a compact height — switch to a side-by-side
    /// layout so nothing gets crushed.
    private var isLandscape: Bool { vSizeClass == .compact }

    var body: some View {
        Group {
            if isLandscape {
                HStack(alignment: .top, spacing: 12) {
                    VStack(spacing: 10) {
                        headerBar
                        enemyStage
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity)
                    VStack(spacing: 10) {
                        CombatLogView(lines: engine.log)
                            .frame(maxHeight: .infinity)
                        playerStatus
                        moveButtons
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                VStack(spacing: 12) {
                    headerBar
                    enemyStage
                    CombatLogView(lines: engine.log)
                        .frame(maxHeight: .infinity)
                    playerStatus
                    moveButtons
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .modifier(Shake(amount: reduceMotion ? 0 : 7,
                        animatableData: CGFloat(engine.shakeTrigger)))
        .animation(.linear(duration: 0.3), value: engine.shakeTrigger)
    }

    /// Floating combat number for the given target (player vs. enemy), if any.
    @ViewBuilder private func popupOverlay(onPlayer: Bool) -> some View {
        if let p = engine.popup, p.onPlayer == onPlayer {
            FloatingPopup(popup: p, onClear: { engine.clearPopup($0) })
                .id(p.id)
                .allowsHitTesting(false)
        }
    }

    private var headerBar: some View {
        HStack {
            Label("Layer \(engine.layer)", systemImage: "square.3.layers.3d")
            Spacer()
            Label("\(engine.enemyIndex)/5", systemImage: "person.fill")
            Spacer()
            Label("\(engine.player.gold)", systemImage: "centsign.circle.fill")
                .foregroundStyle(Theme.gold)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.3), value: engine.player.gold)
        }
        .font(.subheadline.bold())
        .foregroundStyle(.primary.opacity(0.85))
    }

    private var enemyStage: some View {
        Panel {
            VStack(spacing: 10) {
                HStack {
                    Text(engine.enemy.name)
                        .font(.headline)
                        .foregroundStyle(Theme.tint(engine.enemy.tint))
                    if engine.enemy.isBoss {
                        Text("BOSS")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Theme.hpRed)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                    Spacer()
                    Text("Lv \(engine.enemy.level)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                enemySprite
                StatBar(value: engine.enemy.hp, maxValue: engine.enemy.maxHp,
                        tint: Theme.hpRed, label: "Enemy HP")
                HStack(spacing: 16) {
                    statChip("burst.fill", engine.enemy.attack)
                    statChip("shield.lefthalf.filled", engine.enemy.defense)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    /// Enemy sprite: gently idles, flashes on hit, and animates in on spawn.
    private var enemySprite: some View {
        Text(engine.enemy.sprite)
            .font(.system(size: isLandscape ? 56 : 72))
            .scaleEffect(engine.enemyFlash ? 1.15 : 1.0)
            .opacity(engine.enemyFlash ? 0.5 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: engine.enemyFlash)
            .modifier(IdleBob())
            .id(engine.spawnCounter)
            .transition(reduceMotion
                        ? .opacity
                        : .asymmetric(insertion: .scale(scale: 0.4).combined(with: .opacity),
                                      removal: .opacity))
            .animation(reduceMotion ? .easeInOut(duration: 0.25)
                                    : .spring(response: 0.45, dampingFraction: 0.6),
                       value: engine.spawnCounter)
            .overlay(alignment: .top) { popupOverlay(onPlayer: false).offset(y: -8) }
            .onChange(of: engine.enemyFlash) { flash in
                if flash {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                        engine.enemyFlash = false
                    }
                }
            }
    }

    private var playerStatus: some View {
        Panel {
            VStack(spacing: 8) {
                HStack {
                    Text(engine.player.name).font(.headline)
                    Spacer()
                    Text("Lv \(engine.player.level)").font(.caption.monospacedDigit())
                }
                StatBar(value: engine.player.hp, maxValue: engine.player.maxHp,
                        tint: Theme.hpGreen, label: "HP")
                StatBar(value: engine.player.mana, maxValue: engine.player.maxMana,
                        tint: Theme.mana, label: "Mana")
                HStack(spacing: 16) {
                    statChip("burst.fill", engine.player.attack)
                    statChip("shield.lefthalf.filled", engine.player.defense)
                    statChip("dice.fill", engine.player.luck)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .overlay(alignment: .top) { popupOverlay(onPlayer: true).offset(y: -6) }
        .scaleEffect(engine.playerFlash ? 0.97 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: engine.playerFlash)
        .onChange(of: engine.playerFlash) { flash in
            if flash {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                    engine.playerFlash = false
                }
            }
        }
    }

    private var moveButtons: some View {
        // The four offensive / evasive moves in a 2×2 grid, with Heal given a
        // prominent full-width button beneath them.
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        let grid = Move.allCases.filter { $0 != .heal }
        return VStack(spacing: 10) {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(grid) { moveButton($0) }
            }
            moveButton(.heal)
        }
        .padding(.bottom, 6)
    }

    private func moveButton(_ move: Move) -> some View {
        let affordable = engine.player.mana >= move.manaCost
        return Button {
            engine.perform(move)
        } label: {
            HStack {
                Image(systemName: move.sfSymbol)
                VStack(alignment: .leading, spacing: 1) {
                    Text(move.rawValue).font(.subheadline.bold())
                    if move.manaCost > 0 {
                        Text("\(move.manaCost) mana").font(.caption2)
                    }
                }
                Spacer()
            }
            .padding(.vertical, 12).padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .background(buttonColor(move))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .opacity(affordable ? 1 : 0.4)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!affordable)
    }

    private func buttonColor(_ move: Move) -> Color {
        switch move {
        case .attack: return Color.red.opacity(0.7)
        case .heavy:  return Color.orange.opacity(0.7)
        case .magic:  return Theme.mana.opacity(0.85)
        case .dodge:  return Color.teal.opacity(0.7)
        case .heal:   return Theme.hpGreen.opacity(0.8)
        }
    }

    private func statChip(_ symbol: String, _ value: Int) -> some View {
        Label("\(value)", systemImage: symbol)
            .contentTransition(.numericText())
            .animation(.easeInOut(duration: 0.3), value: value)
    }
}

/// A slow, looping vertical float to give sprites a sense of life.
/// Honours Reduce Motion by staying still.
private struct IdleBob: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var up = false
    func body(content: Content) -> some View {
        content
            .offset(y: (up && !reduceMotion) ? -6 : 4)
            .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: up)
            .onAppear { if !reduceMotion { up = true } }
    }
}

/// A combat number/word that rises and fades over a combatant, then removes
/// itself via `onClear`. Honours Reduce Motion (fades in place, no travel).
private struct FloatingPopup: View {
    let popup: CombatPopup
    let onClear: (UUID) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false

    var body: some View {
        Text(popup.text)
            .font(popup.flavor == .crit ? .title3.weight(.heavy) : .headline.bold())
            .foregroundStyle(color)
            .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
            .scaleEffect(popup.flavor == .crit && !animate && !reduceMotion ? 1.4 : 1.0)
            .offset(y: (animate && !reduceMotion) ? -44 : 0)
            .opacity(animate ? 0 : 1)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) { animate = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) { onClear(popup.id) }
            }
    }

    private var color: Color {
        switch popup.flavor {
        case .damage: return Theme.hpRed
        case .crit:   return Theme.gold
        case .heal:   return Theme.hpGreen
        case .miss:   return .secondary
        }
    }
}

/// Auto-scrolling combat log.
struct CombatLogView: View {
    let lines: [LogLine]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(lines) { line in
                        Text(line.text)
                            .font(.footnote)
                            .foregroundStyle(color(for: line.kind))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id(line.id)
                    }
                }
                .padding(10)
            }
            .background(Theme.logBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .onChange(of: lines.count) { _ in
                if let last = lines.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    private func color(for kind: LogLine.Kind) -> Color {
        switch kind {
        case .info:      return .primary.opacity(0.8)
        case .playerHit: return Theme.hpGreen
        case .enemyHit:  return Theme.hpRed
        case .miss:      return .secondary
        case .reward:    return Theme.gold
        case .system:    return Theme.mana
        case .danger:    return .red
        }
    }
}
