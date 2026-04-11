import AVFoundation

// MARK: - Sound catalog
enum AppSound: String {
    case happy       = "8bit happy"
    case happy1      = "8bit Pet happy1"
    case happy2      = "8bit Pet happy2"
    case happy3      = "8bit Pet happy3"
    case hype        = "8bit hype"
    case jump        = "8bit jump"
    case crying      = "8bit crying"
    case hurt        = "8bit hurt"
    case death       = "8bit death"
    case angry       = "8bit angry"
    case dizzy       = "8bit dizzy"
    case achievement = "8bit achiviement"
    case day66       = "8bit 66 day"
    case running     = "8bit running"
    case select      = "8bit select"
}

// MARK: - Manager
final class SoundManager {
    static let shared = SoundManager()

    private var sfxPlayer: AVAudioPlayer?
    private var musicPlayer: AVAudioPlayer?
    private var deathSequenceWork: DispatchWorkItem?

    private init() {
        configureSession()
    }

    // MARK: - Session

    private func configureSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {}
    }

    // MARK: - Sound effects

    func play(_ sound: AppSound, enabled: Bool, loop: Bool = false) {
        guard enabled else { return }
        guard let url = resolveURL(name: sound.rawValue, folder: "sounds") else { return }
        do {
            sfxPlayer = try AVAudioPlayer(contentsOf: url)
            sfxPlayer?.volume = 0.75
            sfxPlayer?.numberOfLoops = loop ? -1 : 0
            sfxPlayer?.prepareToPlay()
            sfxPlayer?.play()
        } catch {}
    }

    // MARK: - Music

    func cancelDeathSequence() {
        deathSequenceWork?.cancel()
        deathSequenceWork = nil
    }

    func playMusic(name: String, enabled: Bool, loop: Bool = true) {
        cancelDeathSequence()
        guard enabled else { return }
        guard let url = resolveURL(name: name, folder: "songs") else { return }
        do {
            musicPlayer = try AVAudioPlayer(contentsOf: url)
            musicPlayer?.numberOfLoops = loop ? -1 : 0
            musicPlayer?.volume = 0.5
            musicPlayer?.prepareToPlay()
            musicPlayer?.play()
            currentMusicName = name
        } catch {}
    }

    func playRandomHappy(enabled: Bool, loop: Bool = false) {
        let variants: [AppSound] = [.happy, .happy1, .happy2, .happy3]
        play(variants.randomElement()!, enabled: enabled, loop: loop)
    }

    /// Plays the death sound once, then loops "continue?" music.
    /// Uses musicPlayer so sfxPlayer stays free and nothing can interrupt the sequence.
    func playDeathSequence(enabled: Bool) {
        stopSFX()   // Kill any looping sfx (crying, dizzy) immediately
        guard enabled else { return }
        guard let url = resolveURL(name: AppSound.death.rawValue, folder: "sounds") else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.playMusic(name: "continue?", enabled: enabled, loop: true)
            }
            return
        }
        do {
            deathSequenceWork?.cancel()
            musicPlayer?.stop()
            musicPlayer = try AVAudioPlayer(contentsOf: url)
            musicPlayer?.numberOfLoops = 0
            musicPlayer?.volume = 0.75
            musicPlayer?.prepareToPlay()
            musicPlayer?.play()
            let duration = musicPlayer?.duration ?? 1.5
            let work = DispatchWorkItem { [weak self] in
                self?.playMusic(name: "continue?", enabled: enabled, loop: true)
            }
            deathSequenceWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.2, execute: work)
        } catch {}
    }

    var isMusicPlaying: Bool { musicPlayer?.isPlaying == true }
    private(set) var currentMusicName: String? = nil

    func stopSFX(fadeDuration: TimeInterval = 0) {
        guard let player = sfxPlayer else { return }
        if fadeDuration > 0 {
            player.setVolume(0, fadeDuration: fadeDuration)
            DispatchQueue.main.asyncAfter(deadline: .now() + fadeDuration) { [weak self] in
                self?.sfxPlayer?.stop()
                self?.sfxPlayer = nil
            }
        } else {
            player.stop()
            sfxPlayer = nil
        }
    }

    func stopMusic(fadeDuration: TimeInterval = 1.2) {
        guard let player = musicPlayer, player.isPlaying else { return }
        player.setVolume(0, fadeDuration: fadeDuration)
        DispatchQueue.main.asyncAfter(deadline: .now() + fadeDuration) { [weak self] in
            self?.musicPlayer?.stop()
            self?.musicPlayer = nil
            self?.currentMusicName = nil
        }
    }

    // MARK: - Helpers

    private func resolveURL(name: String, folder: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: "mp3", subdirectory: folder)
            ?? Bundle.main.url(forResource: name, withExtension: "mp3")
    }
}
