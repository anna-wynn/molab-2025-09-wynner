import SwiftUI

struct AppStoragePage: View {
    // Use unique keys so we don't collide with other demos
    @AppStorage("ta_username") private var username: String = "Anonymous"
    @AppStorage("ta_score")    private var score: Int = 0
    @AppStorage("ta_soundOn")  private var soundOn: Bool = true
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Persistent Settings (AppStorage)")
                .font(.title.bold())
                .padding(.top)

            // Username
            VStack(alignment: .leading, spacing: 8) {
                Text("Username")
                    .font(.headline)
                TextField("Enter a name", text: $username)
                    .textFieldStyle(.roundedBorder)
                Text("Welcome, \(username)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            // Score
            VStack(alignment: .leading, spacing: 8) {
                Text("Score")
                    .font(.headline)
                HStack(spacing: 16) {
                    Button("-1") { score -= 1 }
                        .buttonStyle(.bordered)
                    Text("\(score)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .frame(minWidth: 80)
                    Button("+1") { score += 1 }
                        .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal)

            // Toggle
            Toggle(isOn: $soundOn) {
                Text("Sound Enabled")
            }
            .padding(.horizontal)

            // Reset
            Button(role: .destructive) {
                username = "Anonymous"
                score = 0
                soundOn = true
            } label: {
                Text("Reset Stored Values")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .padding(.horizontal)

            Spacer()
            Text("Values persist across app launches via UserDefaults.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.bottom)
        }
        .padding(.top)
    }
}

#Preview {
    AppStoragePage()
}

