import SwiftUI

/// Prestige screen — "Descend into the Abyss". Trade the current run for Soul
/// Shards that permanently boost every future run.
struct AscensionView: View {
    @EnvironmentObject var engine: GameEngine
    @State private var showTree = false

    var body: some View {
        ScrollFit {
            VStack(spacing: 20) {
                Spacer(minLength: 12)
                Text("🔮").font(.system(size: 64))
                Text("Descend into the Abyss")
                    .font(.system(size: 32, weight: .heavy, design: .serif))
                    .foregroundStyle(.purple)
                    .multilineTextAlignment(.center)
                Text("End this run to absorb Soul Shards. Shards permanently raise "
                     + "your starting power and gold — every future dive starts stronger.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)

                Panel {
                    VStack(spacing: 8) {
                        row("Shards to spend", "\(engine.availableShards)")
                        row("Shards to gain", "+\(engine.pendingShards)")
                    }
                    .foregroundStyle(.primary)
                }
                .padding(.horizontal, 30)

                if engine.pendingShards == 0 {
                    Text("Earn more gold this run before descending pays off.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Button { showTree = true } label: {
                    Label("Open Soul Tree", systemImage: "sparkles")
                        .font(.subheadline.bold())
                        .foregroundStyle(.purple)
                }

                Button {
                    engine.ascend()
                } label: {
                    Text(engine.pendingShards > 0
                         ? "Descend — gain \(engine.pendingShards) shards"
                         : "Descend anyway")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.purple)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(PressableButtonStyle())
                .padding(.horizontal, 30)

                Button { engine.cancelAscension() } label: {
                    Text("Keep diving")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 12)
            }
            .padding(.vertical)
        }
        .sheet(isPresented: $showTree) { SkillTreeView() }
    }

    private func row(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k).foregroundStyle(.secondary)
            Spacer()
            Text(v).bold()
        }
        .font(.subheadline)
    }
}
