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
///
/// Colours are *adaptive*: a moody dark dungeon under Dark Mode, and a lighter
/// "stone tablet" palette under Light Mode. Text uses SwiftUI's `.primary` /
/// `.secondary` so it flips automatically; only these accent/surface colours
/// need custom adaptation.
enum Theme {
    /// Resolve a light/dark colour pair against the current trait collection.
    private static func adaptive(light: Color, dark: Color) -> Color {
        #if canImport(UIKit)
        return Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #else
        return dark
        #endif
    }

    static let bgTop = adaptive(light: Color(red: 0.95, green: 0.92, blue: 0.86),
                                dark:  Color(red: 0.06, green: 0.05, blue: 0.10))
    static let bgBottom = adaptive(light: Color(red: 0.85, green: 0.81, blue: 0.73),
                                   dark:  Color(red: 0.02, green: 0.02, blue: 0.05))
    static let panel = adaptive(light: Color.white.opacity(0.55),
                                dark:  Color.white.opacity(0.06))
    static let panelStroke = adaptive(light: Color.black.opacity(0.12),
                                      dark:  Color.white.opacity(0.12))
    static let track = adaptive(light: Color.black.opacity(0.10),
                                dark:  Color.white.opacity(0.12))
    static let logBackground = adaptive(light: Color.black.opacity(0.06),
                                        dark:  Color.black.opacity(0.25))
    static let gold = adaptive(light: Color(red: 0.78, green: 0.56, blue: 0.10),
                               dark:  Color(red: 0.98, green: 0.80, blue: 0.30))
    static let hpGreen = Color(red: 0.25, green: 0.72, blue: 0.36)
    static let hpRed = Color(red: 0.85, green: 0.23, blue: 0.23)
    static let mana = Color(red: 0.32, green: 0.55, blue: 0.92)

    static func tint(_ name: String) -> Color {
        switch name {
        case "green":  return adaptive(light: Color(red: 0.20, green: 0.55, blue: 0.25), dark: .green)
        case "pink":   return .pink
        case "gray":   return .gray
        case "brown":  return Color(red: 0.6, green: 0.4, blue: 0.2)
        case "purple": return .purple
        case "blue":   return .blue
        case "yellow": return adaptive(light: Color(red: 0.70, green: 0.55, blue: 0.05), dark: .yellow)
        case "red":    return .red
        default:        return .primary
        }
    }

    static var background: some View {
        LinearGradient(colors: [bgTop, bgBottom],
                       startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
}

/// Button style giving a tactile press: a quick scale-down + dim.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6),
                       value: configuration.isPressed)
    }
}

/// Scrolls its content when it would otherwise overflow (e.g. landscape on a
/// short screen) while still centring it vertically when there's room.
struct ScrollFit<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        GeometryReader { geo in
            ScrollView(showsIndicators: false) {
                content
                    .frame(minHeight: geo.size.height)
                    .frame(maxWidth: .infinity)
            }
        }
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
                    .contentTransition(.numericText())
            }
            .foregroundStyle(.primary.opacity(0.85))

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.track)
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
