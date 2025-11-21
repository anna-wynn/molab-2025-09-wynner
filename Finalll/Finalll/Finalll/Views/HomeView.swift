//
//  HomeView.swift
//  Finalll
//
//  Created for MindEase
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = MoodViewModel()
    @StateObject private var authViewModel = AuthViewModel()
    @State private var inputText = ""
    @State private var isRecording = false
    @State private var recordingDuration: TimeInterval = 0
    @State private var showingHistory = false
    @State private var lastMoodEntry: MoodEntry?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Text("MindEase")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button(action: {
                            showingHistory = true
                        }) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.title2)
                        }
                        
                        Button(action: {
                            authViewModel.signOut()
                        }) {
                            Image(systemName: "person.circle")
                                .font(.title2)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Last Mood Entry Display
                    if let entry = lastMoodEntry {
                        VStack(spacing: 16) {
                            MoodFlowerView(
                                emotion: entry.emotionCategory,
                                confidence: entry.emotionConfidence,
                                colorHex: entry.moodFlowerColor
                            )
                            
                            Text(entry.emotionCategory)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text(entry.insight)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                    
                    // Input Section
                    VStack(spacing: 16) {
                        // Text Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("How are you feeling?")
                                .font(.headline)
                            
                            TextEditor(text: $inputText)
                                .frame(height: 100)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                        }
                        
                        // Voice Recording Button
                        VStack(spacing: 12) {
                            Button(action: {
                                if isRecording {
                                    stopRecording()
                                } else {
                                    startRecording()
                                }
                            }) {
                                HStack {
                                    Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                        .font(.title)
                                    Text(isRecording ? "Stop Recording" : "Record Voice")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isRecording ? Color.red : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            
                            if isRecording {
                                Text(formatDuration(recordingDuration))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Submit Text Button
                        Button(action: {
                            Task {
                                await viewModel.processTextInput(inputText)
                                if let latest = viewModel.moodEntries.first {
                                    lastMoodEntry = latest
                                    inputText = ""
                                }
                            }
                        }) {
                            if viewModel.isProcessing {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("Submit")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isProcessing)
                    }
                    .padding(.horizontal)
                    
                    // Error Message
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingHistory) {
                HistoryView()
            }
            .onAppear {
                Task {
                    await viewModel.loadMoodEntries()
                    lastMoodEntry = viewModel.moodEntries.first
                }
            }
        }
    }
    
    private func startRecording() {
        Task {
            do {
                try await viewModel.recordingManager.startRecording()
                isRecording = true
                
                // Start timer
                Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                    if isRecording {
                        recordingDuration = viewModel.recordingManager.recordingDuration
                    } else {
                        timer.invalidate()
                    }
                }
            } catch {
                viewModel.errorMessage = error.localizedDescription
            }
        }
    }
    
    private func stopRecording() {
        Task {
            isRecording = false
            if let audioURL = try? await viewModel.recordingManager.stopRecording() {
                await viewModel.processVoiceInput(audioURL: audioURL)
                if let latest = viewModel.moodEntries.first {
                    lastMoodEntry = latest
                }
            }
            recordingDuration = 0
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    HomeView()
}

