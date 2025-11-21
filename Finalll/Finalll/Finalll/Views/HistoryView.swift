//
//  HistoryView.swift
//  Finalll
//
//  Created for MindEase
//

import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = MoodViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                } else if viewModel.moodEntries.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge-clock")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No mood entries yet")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Start logging your moods to see them here")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        // Weekly Trends Section
                        Section("Weekly Trends") {
                            let trends = viewModel.getWeeklyTrends()
                            if trends.isEmpty {
                                Text("No entries this week")
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(Array(trends.keys.sorted()), id: \.self) { emotion in
                                    HStack {
                                        Circle()
                                            .fill(Color(hex: EmotionMapper.getColorForEmotion(emotion)) ?? .gray)
                                            .frame(width: 12, height: 12)
                                        Text(emotion)
                                        Spacer()
                                        Text("\(trends[emotion] ?? 0)")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        
                        // Timeline Section
                        Section("Timeline") {
                            ForEach(viewModel.moodEntries) { entry in
                                NavigationLink(destination: EntryDetailView(entry: entry)) {
                                    MoodEntryRow(entry: entry)
                                }
                            }
                            .onDelete { indexSet in
                                for index in indexSet {
                                    Task {
                                        await viewModel.deleteMoodEntry(viewModel.moodEntries[index])
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadMoodEntries()
                }
            }
        }
    }
}

struct MoodEntryRow: View {
    let entry: MoodEntry
    
    var body: some View {
        HStack(spacing: 12) {
            // Mood Flower Mini
            MoodFlowerView(
                emotion: entry.emotionCategory,
                confidence: entry.emotionConfidence,
                colorHex: entry.moodFlowerColor
            )
            .frame(width: 50, height: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.emotionCategory)
                    .font(.headline)
                
                Text(entry.transcript)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text(entry.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HistoryView()
}

