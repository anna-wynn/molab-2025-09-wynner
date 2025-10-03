import SwiftUI

@main
struct TimeAudioDemoApp: App {
    @State var audio = AudioManager()
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(audio)
        }
    }
}
