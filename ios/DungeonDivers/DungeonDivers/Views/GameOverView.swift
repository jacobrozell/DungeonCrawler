import SwiftUI

struct GameOverView: View {
    @EnvironmentObject var engine: GameEngine
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let won: Bool

    @State private var appeared = false

    var body: some View {
        ScrollFit {
            VStack(spacing: 20) {
                Spacer(minLength: 12)
                Text(won ? "🐉" : "💀")
                    .font(.system(size: 80))
                    .scaleEffect(reduceMotion ? 1 : (appeared ? 1 : 0.4))
                    .rotationEffect(.degrees(reduceMotion ? 0 : (appeared ? 0 : -15)))
                    .animation(.spring(response: 0.6, dampingFraction: 0.55), value: appeared)
                Text(won ? "VICTORY!" : "You Died")
                    .font(.system(size: 44, weight: .heavy, design: .serif))
                    .foregroundStyle(won ? Theme.gold : Theme.hpRed)
                Text(won
                     ? "You felled the Imperial Red Dragon and conquered Dungeon Divers!"
                     : "The dungeon claims another diver.")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 30)

                if engine.setNewRecord {
                    Label("New best run!", systemImage: "trophy.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(Theme.gold)
                }

                Panel {
                    VStack(alignment: .leading, spacing: 6) {
                        row("Hero", engine.player.name)
                        row("Level reached", "\(engine.player.level)")
                        row("Layer reached", "\(engine.layer)")
                        row("Gold collected", "\(engine.player.gold)")
                        Divider().background(Theme.panelStroke)
                        row("Best layer", "\(engine.best.layer)")
                        row("Best gold", "\(engine.best.gold)")
                    }
                }
                .padding(.horizontal, 30)

                if won {
                    Button {
                        engine.continueEndless()
                    } label: {
                        actionLabel("Dive Deeper (Endless)", Theme.mana)
                    }
                    .buttonStyle(PressableButtonStyle())
                    .padding(.horizontal, 30)
                }

                Button {
                    engine.startGame(named: engine.player.name)
                } label: {
                    actionLabel(won ? "New Run" : "Try Again", Theme.gold, dark: true)
                }
                .buttonStyle(PressableButtonStyle())
                .padding(.horizontal, 30)
                Spacer(minLength: 12)
            }
            .padding()
        }
        .onAppear { appeared = true }
    }

    private func row(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k).foregroundStyle(.secondary)
            Spacer()
            Text(v).bold()
        }
        .font(.subheadline)
    }

    private func actionLabel(_ text: String, _ color: Color, dark: Bool = false) -> some View {
        Text(text)
            .font(.title3.bold())
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color)
            .foregroundStyle(dark ? .black : .white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
