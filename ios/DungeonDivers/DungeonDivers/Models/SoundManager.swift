import Foundation
#if canImport(AVFoundation)
import AVFoundation
#endif

/// Short sound effects. Resource name == raw value; expected extension `.caf`.
enum SFX: String {
    case swing, crit, miss, magic, poison
    case playerHurt, heal, enemyDie, bossAppear, gold
    case levelUp, purchase, denied, playerDie, victory
}

/// Looping background tracks. Resource name == raw value; expected `.m4a`.
enum MusicTrack: String {
    case title, combat, victory, gameover
}

/// Audio playback mirroring the `Haptics` helper. **Graceful by design:** if an
/// audio file isn't in the bundle (none ship yet — see `Audio/CREDITS.md`), the
/// calls are silent no-ops, so the game runs fine without assets. Drop files in
/// and wire them into the target to light it up.
///
/// Toggles live in `UserDefaults` under `audio.sfxEnabled` / `audio.musicEnabled`
/// (default on) and are edited via `SettingsView`'s `@AppStorage`.
final class SoundManager {
    static let shared = SoundManager()

    private init() { configureSession() }

    private var sfxEnabled: Bool {
        UserDefaults.standard.object(forKey: "audio.sfxEnabled") as? Bool ?? true
    }
    private var musicEnabled: Bool {
        UserDefaults.standard.object(forKey: "audio.musicEnabled") as? Bool ?? true
    }

    #if canImport(AVFoundation)
    private var sfxCache: [String: AVAudioPlayer] = [:]
    private var musicPlayer: AVAudioPlayer?
    private var currentTrack: MusicTrack?

    private func configureSession() {
        // `.ambient` honours the silent switch; `.mixWithOthers` won't stop the
        // user's own music. Failures are non-fatal.
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func url(_ name: String, _ ext: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: ext)
    }
    #else
    private func configureSession() {}
    #endif

    // MARK: - Public API

    func play(_ sfx: SFX) {
        #if canImport(AVFoundation)
        guard sfxEnabled else { return }
        let key = sfx.rawValue
        let player: AVAudioPlayer?
        if let cached = sfxCache[key] {
            player = cached
        } else if let u = url(key, "caf") ?? url(key, "wav") ?? url(key, "m4a"),
                  let made = try? AVAudioPlayer(contentsOf: u) {
            made.prepareToPlay()
            sfxCache[key] = made
            player = made
        } else {
            player = nil   // asset missing → silent
        }
        player?.currentTime = 0
        player?.play()
        #endif
    }

    func playMusic(_ track: MusicTrack) {
        #if canImport(AVFoundation)
        guard musicEnabled else { stopMusic(); return }
        guard currentTrack != track else { return }
        guard let u = url(track.rawValue, "m4a") ?? url(track.rawValue, "caf"),
              let p = try? AVAudioPlayer(contentsOf: u) else { return }
        musicPlayer?.stop()
        p.numberOfLoops = -1
        p.volume = 0.5
        p.prepareToPlay()
        p.play()
        musicPlayer = p
        currentTrack = track
        #endif
    }

    func stopMusic() {
        #if canImport(AVFoundation)
        musicPlayer?.stop()
        musicPlayer = nil
        currentTrack = nil
        #endif
    }

    /// Called by the settings UI when the music toggle flips.
    func musicSettingChanged() {
        #if canImport(AVFoundation)
        if !musicEnabled { stopMusic() }
        #endif
    }
}
