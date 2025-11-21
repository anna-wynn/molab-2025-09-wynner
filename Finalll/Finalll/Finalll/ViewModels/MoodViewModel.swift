//
//  MoodViewModel.swift
//  Finalll
//
//  Created for MindEase
//

import Foundation
import Combine
import SwiftUI

@MainActor
class MoodViewModel: ObservableObject {
    @Published var moodEntries: [MoodEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isProcessing = false
    
    private let moodEntryService = MoodEntryService()
    private let transcriptionService = TranscriptionService()
    private let emotionAnalyzer = EmotionAnalyzer()
    private let audioRecordingManager = AudioRecordingManager()
    
    var recordingManager: AudioRecordingManager {
        audioRecordingManager
    }
    
    func processVoiceInput(audioURL: URL) async {
        isProcessing = true
        errorMessage = nil
        
        do {
            // Step 1: Transcribe audio
            let transcript = try await transcriptionService.transcribeAudio(from: audioURL)
            
            // Step 2: Analyze emotion
            let emotionResult = try await emotionAnalyzer.analyzeEmotion(from: transcript)
            
            // Step 3: Create mood entry
            let moodEntry = MoodEntry(
                timestamp: Date(),
                inputType: "voice",
                transcript: transcript,
                emotionCategory: emotionResult.category,
                emotionConfidence: emotionResult.confidence,
                insight: emotionResult.insight,
                moodFlowerColor: emotionResult.color
            )
            
            // Step 4: Save to Firestore
            try await moodEntryService.saveMoodEntry(moodEntry)
            
            // Step 5: Refresh entries
            await loadMoodEntries()
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isProcessing = false
    }
    
    func processTextInput(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter some text"
            return
        }
        
        isProcessing = true
        errorMessage = nil
        
        do {
            // Step 1: Analyze emotion
            let emotionResult = try await emotionAnalyzer.analyzeEmotion(from: text)
            
            // Step 2: Create mood entry
            let moodEntry = MoodEntry(
                timestamp: Date(),
                inputType: "text",
                transcript: text,
                emotionCategory: emotionResult.category,
                emotionConfidence: emotionResult.confidence,
                insight: emotionResult.insight,
                moodFlowerColor: emotionResult.color
            )
            
            // Step 3: Save to Firestore
            try await moodEntryService.saveMoodEntry(moodEntry)
            
            // Step 4: Refresh entries
            await loadMoodEntries()
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isProcessing = false
    }
    
    func loadMoodEntries() async {
        isLoading = true
        errorMessage = nil
        
        do {
            moodEntries = try await moodEntryService.fetchMoodEntries()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func deleteMoodEntry(_ entry: MoodEntry) async {
        guard let id = entry.id else { return }
        
        do {
            try await moodEntryService.deleteMoodEntry(id)
            await loadMoodEntries()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func getWeeklyTrends() -> [String: Int] {
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        
        let recentEntries = moodEntries.filter { $0.timestamp >= weekAgo }
        
        var trends: [String: Int] = [:]
        for entry in recentEntries {
            trends[entry.emotionCategory, default: 0] += 1
        }
        
        return trends
    }
}

