import SwiftUI

/// Spend Soul Shards on permanent prestige upgrades. Reachable from the title
/// screen and the ascension screen.
struct SkillTreeView: View {
    @EnvironmentObject var engine: GameEngine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    Label("\(engine.availableShards) Soul Shards", systemImage: "sparkles")
                        .font(.title3.bold())
                        .foregroundStyle(.purple)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.3), value: engine.availableShards)
                        .padding(.top, 4)

                    ForEach(SkillNode.allCases) { node in
                        card(node)
                    }
                }
                .padding()
            }
            .navigationTitle("Soul Tree")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func card(_ node: SkillNode) -> some View {
        let lvl = engine.level(of: node)
        let maxed = lvl >= node.maxLevel
        let cost = engine.cost(node)
        let affordable = engine.canUpgrade(node)
        return HStack(spacing: 12) {
            Text(node.icon).font(.largeTitle)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(node.name).font(.headline)
                    Text("Lv \(lvl)/\(node.maxLevel)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Text(node.blurb)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Button { engine.upgradeNode(node) } label: {
                Text(maxed ? "MAX" : "\(cost) ◆")
                    .font(.subheadline.bold())
                    .padding(.vertical, 8).padding(.horizontal, 12)
                    .background(affordable ? Color.purple : Theme.panel)
                    .foregroundStyle(affordable ? .white : .secondary)
                    .clipShape(Capsule())
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(!affordable)
        }
        .padding(12)
        .background(Theme.panel)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.panelStroke))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
