import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Time + Audio Demo")
                    .font(.largeTitle.bold())
                    .padding(.top, 20)
                NavigationLink("⏰ Clock & Countdown") { ClockPage() }
                    .buttonStyle(.borderedProminent)
                NavigationLink("🎧 Soundboard") { SoundboardPage() }
                    .buttonStyle(.bordered)
                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    HomeView().environment(AudioManager())
}

