//
//  TranscriptionService.swift
//  Finalll
//
//  Created for MindEase
//

import Foundation

class TranscriptionService {
    private let apiKey: String
    private let baseURL = "https://api.assemblyai.com/v2"
    
    init(apiKey: String = APIConfiguration.assemblyAIAPIKey) {
        self.apiKey = apiKey
    }
    
    func transcribeAudio(from url: URL) async throws -> String {
        guard APIConfiguration.validateKeys() else {
            throw TranscriptionError.invalidAPIKey
        }
        
        // Step 1: Upload audio file
        let uploadURL = try await uploadAudioFile(url: url)
        
        // Step 2: Submit transcription job
        let transcriptId = try await submitTranscription(uploadURL: uploadURL)
        
        // Step 3: Poll for results
        let transcript = try await pollForTranscript(transcriptId: transcriptId)
        
        return transcript
    }
    
    // MARK: - Step 1: Upload Audio File
    private func uploadAudioFile(url: URL) async throws -> String {
        guard let audioData = try? Data(contentsOf: url) else {
            throw TranscriptionError.failedToReadFile
        }
        
        var request = URLRequest(url: URL(string: "\(baseURL)/upload")!)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "authorization")
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.httpBody = audioData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranscriptionError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorData = try? JSONDecoder().decode(AssemblyAIError.self, from: data) {
                throw TranscriptionError.apiError(errorData.error ?? "Upload failed")
            }
            throw TranscriptionError.httpError(httpResponse.statusCode)
        }
        
        guard let json = try? JSONDecoder().decode(UploadResponse.self, from: data),
              let uploadURL = json.upload_url else {
            throw TranscriptionError.invalidResponse
        }
        
        return uploadURL
    }
    
    // MARK: - Step 2: Submit Transcription Job
    private func submitTranscription(uploadURL: String) async throws -> String {
        var request = URLRequest(url: URL(string: "\(baseURL)/transcript")!)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "audio_url": uploadURL
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranscriptionError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorData = try? JSONDecoder().decode(AssemblyAIError.self, from: data) {
                throw TranscriptionError.apiError(errorData.error ?? "Transcription submission failed")
            }
            throw TranscriptionError.httpError(httpResponse.statusCode)
        }
        
        guard let json = try? JSONDecoder().decode(TranscriptResponse.self, from: data),
              let transcriptId = json.id else {
            throw TranscriptionError.invalidResponse
        }
        
        return transcriptId
    }
    
    // MARK: - Step 3: Poll for Transcript Results
    private func pollForTranscript(transcriptId: String) async throws -> String {
        let maxAttempts = 60 // Maximum 60 attempts (about 1 minute)
        let delaySeconds: UInt64 = 1 // Wait 1 second between polls
        
        for attempt in 1...maxAttempts {
            var request = URLRequest(url: URL(string: "\(baseURL)/transcript/\(transcriptId)")!)
            request.httpMethod = "GET"
            request.setValue(apiKey, forHTTPHeaderField: "authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw TranscriptionError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
            }
            
            guard let json = try? JSONDecoder().decode(TranscriptResponse.self, from: data) else {
                throw TranscriptionError.invalidResponse
            }
            
            // Check if transcription is complete
            if json.status == "completed" {
                guard let text = json.text, !text.isEmpty else {
                    throw TranscriptionError.invalidResponse
                }
                return text
            } else if json.status == "error" {
                throw TranscriptionError.apiError(json.error ?? "Transcription failed")
            }
            
            // Status is "queued" or "processing", wait and retry
            if attempt < maxAttempts {
                try await Task.sleep(nanoseconds: delaySeconds * 1_000_000_000)
            }
        }
        
        throw TranscriptionError.apiError("Transcription timed out")
    }
}

// MARK: - Response Models
struct UploadResponse: Codable {
    let upload_url: String?
}

struct TranscriptResponse: Codable {
    let id: String?
    let status: String?
    let text: String?
    let error: String?
}

struct AssemblyAIError: Codable {
    let error: String?
}

// MARK: - Errors
enum TranscriptionError: LocalizedError {
    case invalidAPIKey
    case failedToReadFile
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid API key. Please check your configuration."
        case .failedToReadFile:
            return "Failed to read audio file"
        case .invalidResponse:
            return "Invalid response from API"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .apiError(let message):
            return message
        }
    }
}
