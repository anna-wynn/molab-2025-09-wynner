import AVFoundation

@Observable
class AudioManager {
    private(set) var trackIndex = 0
    private(set) var currentTitle = AudioManager.tracks[0].title
    private var player: AVAudioPlayer? = nil
    
    init() { print("AudioManager init") }
    
    func play() {
        loadCurrentIfNeeded()
        // loop forever
        player?.numberOfLoops = -1
        player?.play()
    }
    
    func pause() {
        player?.pause()
    }
    
    func stop() {
        player?.stop()
    }
    
    func next() {
        choose((trackIndex + 1) % AudioManager.tracks.count)
        play()
    }
    
    func choose(_ index: Int) {
        trackIndex = index
        currentTitle = AudioManager.tracks[trackIndex].title
        player = loadAudio(AudioManager.tracks[trackIndex].url)
    }
    
    func setVolume(_ value: Float) {
        player?.volume = value
    }
    
    // MARK: - Loading
    private func loadCurrentIfNeeded() {
        if player == nil { player = loadAudio(AudioManager.tracks[trackIndex].url) }
    }
    
    private func loadAudio(_ ref: String) -> AVAudioPlayer? {
        if ref.hasPrefix("http") { return loadRemote(ref) }
        return loadBundle(ref)
    }
    
    private func loadRemote(_ urlString: String) -> AVAudioPlayer? {
        guard let url = URL(string: urlString) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            return try AVAudioPlayer(data: data)
        } catch { print("loadRemote error:", error); return nil }
    }
    
    private func loadBundle(_ fileName: String) -> AVAudioPlayer? {
        guard let path = Bundle.main.path(forResource: fileName, ofType: nil) else { return nil }
        do {
            return try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
        } catch { print("loadBundle error:", error); return nil }
    }
    
    // Replace these with your own files/URLs if you want.
    static let tracks: [(title: String, url: String)] = [
        ("Pentatonic on F♯", "https://www.youraccompanist.com/images/stories/Reference%20Scales_Pentatonic%20on%20F%20Sharp.mp3"),
        ("Chromatic on F♯", "https://www.youraccompanist.com/images/stories/Reference%20Scales_Chromatic%20Scale%20On%20F%20Sharp.mp3"),
        ("A♭–G♯ Scale",     "https://www.youraccompanist.com/images/stories/Reference%20Scales_On%20A%20Flat-G%20Sharp.mp3"),
    ]
}
