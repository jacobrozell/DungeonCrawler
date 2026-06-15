import SwiftUI

struct GameOverView: View {
    @EnvironmentObject var engine: GameEngine
    let won: Bool

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text(won ? "🐉" : "💀").font(.system(size: 80))
            Text(won ? "VICTORY!" : "You Died")
                .font(.system(size: 44, weight: .heavy, design: .serif))
                .foregroundStyle(won ? Theme.gold : Theme.hpRed)
            Text(won
                 ? "You felled the Imperial Red Dragon and conquered Dungeon Divers!"
                 : "The dungeon claims another diver.")
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.8))
                .padding(.horizontal, 30)

            Panel {
                VStack(alignment: .leading, spacing: 6) {
                    row("Hero", engine.player.name)
                    row("Level reached", "\(engine.player.level)")
                    row("Layer reached", "\(engine.layer)")
                    row("Gold collected", "\(engine.player.gold)")
                }
                .foregroundStyle(.white)
            }
            .padding(.horizontal, 30)

            if won {
                Button {
                    engine.continueEndless()
                } label: {
                    actionLabel("Dive Deeper (Endless)", Theme.mana)
                }
                .padding(.horizontal, 30)
            }

            Button {
                engine.startGame(named: engine.player.name)
            } label: {
                actionLabel(won ? "New Run" : "Try Again", Theme.gold, dark: true)
            }
            .padding(.horizontal, 30)
            Spacer()
        }
        .padding()
    }

    private func row(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k).foregroundStyle(.white.opacity(0.7))
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
