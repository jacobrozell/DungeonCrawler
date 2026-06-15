import SwiftUI

struct LevelUpView: View {
    @EnvironmentObject var engine: GameEngine

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            Text("⬆️").font(.system(size: 64))
            Text("Level Up!")
                .font(.system(size: 40, weight: .heavy, design: .serif))
                .foregroundStyle(Theme.gold)
            Text("Choose a stat to boost. It rises by the larger amount; the others still grow a little.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.75))
                .padding(.horizontal, 30)

            VStack(spacing: 14) {
                ForEach(Player.Upgrade.allCases, id: \.self) { upgrade in
                    Button {
                        engine.chooseUpgrade(upgrade)
                    } label: {
                        HStack {
                            Image(systemName: upgrade.icon)
                            Text(upgrade.label).font(.title3.bold())
                            Spacer()
                            Text(detail(upgrade)).font(.subheadline)
                        }
                        .padding(.vertical, 16).padding(.horizontal, 18)
                        .frame(maxWidth: .infinity)
                        .background(Theme.panel)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.panelStroke))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            .padding(.horizontal, 24)
            Spacer()
        }
    }

    private func detail(_ upgrade: Player.Upgrade) -> String {
        switch upgrade {
        case .attack:  return "+10 ATK"
        case .defense: return "+10 DEF"
        case .health:  return "+20 HP"
        }
    }
}
