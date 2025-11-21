//
//  MoodEntryService.swift
//  Finalll
//
//  Created for MindEase
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class MoodEntryService {
    private let db = Firestore.firestore()
    
    func saveMoodEntry(_ entry: MoodEntry) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw MoodEntryError.userNotAuthenticated
        }
        
        let entryRef = db.collection("users").document(userId).collection("moodEntries").document()
        
        do {
            try await entryRef.setData(entry.toDictionary())
        } catch {
            throw MoodEntryError.saveFailed(error.localizedDescription)
        }
    }
    
    func fetchMoodEntries(limit: Int = 100) async throws -> [MoodEntry] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw MoodEntryError.userNotAuthenticated
        }
        
        let query = db.collection("users")
            .document(userId)
            .collection("moodEntries")
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
        
        let snapshot = try await query.getDocuments()
        
        return snapshot.documents.compactMap { doc in
            MoodEntry.fromDictionary(doc.data(), id: doc.documentID)
        }
    }
    
    func fetchMoodEntries(from startDate: Date, to endDate: Date) async throws -> [MoodEntry] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw MoodEntryError.userNotAuthenticated
        }
        
        let query = db.collection("users")
            .document(userId)
            .collection("moodEntries")
            .whereField("timestamp", isGreaterThanOrEqualTo: Timestamp(date: startDate))
            .whereField("timestamp", isLessThanOrEqualTo: Timestamp(date: endDate))
            .order(by: "timestamp", descending: true)
        
        let snapshot = try await query.getDocuments()
        
        return snapshot.documents.compactMap { doc in
            MoodEntry.fromDictionary(doc.data(), id: doc.documentID)
        }
    }
    
    func deleteMoodEntry(_ entryId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw MoodEntryError.userNotAuthenticated
        }
        
        let entryRef = db.collection("users").document(userId).collection("moodEntries").document(entryId)
        
        do {
            try await entryRef.delete()
        } catch {
            throw MoodEntryError.deleteFailed(error.localizedDescription)
        }
    }
    
    // Real-time listener for mood entries
    func observeMoodEntries(limit: Int = 100, completion: @escaping (Result<[MoodEntry], Error>) -> Void) -> ListenerRegistration? {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(MoodEntryError.userNotAuthenticated))
            return nil
        }
        
        let query = db.collection("users")
            .document(userId)
            .collection("moodEntries")
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
        
        return query.addSnapshotListener { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let snapshot = snapshot else {
                completion(.failure(MoodEntryError.invalidSnapshot))
                return
            }
            
            let entries = snapshot.documents.compactMap { doc in
                MoodEntry.fromDictionary(doc.data(), id: doc.documentID)
            }
            
            completion(.success(entries))
        }
    }
}

// MARK: - Errors
enum MoodEntryError: LocalizedError {
    case userNotAuthenticated
    case saveFailed(String)
    case deleteFailed(String)
    case invalidSnapshot
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User is not authenticated"
        case .saveFailed(let message):
            return "Failed to save mood entry: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete mood entry: \(message)"
        case .invalidSnapshot:
            return "Invalid snapshot from Firestore"
        }
    }
}

