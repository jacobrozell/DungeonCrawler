import SwiftUI

/// Between-layers shop. Spend gold on consumables and permanent upgrades.
struct ShopView: View {
    @EnvironmentObject var engine: GameEngine
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollFit {
            VStack(spacing: 18) {
                Spacer(minLength: 12)
                Text("🪙")
                    .font(.system(size: 56))
                    .scaleEffect(reduceMotion ? 1 : (appeared ? 1 : 0.5))
                    .animation(.spring(response: 0.5, dampingFraction: 0.55), value: appeared)
                Text("Merchant")
                    .font(.system(size: 36, weight: .heavy, design: .serif))
                    .foregroundStyle(Theme.gold)

                Label("\(Formatting.short(engine.player.gold)) gold", systemImage: "centsign.circle.fill")
                    .font(.headline)
                    .foregroundStyle(Theme.gold)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.3), value: engine.player.gold)

                if engine.player.potions > 0 || engine.player.ethers > 0 {
                    HStack(spacing: 14) {
                        if engine.player.potions > 0 { Text("🧪 ×\(engine.player.potions)") }
                        if engine.player.ethers > 0 { Text("🔮 ×\(engine.player.ethers)") }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(ShopItem.allCases) { item in
                        itemCard(item)
                    }
                }
                .padding(.horizontal, 16)

                Button {
                    engine.leaveShop()
                } label: {
                    Text("Dive to Layer \(engine.layer)")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.gold)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(PressableButtonStyle())
                .padding(.horizontal, 24)
                Spacer(minLength: 12)
            }
            .padding(.vertical)
        }
        .onAppear { appeared = true }
    }

    private func itemCard(_ item: ShopItem) -> some View {
        let cost = engine.price(item)
        let affordable = engine.canAfford(item)
        return Button {
            engine.buy(item)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(item.icon).font(.title2)
                    Spacer()
                    Label(Formatting.short(cost), systemImage: "centsign.circle.fill")
                        .font(.caption.bold())
                        .foregroundStyle(Theme.gold)
                }
                Text(item.name).font(.subheadline.bold())
                Text(item.blurb)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
            .padding(12)
            .background(Theme.panel)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.panelStroke))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .opacity(affordable ? 1 : 0.45)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!affordable)
    }
}
