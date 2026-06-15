import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// A horizontal shake driven by an incrementing trigger value. Each whole-number
/// step of `animatableData` plays one full shake cycle.
struct Shake: GeometryEffect {
    var amount: CGFloat = 7
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let dx = amount * CGFloat(sin(Double(animatableData) * .pi * Double(shakesPerUnit)))
        return ProjectionTransform(CGAffineTransform(translationX: dx, y: 0))
    }
}

/// Thin wrapper around UIKit haptics (no-ops on platforms without UIKit).
enum Haptics {
    enum Feel { case light, medium, heavy, success, warning, error }

    static func play(_ feel: Feel) {
        #if canImport(UIKit)
        switch feel {
        case .light:   UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:  UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:   UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .success: UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning: UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:   UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        #endif
    }
}

/// Central palette + reusable styling so the dungeon has a consistent look.
enum Theme {
    static let bgTop = Color(red: 0.06, green: 0.05, blue: 0.10)
    static let bgBottom = Color(red: 0.02, green: 0.02, blue: 0.05)
    static let panel = Color.white.opacity(0.06)
    static let panelStroke = Color.white.opacity(0.12)
    static let gold = Color(red: 0.98, green: 0.80, blue: 0.30)
    static let hpGreen = Color(red: 0.30, green: 0.85, blue: 0.40)
    static let hpRed = Color(red: 0.90, green: 0.25, blue: 0.25)
    static let mana = Color(red: 0.35, green: 0.60, blue: 0.95)

    static func tint(_ name: String) -> Color {
        switch name {
        case "green":  return .green
        case "pink":   return .pink
        case "gray":   return .gray
        case "brown":  return Color(red: 0.6, green: 0.4, blue: 0.2)
        case "purple": return .purple
        case "blue":   return .blue
        case "yellow": return .yellow
        case "red":    return .red
        default:        return .white
        }
    }

    static var background: some View {
        LinearGradient(colors: [bgTop, bgBottom],
                       startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
}

/// A frosted rounded panel used throughout the UI.
struct Panel<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(14)
            .background(Theme.panel)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.panelStroke))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

/// Animated horizontal stat bar (HP / mana).
struct StatBar: View {
    let value: Int
    let maxValue: Int
    let tint: Color
    var label: String

    private var fraction: Double {
        guard maxValue > 0 else { return 0 }
        return max(0, min(1, Double(value) / Double(maxValue)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(label).font(.caption2.bold())
                Spacer()
                Text("\(value)/\(maxValue)").font(.caption2.monospacedDigit())
            }
            .foregroundStyle(.white.opacity(0.85))

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.12))
                    Capsule()
                        .fill(tint)
                        .frame(width: max(4, geo.size.width * fraction))
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: fraction)
                }
            }
            .frame(height: 10)
        }
    }
}
