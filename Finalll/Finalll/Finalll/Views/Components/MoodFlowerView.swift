//
//  MoodFlowerView.swift
//  Finalll
//
//  Created for MindEase
//

import SwiftUI

struct MoodFlowerView: View {
    let emotion: String
    let confidence: Double
    let colorHex: String
    
    @State private var animationScale: CGFloat = 0.8
    
    private var color: Color {
        Color(hex: colorHex) ?? .yellow
    }
    
    private var flowerSize: CGFloat {
        // Size based on confidence (0.5 to 1.0 maps to 80 to 120 points)
        let baseSize: CGFloat = 80
        let maxSize: CGFloat = 120
        let sizeRange = maxSize - baseSize
        let size = baseSize + (CGFloat(confidence) * sizeRange)
        return size
    }
    
    var body: some View {
        ZStack {
            // Outer petals (larger, more transparent)
            ForEach(0..<8) { index in
                PetalShape()
                    .fill(color.opacity(0.3))
                    .frame(width: flowerSize * 1.2, height: flowerSize * 1.2)
                    .rotationEffect(.degrees(Double(index) * 45))
                    .scaleEffect(animationScale)
            }
            
            // Inner petals (smaller, more opaque)
            ForEach(0..<6) { index in
                PetalShape()
                    .fill(color.opacity(0.6))
                    .frame(width: flowerSize * 0.8, height: flowerSize * 0.8)
                    .rotationEffect(.degrees(Double(index) * 60 + 30))
                    .scaleEffect(animationScale)
            }
            
            // Center circle
            Circle()
                .fill(color)
                .frame(width: flowerSize * 0.3, height: flowerSize * 0.3)
                .scaleEffect(animationScale)
        }
        .frame(width: flowerSize * 1.5, height: flowerSize * 1.5)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animationScale = 1.0
            }
        }
    }
}

struct PetalShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let width = rect.width
        let height = rect.height
        
        // Create petal shape (ellipse rotated)
        path.addEllipse(in: CGRect(
            x: center.x - width / 4,
            y: center.y - height / 2,
            width: width / 2,
            height: height
        ))
        
        return path
    }
}

// Color extension for hex support
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    VStack(spacing: 30) {
        MoodFlowerView(emotion: "Happy", confidence: 0.9, colorHex: "#FFD700")
        MoodFlowerView(emotion: "Sad", confidence: 0.7, colorHex: "#4169E1")
        MoodFlowerView(emotion: "Angry", confidence: 0.8, colorHex: "#FF4500")
    }
    .padding()
}

