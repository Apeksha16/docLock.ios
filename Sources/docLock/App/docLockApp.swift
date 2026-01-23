//
//  docLockApp.swift
//  docLock
//
//  Created by Pranav Katiyar on 17/01/26.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn

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
                .onOpenURL { url in
                    // Handle Google Sign-In URL callback
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
