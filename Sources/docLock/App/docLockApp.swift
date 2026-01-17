//
//  docLockApp.swift
//  docLock
//
//  Created by Pranav Katiyar on 17/01/26.
//

import SwiftUI
import FirebaseCore

@main
struct docLockApp: App {
    
    init() {
        // Initialize Firebase
        FirebaseApp.configure()
        print("✅ Firebase initialized successfully")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
