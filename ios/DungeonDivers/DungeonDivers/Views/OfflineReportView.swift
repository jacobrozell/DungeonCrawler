import SwiftUI

/// "While you were away…" summary shown on resume when offline auto-battle
/// earned gold.
struct OfflineReportView: View {
    let report: OfflineReport
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("💤").font(.system(size: 64))
            Text("While you were away")
                .font(.title.bold())
                .foregroundStyle(Theme.gold)
            Text("Your auto-battle kept diving for \(durationText).")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Panel {
                HStack {
                    Text("🪙").font(.title2)
                    Text("+\(Formatting.short(report.gold)) gold")
                        .font(.title3.bold())
                        .foregroundStyle(Theme.gold)
                }
            }
            .padding(.horizontal, 30)

            Button { dismiss() } label: {
                Text("Collect")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.gold)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(PressableButtonStyle())
            .padding(.horizontal, 30)
            Spacer()
        }
        .padding()
        .presentationDetents([.medium])
    }

    private var durationText: String {
        let mins = Int(report.duration / 60)
        if mins < 60 { return "\(max(1, mins)) min" }
        let h = mins / 60, m = mins % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }
}
