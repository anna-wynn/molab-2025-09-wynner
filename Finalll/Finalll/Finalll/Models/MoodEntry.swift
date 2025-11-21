//
//  MoodEntry.swift
//  Finalll
//
//  Created for MindEase
//

import Foundation
import FirebaseFirestore

struct MoodEntry: Identifiable, Codable {
    @DocumentID var id: String?
    var timestamp: Date
    var inputType: String // "voice" or "text"
    var transcript: String
    var emotionCategory: String // Happy, Sad, Tired, Scared, Angry, Nervous, Shy, Excited, Bored, Worried, Sick
    var emotionConfidence: Double // 0.0-1.0
    var insight: String
    var moodFlowerColor: String // Hex color
    
    init(
        id: String? = nil,
        timestamp: Date = Date(),
        inputType: String,
        transcript: String,
        emotionCategory: String,
        emotionConfidence: Double,
        insight: String,
        moodFlowerColor: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.inputType = inputType
        self.transcript = transcript
        self.emotionCategory = emotionCategory
        self.emotionConfidence = emotionConfidence
        self.insight = insight
        self.moodFlowerColor = moodFlowerColor
    }
}

// MARK: - Firestore Encoding
extension MoodEntry {
    func toDictionary() -> [String: Any] {
        return [
            "timestamp": Timestamp(date: timestamp),
            "inputType": inputType,
            "transcript": transcript,
            "emotionCategory": emotionCategory,
            "emotionConfidence": emotionConfidence,
            "insight": insight,
            "moodFlowerColor": moodFlowerColor
        ]
    }
    
    static func fromDictionary(_ dictionary: [String: Any], id: String) -> MoodEntry? {
        guard let timestamp = dictionary["timestamp"] as? Timestamp,
              let inputType = dictionary["inputType"] as? String,
              let transcript = dictionary["transcript"] as? String,
              let emotionCategory = dictionary["emotionCategory"] as? String,
              let emotionConfidence = dictionary["emotionConfidence"] as? Double,
              let insight = dictionary["insight"] as? String,
              let moodFlowerColor = dictionary["moodFlowerColor"] as? String else {
            return nil
        }
        
        return MoodEntry(
            id: id,
            timestamp: timestamp.dateValue(),
            inputType: inputType,
            transcript: transcript,
            emotionCategory: emotionCategory,
            emotionConfidence: emotionConfidence,
            insight: insight,
            moodFlowerColor: moodFlowerColor
        )
    }
}

