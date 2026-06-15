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
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("🗡️").font(.system(size: 72))
            Text("DUNGEON\nDIVERS")
                .font(.system(size: 46, weight: .heavy, design: .serif))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.gold)
                .shadow(color: .black, radius: 6, y: 3)
            Text("Crawl the layers. Slay the bosses.\nFell the Imperial Red Dragon.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.7))

            Panel {
                VStack(spacing: 12) {
                    Text("What is your name, diver?")
                        .font(.headline)
                        .foregroundStyle(.white)
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
            .padding(.horizontal, 30)
            Spacer()
        }
        .padding()
    }

    private func start() {
        engine.startGame(named: name.trimmingCharacters(in: .whitespaces))
    }
}
