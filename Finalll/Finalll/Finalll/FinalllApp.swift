//
//  FinalllApp.swift
//  Finalll
//
//  Created by Ya Wen Tang on 11/14/25.
//

import SwiftUI
import CoreData
import FirebaseCore
import FirebaseAuth

@main
struct FinalllApp: App {
    let persistenceController = PersistenceController.shared
    
    // StateObject - initialized after Firebase is configured
    @StateObject private var authService = AuthenticationService.shared
    
    init() {
        // Initialize Firebase FIRST - this runs before @StateObject is accessed
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            if authService.isAuthenticated {
                HomeView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            } else {
                LoginView(isPresented: .constant(true))
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
        }
    }
}
