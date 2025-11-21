//
//  EmotionAnalyzer.swift
//  Finalll
//
//  Created for MindEase
//

import Foundation

struct EmotionResult {
    let category: String
    let confidence: Double
    let insight: String
    let color: String
}

class EmotionAnalyzer {
    private let huggingFaceAPIKey: String
    private let openAIAPIKey: String
    private let useHuggingFace: Bool
    
    init(
        huggingFaceAPIKey: String = APIConfiguration.huggingFaceAPIKey,
        useHuggingFace: Bool = true
    ) {
        self.huggingFaceAPIKey = huggingFaceAPIKey
        self.openAIAPIKey = "" // not used
        self.useHuggingFace = useHuggingFace
    }
    
    func analyzeEmotion(from transcript: String) async throws -> EmotionResult {
        if useHuggingFace && !huggingFaceAPIKey.contains("YOUR_") {
            return try await analyzeWithHuggingFace(transcript: transcript)
        } else {
            // Fallback: simple keyword-based analysis
            return analyzeWithKeywords(transcript: transcript)
        }
    }
    
    // MARK: - Hugging Face Analysis
    private func analyzeWithHuggingFace(transcript: String) async throws -> EmotionResult {
        let url = URL(string: "https://api-inference.huggingface.co/models/j-hartmann/emotion-english-distilroberta-base")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(huggingFaceAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["inputs": transcript]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw EmotionAnalysisError.apiError("HTTP error: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        }
        
        // Parse response - Hugging Face returns array of arrays with labels and scores
        guard let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              let firstResult = jsonArray.first,
              let label = firstResult["label"] as? String,
              let score = firstResult["score"] as? Double else {
            throw EmotionAnalysisError.invalidResponse
        }
        
        let emotion = EmotionMapper.mapHuggingFaceEmotion(label, transcript: transcript)
        let insight = EmotionMapper.generateInsight(emotion: emotion, transcript: transcript)
        let color = EmotionMapper.getColorForEmotion(emotion)
        
        return EmotionResult(
            category: emotion,
            confidence: score,
            insight: insight,
            color: color
        )
    }
    
    // MARK: - OpenAI Analysis
    private func analyzeWithOpenAI(transcript: String) async throws -> EmotionResult {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let prompt = """
        Analyze the following text and classify the emotion into ONE of these categories:
        Happy, Sad, Tired, Scared, Angry, Nervous, Shy, Excited, Bored, Worried, Sick
        
        Text: "\(transcript)"
        
        Respond with ONLY the emotion category name, nothing else.
        """
        
        let body: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 10,
            "temperature": 0.3
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw EmotionAnalysisError.apiError("HTTP error: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw EmotionAnalysisError.invalidResponse
        }
        
        let emotion = EmotionMapper.mapOpenAIEmotion(content.trimmingCharacters(in: .whitespacesAndNewlines), transcript: transcript)
        let insight = EmotionMapper.generateInsight(emotion: emotion, transcript: transcript)
        let color = EmotionMapper.getColorForEmotion(emotion)
        
        // Use a default confidence since OpenAI doesn't provide one
        return EmotionResult(
            category: emotion,
            confidence: 0.8,
            insight: insight,
            color: color
        )
    }
    
    // MARK: - Keyword-based Fallback
    private func analyzeWithKeywords(transcript: String) -> EmotionResult {
        let lowerTranscript = transcript.lowercased()
        
        // Score each emotion based on keyword matches
        var emotionScores: [String: Int] = [:]
        
        for (emotion, keywords) in EmotionMapper.emotionKeywords {
            var score = 0
            for keyword in keywords {
                if lowerTranscript.contains(keyword) {
                    score += 1
                }
            }
            emotionScores[emotion] = score
        }
        
        // Find emotion with highest score
        let topEmotion = emotionScores.max(by: { $0.value < $1.value })?.key ?? "Happy"
        let maxScore = emotionScores[topEmotion] ?? 0
        let totalKeywords = EmotionMapper.emotionKeywords[topEmotion]?.count ?? 1
        let confidence = min(Double(maxScore) / Double(totalKeywords), 1.0)
        
        let insight = EmotionMapper.generateInsight(emotion: topEmotion, transcript: transcript)
        let color = EmotionMapper.getColorForEmotion(topEmotion)
        
        return EmotionResult(
            category: topEmotion,
            confidence: max(confidence, 0.5), // Minimum 0.5 confidence for keyword matching
            insight: insight,
            color: color
        )
    }
}

// MARK: - Errors
enum EmotionAnalysisError: LocalizedError {
    case apiError(String)
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .apiError(let message):
            return message
        case .invalidResponse:
            return "Invalid response from emotion analysis API"
        }
    }
}

