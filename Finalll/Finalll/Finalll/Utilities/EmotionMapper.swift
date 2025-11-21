//
//  EmotionMapper.swift
//  Finalll
//
//  Created for MindEase
//

import Foundation

struct EmotionMapper {
    // Supported emotions
    static let supportedEmotions = [
        "Happy", "Sad", "Tired", "Scared", "Angry",
        "Nervous", "Shy", "Excited", "Bored", "Worried", "Sick"
    ]
    
    // Keyword mappings for emotions
    static let emotionKeywords: [String: [String]] = [
        "Happy": ["happy", "joy", "glad", "cheerful", "pleased", "delighted", "content", "smile", "laugh"],
        "Sad": ["sad", "unhappy", "depressed", "down", "melancholy", "blue", "upset", "cry", "tears"],
        "Tired": ["tired", "exhausted", "sleepy", "fatigued", "worn out", "drained", "weary", "rest"],
        "Scared": ["scared", "afraid", "frightened", "terrified", "fear", "anxious", "worried", "panic"],
        "Angry": ["angry", "mad", "furious", "irritated", "annoyed", "frustrated", "rage", "upset"],
        "Nervous": ["nervous", "anxious", "worried", "uneasy", "jittery", "tense", "apprehensive"],
        "Shy": ["shy", "bashful", "timid", "reserved", "introverted", "self-conscious"],
        "Excited": ["excited", "thrilled", "enthusiastic", "eager", "pumped", "energetic", "upbeat"],
        "Bored": ["bored", "uninterested", "dull", "tedious", "monotonous", "uninspired"],
        "Worried": ["worried", "concerned", "anxious", "troubled", "stressed", "uneasy"],
        "Sick": ["sick", "ill", "unwell", "nauseous", "fever", "ache", "pain", "headache"]
    ]
    
    // Map Hugging Face emotions to our categories
    static func mapHuggingFaceEmotion(_ apiEmotion: String, transcript: String) -> String {
        let lowerTranscript = transcript.lowercased()
        
        // First, check for keyword matches in transcript
        for (emotion, keywords) in emotionKeywords {
            for keyword in keywords {
                if lowerTranscript.contains(keyword) {
                    return emotion
                }
            }
        }
        
        // Map API emotions to our categories
        let apiEmotionLower = apiEmotion.lowercased()
        switch apiEmotionLower {
        case "joy", "happy":
            return "Happy"
        case "sadness", "sad":
            return "Sad"
        case "anger", "angry":
            return "Angry"
        case "fear", "scared":
            return "Scared"
        case "surprise":
            return "Excited" // Map surprise to excited
        case "disgust":
            return "Sick" // Map disgust to sick
        default:
            // Default fallback based on sentiment
            return "Happy" // Safe default
        }
    }
    
    // Map OpenAI emotion classification to our categories
    static func mapOpenAIEmotion(_ emotion: String, transcript: String) -> String {
        let lowerTranscript = transcript.lowercased()
        let emotionLower = emotion.lowercased()
        
        // Check keywords first
        for (emotion, keywords) in emotionKeywords {
            for keyword in keywords {
                if lowerTranscript.contains(keyword) {
                    return emotion
                }
            }
        }
        
        // Direct mapping if emotion matches
        if supportedEmotions.contains(where: { $0.lowercased() == emotionLower }) {
            return emotion.capitalized
        }
        
        // Fallback mappings
        if emotionLower.contains("happy") || emotionLower.contains("joy") {
            return "Happy"
        } else if emotionLower.contains("sad") {
            return "Sad"
        } else if emotionLower.contains("angry") || emotionLower.contains("mad") {
            return "Angry"
        } else if emotionLower.contains("scared") || emotionLower.contains("fear") {
            return "Scared"
        } else if emotionLower.contains("nervous") || emotionLower.contains("anxious") {
            return "Nervous"
        } else if emotionLower.contains("excited") {
            return "Excited"
        } else if emotionLower.contains("tired") || emotionLower.contains("exhausted") {
            return "Tired"
        } else if emotionLower.contains("bored") {
            return "Bored"
        } else if emotionLower.contains("worried") {
            return "Worried"
        } else if emotionLower.contains("sick") || emotionLower.contains("ill") {
            return "Sick"
        } else if emotionLower.contains("shy") {
            return "Shy"
        }
        
        return "Happy" // Default fallback
    }
    
    // Generate insight sentence based on emotion and transcript
    static func generateInsight(emotion: String, transcript: String) -> String {
        let insights: [String: [String]] = [
            "Happy": [
                "You're feeling positive and content today.",
                "Your mood is bright and cheerful.",
                "You seem to be in good spirits."
            ],
            "Sad": [
                "It sounds like you're going through a difficult time.",
                "Your feelings are valid, and it's okay to feel down.",
                "You're experiencing some sadness right now."
            ],
            "Tired": [
                "You seem to need some rest and relaxation.",
                "Your body is telling you to slow down.",
                "You're feeling drained and could use a break."
            ],
            "Scared": [
                "You're feeling anxious or fearful about something.",
                "It's natural to feel scared sometimes.",
                "Your fear is understandable given what you're experiencing."
            ],
            "Angry": [
                "You're feeling frustrated or upset about something.",
                "Your anger is a valid emotional response.",
                "It sounds like something is bothering you."
            ],
            "Nervous": [
                "You're feeling anxious or on edge.",
                "Your nervousness is understandable.",
                "You seem to be feeling tense right now."
            ],
            "Shy": [
                "You're feeling reserved or self-conscious.",
                "It's okay to be quiet and introspective.",
                "You seem to prefer keeping to yourself today."
            ],
            "Excited": [
                "You're feeling energized and enthusiastic!",
                "Your excitement is contagious!",
                "You seem pumped up and ready to go."
            ],
            "Bored": [
                "You're feeling uninterested or uninspired.",
                "It sounds like you need something to engage you.",
                "You seem to be looking for stimulation."
            ],
            "Worried": [
                "You're feeling concerned about something.",
                "Your worries are valid, but try not to let them overwhelm you.",
                "You seem to have a lot on your mind."
            ],
            "Sick": [
                "You're not feeling well physically.",
                "Your body needs care and rest.",
                "It sounds like you're dealing with some physical discomfort."
            ]
        ]
        
        let emotionInsights = insights[emotion] ?? ["You're experiencing \(emotion.lowercased()) feelings today."]
        return emotionInsights.randomElement() ?? "You're feeling \(emotion.lowercased()) today."
    }
    
    // Get color for emotion
    static func getColorForEmotion(_ emotion: String) -> String {
        let colors: [String: String] = [
            "Happy": "#FFD700",      // Yellow
            "Sad": "#4169E1",        // Blue
            "Tired": "#808080",      // Gray
            "Scared": "#9370DB",     // Purple
            "Angry": "#FF4500",      // Red-orange
            "Nervous": "#FF8C00",    // Orange
            "Shy": "#FFB6C1",        // Pink
            "Excited": "#32CD32",    // Green
            "Bored": "#D2B48C",      // Beige/Tan
            "Worried": "#8B4513",     // Brown
            "Sick": "#FF6347"        // Red-orange
        ]
        
        return colors[emotion] ?? "#FFD700" // Default to yellow
    }
}

