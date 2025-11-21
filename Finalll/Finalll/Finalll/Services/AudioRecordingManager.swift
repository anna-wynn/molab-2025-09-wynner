//
//  AudioRecordingManager.swift
//  Finalll
//
//  Created for MindEase
//

import Foundation
import AVFoundation
import Combine

class AudioRecordingManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var errorMessage: String?
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var audioSession: AVAudioSession = AVAudioSession.sharedInstance()
    private var recordingURL: URL?
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true)
        } catch {
            errorMessage = "Failed to setup audio session: \(error.localizedDescription)"
        }
    }
    
    func requestMicrophonePermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    func startRecording() async throws {
        // Request permission
        let hasPermission = await requestMicrophonePermission()
        guard hasPermission else {
            throw RecordingError.permissionDenied
        }
        
        // Setup audio session
        try audioSession.setCategory(.record, mode: .default)
        try audioSession.setActive(true)
        
        // Create recording URL
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        recordingURL = documentsPath.appendingPathComponent("recording_\(UUID().uuidString).m4a")
        
        guard let recordingURL = recordingURL else {
            throw RecordingError.failedToCreateFile
        }
        
        // Configure recorder settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        // Create recorder
        audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
        audioRecorder?.delegate = self
        audioRecorder?.record()
        
        isRecording = true
        recordingDuration = 0
        
        // Start timer
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.recordingDuration += 0.1
            
            // Auto-stop at 60 seconds
            if self.recordingDuration >= 60.0 {
                Task { @MainActor in
                    try? await self.stopRecording()
                }
            }
        }
    }
    
    func stopRecording() async throws -> URL? {
        audioRecorder?.stop()
        audioRecorder = nil
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        isRecording = false
        
        try audioSession.setActive(false)
        
        guard let url = recordingURL else {
            throw RecordingError.noRecordingFound
        }
        
        // Verify file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw RecordingError.fileNotFound
        }
        
        return url
    }
    
    func cancelRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        isRecording = false
        
        // Delete file if exists
        if let url = recordingURL, FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
        
        recordingURL = nil
        
        try? audioSession.setActive(false)
    }
    
    func getRecordingURL() -> URL? {
        return recordingURL
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioRecordingManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            errorMessage = "Recording failed"
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        errorMessage = error?.localizedDescription ?? "Unknown recording error"
    }
}

// MARK: - Errors
enum RecordingError: LocalizedError {
    case permissionDenied
    case failedToCreateFile
    case noRecordingFound
    case fileNotFound
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission denied"
        case .failedToCreateFile:
            return "Failed to create recording file"
        case .noRecordingFound:
            return "No recording found"
        case .fileNotFound:
            return "Recording file not found"
        }
    }
}

