import SwiftUI
import Combine


struct ClockPage: View {
    // live clock
    @State private var now = Date()
    let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // simple countdown
    @State private var isCounting = false
    @State private var startSeconds = 60
    @State private var remaining = 60
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Clock & Countdown")
                .font(.title.bold())
                .padding(.top)
            
            // Digital clock
            Text(now.formatted(.dateTime.hour().minute().second()))
                .font(.system(size: 56, weight: .semibold, design: .rounded))
                .monospacedDigit()
            
            Divider().padding(.vertical, 8)
            
            // Countdown Controls
            VStack(spacing: 12) {
                Text("Countdown")
                    .font(.headline)
                Text(secondsToHMS(remaining))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .monospacedDigit()
                
                HStack {
                    Stepper("Start at \(startSeconds)s",
                            value: $startSeconds,
                            in: 5...600,
                            step: 5,
                            onEditingChanged: { _ in
                                if !isCounting { remaining = startSeconds }
                            })
                }
                
                HStack(spacing: 16) {
                    Button(isCounting ? "Pause" : "Start") {
                        if !isCounting && remaining <= 0 { remaining = startSeconds }
                        isCounting.toggle()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Reset") {
                        isCounting = false
                        remaining = startSeconds
                    }
                    .buttonStyle(.bordered)
                }
            }
            Spacer()
        }
        .padding()
        .onReceive(tick) { _ in
            now = Date()
            if isCounting && remaining > 0 {
                remaining -= 1
            } else if isCounting && remaining == 0 {
                // stop at zero
                isCounting = false
                // (optional) simple haptic
                #if os(iOS)
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                #endif
            }
        }
        .onAppear { remaining = startSeconds }
    }
    
    private func secondsToHMS(_ s: Int) -> String {
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        if h > 0 { return String(format: "%02d:%02d:%02d", h, m, sec) }
        return String(format: "%02d:%02d", m, sec)
    }
}

#Preview {
    ClockPage()
}
