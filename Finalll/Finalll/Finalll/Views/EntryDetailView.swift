//
//  EntryDetailView.swift
//  Finalll
//
//  Created for MindEase
//

import SwiftUI

struct EntryDetailView: View {
    let entry: MoodEntry
    @StateObject private var viewModel = MoodViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Mood Flower
                MoodFlowerView(
                    emotion: entry.emotionCategory,
                    confidence: entry.emotionConfidence,
                    colorHex: entry.moodFlowerColor
                )
                .padding(.top, 20)
                
                // Emotion Category
                Text(entry.emotionCategory)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Insight
                Text(entry.insight)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Divider()
                
                // Details
                VStack(alignment: .leading, spacing: 16) {
                    DetailRow(label: "Date", value: formatDate(entry.timestamp))
                    DetailRow(label: "Input Type", value: entry.inputType.capitalized)
                    DetailRow(label: "Confidence", value: String(format: "%.0f%%", entry.emotionConfidence * 100))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Transcript")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text(entry.transcript)
                            .font(.body)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Mood Entry")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.headline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.body)
        }
    }
}

#Preview {
    NavigationView {
        EntryDetailView(entry: MoodEntry(
            timestamp: Date(),
            inputType: "voice",
            transcript: "I'm feeling really happy today!",
            emotionCategory: "Happy",
            emotionConfidence: 0.9,
            insight: "You're feeling positive and content today.",
            moodFlowerColor: "#FFD700"
        ))
    }
}

