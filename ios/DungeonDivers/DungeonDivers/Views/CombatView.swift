import SwiftUI

struct CombatView: View {
    @EnvironmentObject var engine: GameEngine

    var body: some View {
        VStack(spacing: 12) {
            headerBar
            enemyStage
            CombatLogView(lines: engine.log)
                .frame(maxHeight: .infinity)
            playerStatus
            moveButtons
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .offset(x: engine.screenShake ? 6 : 0)
        .onChange(of: engine.screenShake) { shaking in
            if shaking {
                withAnimation(.default.repeatCount(3, autoreverses: true).speed(6)) {}
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    engine.screenShake = false
                }
            }
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
        }
        .font(.subheadline.bold())
        .foregroundStyle(.white.opacity(0.85))
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
                            .clipShape(Capsule())
                    }
                    Spacer()
                    Text("Lv \(engine.enemy.level)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.7))
                }
                Text(engine.enemy.sprite)
                    .font(.system(size: 72))
                    .scaleEffect(engine.enemyFlash ? 1.15 : 1.0)
                    .opacity(engine.enemyFlash ? 0.5 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: engine.enemyFlash)
                    .onChange(of: engine.enemyFlash) { flash in
                        if flash {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                                engine.enemyFlash = false
                            }
                        }
                    }
                StatBar(value: engine.enemy.hp, maxValue: engine.enemy.maxHp,
                        tint: Theme.hpRed, label: "Enemy HP")
                HStack(spacing: 16) {
                    statChip("burst.fill", engine.enemy.attack)
                    statChip("shield.lefthalf.filled", engine.enemy.defense)
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.75))
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
                .foregroundStyle(.white)
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
                .foregroundStyle(.white.opacity(0.75))
            }
        }
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
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(Move.allCases) { move in
                Button {
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
                    .opacity(engine.player.mana >= move.manaCost ? 1 : 0.4)
                }
                .disabled(engine.player.mana < move.manaCost)
            }
        }
        .padding(.bottom, 6)
    }

    private func buttonColor(_ move: Move) -> Color {
        switch move {
        case .attack: return Color.red.opacity(0.55)
        case .heavy:  return Color.orange.opacity(0.55)
        case .magic:  return Theme.mana.opacity(0.7)
        case .dodge:  return Color.teal.opacity(0.55)
        case .heal:   return Theme.hpGreen.opacity(0.55)
        }
    }

    private func statChip(_ symbol: String, _ value: Int) -> some View {
        Label("\(value)", systemImage: symbol)
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
            .background(Color.black.opacity(0.25))
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
        case .info:      return .white.opacity(0.8)
        case .playerHit: return Theme.hpGreen
        case .enemyHit:  return Theme.hpRed
        case .miss:      return .white.opacity(0.5)
        case .reward:    return Theme.gold
        case .system:    return Theme.mana
        case .danger:    return .red
        }
    }
}
