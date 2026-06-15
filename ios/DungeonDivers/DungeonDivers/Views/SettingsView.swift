import SwiftUI

/// Audio settings sheet. Toggles persist via `@AppStorage` (same keys the
/// `SoundManager` reads). Defaults: both on.
struct SettingsView: View {
    @AppStorage("audio.sfxEnabled") private var sfxEnabled = true
    @AppStorage("audio.musicEnabled") private var musicEnabled = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Audio") {
                    Toggle("Sound effects", isOn: $sfxEnabled)
                    Toggle("Music", isOn: $musicEnabled)
                        .onChange(of: musicEnabled) { _ in
                            SoundManager.shared.musicSettingChanged()
                        }
                }
                Section("About") {
                    LabeledContent("Game", value: "Dungeon Divers")
                    Text("A SwiftUI remake of a one-night Java console game. "
                         + "Audio respects the silent switch and won't interrupt "
                         + "your own music.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
