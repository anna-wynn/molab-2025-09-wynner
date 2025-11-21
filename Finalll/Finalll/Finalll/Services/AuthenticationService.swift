//
//  AuthenticationService.swift
//  Finalll
//
//  Created for MindEase
//

import Foundation
import Combine
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

@MainActor
class AuthenticationService: ObservableObject {
    static let shared = AuthenticationService()
    
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    
    private lazy var db = Firestore.firestore()
    
    private init() {
        // Listen for auth state changes
        
        // Listen for auth state changes
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.user = user
                self?.isAuthenticated = user != nil
                
                // Create user document if it doesn't exist
                if let user = user {
                    await self?.createUserDocumentIfNeeded(userId: user.uid, email: user.email ?? "")
                }
            }
        }
    }
    
    func signUp(email: String, password: String) async throws {
        do {
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            self.user = authResult.user
            self.isAuthenticated = true
            
            // Create user document in Firestore
            await createUserDocumentIfNeeded(userId: authResult.user.uid, email: email)
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func signIn(email: String, password: String) async throws {
        do {
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            self.user = authResult.user
            self.isAuthenticated = true
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func signOut() throws {
        do {
            try Auth.auth().signOut()
            self.user = nil
            self.isAuthenticated = false
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
    }
    
    private func createUserDocumentIfNeeded(userId: String, email: String) async {
        let userRef = db.collection("users").document(userId)
        
        do {
            let document = try await userRef.getDocument()
            if !document.exists {
                try await userRef.setData([
                    "email": email,
                    "createdAt": Timestamp(date: Date())
                ])
            }
        } catch {
            print("Error creating user document: \(error.localizedDescription)")
        }
    }
}

