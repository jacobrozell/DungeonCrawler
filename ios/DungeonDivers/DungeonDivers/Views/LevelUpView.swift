import SwiftUI

struct LevelUpView: View {
    @EnvironmentObject var engine: GameEngine

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        ScrollFit {
            VStack(spacing: 22) {
                Spacer(minLength: 12)
                Text("⬆️")
                    .font(.system(size: 64))
                    .scaleEffect(reduceMotion ? 1 : (appeared ? 1 : 0.5))
                    .animation(.spring(response: 0.5, dampingFraction: 0.5), value: appeared)
                Text("Level Up!")
                    .font(.system(size: 40, weight: .heavy, design: .serif))
                    .foregroundStyle(Theme.gold)
                Text("Choose a stat to boost. It rises by the larger amount; the others still grow a little.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
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
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
                .padding(.horizontal, 24)
                Spacer(minLength: 12)
            }
            .padding(.vertical)
        }
        .onAppear { appeared = true }
    }

    private func detail(_ upgrade: Player.Upgrade) -> String {
        switch upgrade {
        case .attack:  return "+10 ATK"
        case .defense: return "+10 DEF"
        case .health:  return "+20 HP"
        }
    }
}
