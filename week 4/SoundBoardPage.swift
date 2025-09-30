import SwiftUI

struct SoundboardPage: View {
    @Environment(AudioManager.self) var audio
    @State private var isPlaying = false
    @State private var volume: Float = 1.0
    
    var body: some View {
        VStack(spacing: 18) {
            Text("Soundboard")
                .font(.title.bold())
                .padding(.top)
            
            Text("Now Selected: \(audio.currentTitle)")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Track chooser
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(AudioManager.tracks.enumerated()), id: \.0) { index, track in
                        Button {
                            audio.choose(index)
                            if isPlaying { audio.play() }
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: "music.note.list")
                                    .font(.system(size: 28))
                                Text(track.title)
                                    .font(.footnote)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 120)
                            }
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Transport
            HStack(spacing: 24) {
                Button {
                    audio.next()
                    isPlaying = true
                } label: {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 28))
                }
                Button {
                    isPlaying.toggle()
                    if isPlaying { audio.play() } else { audio.pause() }
                } label: {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                }
                Button {
                    audio.stop()
                    isPlaying = false
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 28))
                }
            }
            .padding(.top, 8)
            
            // Volume
            VStack {
                Text("Volume")
                Slider(value: Binding(
                    get: { Double(volume) },
                    set: { newVal in
                        volume = Float(newVal)
                        audio.setVolume(volume)
                    }), in: 0...1)
                .padding(.horizontal)
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    SoundboardPage().environment(AudioManager())
}

