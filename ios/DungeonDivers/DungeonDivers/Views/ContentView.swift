import SwiftUI

/// Routes between the game's phases.
struct ContentView: View {
    @EnvironmentObject var engine: GameEngine

    var body: some View {
        ZStack {
            Theme.background
            switch engine.phase {
            case .title:
                TitleView()
            case .combat:
                CombatView()
            case .levelUp:
                LevelUpView()
            case .victory:
                GameOverView(won: true)
            case .defeat:
                GameOverView(won: false)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: engine.phase)
    }
}

struct TitleView: View {
    @EnvironmentObject var engine: GameEngine
    @State private var name = ""
    @State private var pulse = false
    @FocusState private var focused: Bool

    var body: some View {
        ScrollFit {
            VStack(spacing: 24) {
                Spacer(minLength: 12)
                Text("🗡️")
                    .font(.system(size: 72))
                    .scaleEffect(pulse ? 1.08 : 0.96)
                    .rotationEffect(.degrees(pulse ? 4 : -4))
                    .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true),
                               value: pulse)
                Text("DUNGEON\nDIVERS")
                    .font(.system(size: 46, weight: .heavy, design: .serif))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.gold)
                    .shadow(color: .black.opacity(0.4), radius: 6, y: 3)
                Text("Crawl the layers. Slay the bosses.\nFell the Imperial Red Dragon.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Panel {
                    VStack(spacing: 12) {
                        Text("What is your name, diver?")
                            .font(.headline)
                        TextField("Diver", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .focused($focused)
                            .submitLabel(.go)
                            .autocorrectionDisabled()
                            .onSubmit(start)
                    }
                }
                .padding(.horizontal, 30)

                Button(action: start) {
                    Text("Begin the Crawl")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.gold)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(PressableButtonStyle())
                .padding(.horizontal, 30)
                Spacer(minLength: 12)
            }
            .padding()
        }
        .onAppear { pulse = true }
    }

    private func start() {
        engine.startGame(named: name.trimmingCharacters(in: .whitespaces))
    }
}
