import Foundation
import SwiftUI
import UIKit
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import CryptoKit
import Security

class AuthService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isAuthenticated = false
    @Published var user: User?
    @Published var mobileExists: Bool?
    @Published var lockoutDate: Date?
    @Published var isDeviceMismatch = false
    
    private var userListener: ListenerRegistration?
    
    // Services for data sync
    let notificationService = NotificationService()
    let friendsService = FriendsService()
    let documentsService = DocumentsService()
    let cardsService = CardsService()
    let appConfigService = AppConfigService()
    
    init() {
        documentsService.appConfigService = appConfigService
    }
    
    // Base URL from your Cloud Function
    private let baseURL = "https://api-to72oyfxda-uc.a.run.app/api/auth"
    
    // MARK: - Helper Methods
    private func parseErrorMessage(from data: Data?) -> String {
        guard let data = data else {
            return "No error details available"
        }
        
        // Try to decode as ErrorResponse
        if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data),
           let message = errorResponse.message, !message.isEmpty {
            return message
        }
        
        // Try to parse as JSON dictionary manually
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let message = json["message"] as? String, !message.isEmpty {
            return message
        }
        
        // Try to parse as plain string
        if let stringResponse = String(data: data, encoding: .utf8), !stringResponse.isEmpty {
            return stringResponse
        }
        
        return "An error occurred"
    }

    // Helper to propagate profile updates to friends' lists
    private func updateFriendRecords(userId: String, data: [String: Any]) {
        let db = Firestore.firestore()
        print("🔄 updateFriendRecords: Updating friend records for user \(userId) with data: \(data)")
        
        // Query all 'friends' collections where this user is stored
        db.collectionGroup("friends").whereField("uid", isEqualTo: userId).getDocuments { (snapshot, error) in
            if let error = error {
                print("⚠️ Error finding friend records to update: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                print("ℹ️ No friend records found to update for user \(userId)")
                return
            }
            
            print("📝 Found \(documents.count) friend records to update")
            let batch = db.batch()
            // Note: Firestore batch limit is 500.
            for doc in documents {
                batch.updateData(data, forDocument: doc.reference)
                print("  - Updating friend record at: \(doc.reference.path)")
            }
            
            batch.commit { error in
                if let error = error {
                    print("🔴 Error propagating profile updates to friends: \(error.localizedDescription)")
                } else {
                    print("🟢 Successfully propagated profile updates to \(documents.count) friends")
                    // The real-time listeners should automatically pick up these changes
                }
            }
        }
    }

    func login(mobile: String, mpin: String) {
        print("AuthService: login called with mobile: \(mobile)")
        isLoading = true
        errorMessage = nil

        // TODO: Get real Device ID if needed, for now using static or UUID
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown-device-id"
        print("AuthService: Device ID: \(deviceId)")
        
        // Construct Request Body
        let requestBody = LoginRequest(mobile: mobile, mpin: mpin, deviceId: deviceId)
        
        guard let url = URL(string: "\(baseURL)/login") else {
            self.errorMessage = "Invalid URL"
            self.isLoading = false
            print("AuthService: Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0 // 30s timeout

        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
            
            // Log request details
            if let requestBodyString = String(data: request.httpBody!, encoding: .utf8) {
                print("""
                🔵 API REQUEST - LOGIN
                ========================
                URL: \(url.absoluteString)
                Method: POST
                Headers: \(request.allHTTPHeaderFields ?? [:])
                Body: \(requestBodyString)
                ========================
                """)
            }
        } catch {
            self.errorMessage = "Failed to encode request"
            self.isLoading = false
            print("AuthService: Failed to encode request")
            return
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    self?.errorMessage = "Invalid server response"
                    print("""
                    🔴 API RESPONSE - LOGIN (ERROR)
                    ========================
                    Error: Invalid server response
                    ========================
                    """)
                    return
                }

                // Log response details
                if let responseData = data, let responseString = String(data: responseData, encoding: .utf8) {
                    print("""
                    \(httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 ? "🟢" : "🔴") API RESPONSE - LOGIN
                    ========================
                    Status Code: \(httpResponse.statusCode)
                    Headers: \(httpResponse.allHeaderFields)
                    Body: \(responseString)
                    ========================
                    """)
                }

                guard (200...299).contains(httpResponse.statusCode) else {
                    // Parse error message from response body
                    let errorMsg = self?.parseErrorMessage(from: data) ?? "Login failed with status code: \(httpResponse.statusCode)"
                    self?.errorMessage = errorMsg
                    
                    // Check for device mismatch
                    if errorMsg.localizedCaseInsensitiveContains("device") && errorMsg.localizedCaseInsensitiveContains("mismatch") {
                         self?.isDeviceMismatch = true
                    } else {
                         self?.isDeviceMismatch = false
                    }
                    
                    if let data = data, let errorResponse = String(data: data, encoding: .utf8) {
                        print("Error Response: \(errorResponse)")
                    }
                    return
                }

                guard let data = data else {
                    self?.errorMessage = "No data received"
                    return
                }

                do {
                    let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
                    self?.user = loginResponse.user
                    self?.successMessage = loginResponse.message
                    print("✅ Login Successful. API Token received.")
                    
                    // Sign in to Firebase Auth using the custom token
                    Auth.auth().signIn(withCustomToken: loginResponse.token) { authResult, error in
                        if let error = error {
                            print("🔴 Firebase Auth Sign-In Error: \(error.localizedDescription)")
                            self?.errorMessage = "Firebase Authentication Failed: \(error.localizedDescription)"
                            self?.isLoading = false
                            return
                        }
                        
                        print("✅ Firebase Auth Signed In: \(authResult?.user.uid ?? "Unknown UID")")
                        
                        // BLOCKING: Fetch App Config before proceeding
                        self?.appConfigService.fetchConfig { [weak self] success in
                            self?.isLoading = false // Ensure loading is stopped
                            
                            guard success else {
                                self?.errorMessage = "Failed to load application configuration."
                                return
                            }
                            
                            self?.isAuthenticated = true
                            
                            // Trigger Data Sync
                            if let userId = self?.user?.id {
                                 self?.startDataSync(userId: userId)
                            } else if let mobile = self?.user?.mobile {
                                 self?.startDataSync(userId: mobile) 
                            }
                        }
                    }
                    
                    // Consider storing token in Keychain
                } catch {
                    self?.errorMessage = "Failed to decode response"
                    print("❌ Decoding Error: \(error)")
                }
            }
        }.resume()
    }
    
    // MARK: - Verify Mobile (Using Firebase Firestore)
    func verifyMobile(mobile: String, completion: @escaping (Bool, String?) -> Void) {
        print("""
        🔵 FIREBASE VERIFICATION - MOBILE
        ========================
        Mobile: \(mobile)
        Collection: users
        Query: mobile == "\(mobile)"
        ========================
        """)
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        let db = Firestore.firestore()
        
        // Query Firestore to check if mobile number exists
        db.collection("users")
            .whereField("mobile", isEqualTo: mobile)
            .limit(to: 1)
            .getDocuments { [weak self] (querySnapshot, error) in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        print("""
                        🔴 FIREBASE VERIFICATION - ERROR
                        ========================
                        Error: \(error.localizedDescription)
                        ========================
                        """)
                        self?.errorMessage = error.localizedDescription
                        completion(false, error.localizedDescription)
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        print("""
                        🔴 FIREBASE VERIFICATION - ERROR
                        ========================
                        Error: No documents returned
                        ========================
                        """)
                        completion(false, "No documents returned")
                        return
                    }
                    
                    let exists = !documents.isEmpty
                    self?.mobileExists = exists
                    
                    if exists {
                        if let userData = documents.first?.data() {
                            // Check for lockout
                            if let lockoutTimestamp = userData["lockoutUntil"] as? Timestamp {
                                let lockoutDate = lockoutTimestamp.dateValue()
                                if lockoutDate > Date() {
                                    self?.lockoutDate = lockoutDate
                                    let remaining = Int(lockoutDate.timeIntervalSince(Date()))
                                    let message = "Account locked. Try again in \(remaining)s"
                                    self?.errorMessage = message
                                    
                                    // Auto-clear lockout when time expires
                                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(remaining)) { [weak self] in
                                        self?.lockoutDate = nil
                                        self?.errorMessage = nil
                                    }
                                    
                                    print("""
                                    🔴 FIREBASE VERIFICATION - LOCKED
                                    ========================
                                    Lockout until: \(lockoutDate)
                                    Remaining: \(remaining)s
                                    ========================
                                    """)
                                    completion(exists, message)
                                    return
                                } else {
                                    // Lockout expired - Reset in Firestore
                                    print("""
                                    🟡 FIREBASE VERIFICATION - LOCKOUT EXPIRED
                                    ========================
                                    Resetting lockoutUntil and failedAttempts
                                    ========================
                                    """)
                                    documents.first?.reference.updateData([
                                        "lockoutUntil": FieldValue.delete(),
                                        "failedAttempts": 0
                                    ]) { error in
                                        if let error = error {
                                            print("Error clearing lockout: \(error)")
                                        } else {
                                            print("Lockout cleared successfully")
                                        }
                                    }
                                    self?.lockoutDate = nil
                                }
                            } else {
                                self?.lockoutDate = nil
                            }

                            print("""
                            🟢 FIREBASE VERIFICATION - SUCCESS
                            ========================
                            Mobile exists: true
                            User Data: \(userData)
                            ========================
                            """)
                        }
                    } else {
                        print("""
                        🟡 FIREBASE VERIFICATION - NOT FOUND
                        ========================
                        Mobile exists: false
                        Mobile: \(mobile)
                        ========================
                        """)
                    }
                    
                    completion(exists, nil)
                }
            }
    }

    // MARK: - Profile Image Upload
    func uploadProfileImage(image: UIImage, completion: @escaping (Bool, String?) -> Void) {
        guard let userId = user?.uid else {
            completion(false, "User not logged in")
            return
        }

        isLoading = true
        errorMessage = nil
        
        // 1. Compress Image
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            isLoading = false
            completion(false, "Failed to compress image")
            return
        }
        
        let newImageSize = Int64(imageData.count)
        // Update filename to match security rules: userId_...
        let storageRef = Storage.storage().reference().child("profile_images/\(userId)_profile.jpg")
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)

        // 2. Fetch current user data to get old image size (if we were tracking it precisely per file)
        // For now, we will just use the current storageUsed and user/meta to adjust.
        // Better approach: We don't store individual file sizes in User struct usually, but we can query the *old* file metadata from Storage?
        // HOWEVER, to be "interesting" and robust as requested: "first remove the size from total size occupied and then add the size of new image".
        
        // Let's first get the metadata of the *existing* file at that path to know what to subtract.
        // If it doesn't exist, we subtract 0.
        
        storageRef.getMetadata { [weak self] metadata, error in
            var oldImageSize: Int64 = 0
            if let metadata = metadata {
                oldImageSize = metadata.size
                print("Found existing profile image. Size: \(oldImageSize) bytes")
            } else {
                print("No existing profile image found (or error). Assuming 0 bytes.")
            }
            
            // 3. Upload new image
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            storageRef.putData(imageData, metadata: metadata) { [weak self] (metadata, error) in
                guard let self = self else { return }
                
                if let error = error {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    completion(false, error.localizedDescription)
                    return
                }
                
                // 4. Get Download URL
                storageRef.downloadURL { (url, error) in
                    if let error = error {
                        self.isLoading = false
                        self.errorMessage = error.localizedDescription
                        completion(false, error.localizedDescription)
                        return
                    }
                    
                    guard let downloadURL = url?.absoluteString else {
                        self.isLoading = false
                        completion(false, "Failed to get download URL")
                        return
                    }
                    
                    // 5. Update Firestore
                    db.runTransaction({ (transaction, errorPointer) -> Any? in
                        let userDocument: DocumentSnapshot
                        do {
                            try userDocument = transaction.getDocument(userRef)
                        } catch let fetchError as NSError {
                            errorPointer?.pointee = fetchError
                            return nil
                        }
                        
                        // Calculate new storage usage
                        // Note: storageUsed in User model is what we display.
                        // We must read it from the document to be safe in transaction
                        let currentStorage = userDocument.data()?["storageUsed"] as? Int64 ?? 0
                        // Prevent negative storage
                        let adjustedStorage = max(0, currentStorage - oldImageSize)
                        let finalStorage = adjustedStorage + newImageSize
                        
                        transaction.updateData([
                            "profileImageUrl": downloadURL,
                            "storageUsed": finalStorage
                        ], forDocument: userRef)
                        
                        return ["url": downloadURL, "storage": finalStorage]
                    }) { (object, error) in
                        DispatchQueue.main.async {
                            self.isLoading = false
                            if let error = error {
                                self.errorMessage = error.localizedDescription
                                completion(false, error.localizedDescription)
                            } else {
                                // Update local user object manually to reflect changes immediately
                                if let result = object as? [String: Any],
                                   let _ = result["url"] as? String,
                                   let _ = result["storage"] as? Int64 {
                                    
                                    // We need to construct a new User object since it's immutable (let properties)
                                    // Assuming we can re-decode or just partial update if we had a mutable model.
                                    // Since User is struct with 'let', we can't modify it in place.
                                    // We'll rely on fetching or just trust the UI updates if we bind to specific fields?
                                    // But 'user' is @Published. We should update it.
                                    // Actually, User struct has `let` properties.
                                    // We might need to make them `var` or create a new instance using the old values + new ones.
                                    // For now, let's try to create a new User instance.
                                    if self.user != nil {
                                        // This is a bit hacky d/t Decodable usually init from JSON.
                                        // But we can't easily init 'User' if it doesn't have a public init.
                                        // Let's assume User has a memberwise init auto-generated internal.
                                        // Wait, 'User' is in another file. If it doesn't have explicit init, internal is available if in same module.
                                        // They are in same module 'docLock'.
                                        // Let's check User.swift again. It's a simple struct.
                                        // We can do:
                                        // self.user = User(uid: currentUser.uid, mobile: currentUser.mobile, name: currentUser.name, profileImageUrl: newUrl, storageUsed: newStorage)
                                        // But we need to make sure we have access to memberwise init.
                                        // Let's assume yes.
                                    
                                        // Actually better: We can re-fetch the user profile to be 100% in sync.
                                        // But that calls an API.
                                        // Let's try to update local state if possible later.
                                    }
                                    
                                    // For "Real-time", if we have a listener on 'user' doc that would be best.
                                    // But currently we don't seem to have a realtime listener for the User profile itself?
                                    // We check "verifyMobile" which gets a snapshot.
                                    // Let's add a quick re-fetch or listener if we want instant update.
                                }
                                
                                // Since we don't have a direct 'update local user' way without Init, 
                                // I will trigger a fresh fetch of the user config/profile or just 'verifyMobile' logic 
                                // or better: Just create a simple update function or just tell UI to reload?
                                // Let's just return success for now.
                                // Trigger Notification
                                NotificationService.send(
                                    to: userId,
                                    title: "Profile Updated",
                                    message: "You successfully updated your profile picture.",
                                    type: "security"
                                )
                                
                                completion(true, downloadURL)
                                
                                // Propagate changes to friends' lists
                                self.updateFriendRecords(userId: userId, data: ["profileImageUrl": downloadURL])
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Signup
    func signup(mobile: String, mpin: String, name: String) {
        print("AuthService: signup called with mobile: \(mobile), name: \(name)")
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown-device-id"
        let requestBody = SignupRequest(mobile: mobile, mpin: mpin, name: name, deviceId: deviceId)
        
        guard let url = URL(string: "\(baseURL)/register") else {
            self.errorMessage = "Invalid URL"
            self.isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0 // 30s timeout
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
            
            // Log request details
            if let requestBodyString = String(data: request.httpBody!, encoding: .utf8) {
                print("""
                🔵 API REQUEST - SIGNUP
                ========================
                URL: \(url.absoluteString)
                Method: POST
                Headers: \(request.allHTTPHeaderFields ?? [:])
                Body: \(requestBodyString)
                ========================
                """)
            }
        } catch {
            self.errorMessage = "Failed to encode request"
            self.isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    print("""
                    🔴 API RESPONSE - SIGNUP (ERROR)
                    ========================
                    Error: \(error.localizedDescription)
                    ========================
                    """)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self?.errorMessage = "Invalid server response"
                    print("""
                    🔴 API RESPONSE - SIGNUP (ERROR)
                    ========================
                    Error: Invalid server response
                    ========================
                    """)
                    return
                }
                
                // Log response details
                if let responseData = data, let responseString = String(data: responseData, encoding: .utf8) {
                    print("""
                    \(httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 ? "🟢" : "🔴") API RESPONSE - SIGNUP
                    ========================
                    Status Code: \(httpResponse.statusCode)
                    Headers: \(httpResponse.allHeaderFields)
                    Body: \(responseString)
                    ========================
                    """)
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    // Parse error message from response body
                    let errorMsg = self?.parseErrorMessage(from: data) ?? "Signup failed with status code: \(httpResponse.statusCode)"
                    self?.errorMessage = errorMsg
                    if let data = data, let errorResponse = String(data: data, encoding: .utf8) {
                        print("Error Response: \(errorResponse)")
                    }
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No data received"
                    return
                }
                
                do {
                    let signupResponse = try JSONDecoder().decode(SignupResponse.self, from: data)
                    self?.user = signupResponse.user
                    self?.successMessage = signupResponse.message
                    print("✅ Signup Successful. API Token received.")
                    
                    // Sign in to Firebase Auth using the custom token
                    Auth.auth().signIn(withCustomToken: signupResponse.token) { authResult, error in
                        if let error = error {
                            print("🔴 Firebase Auth Sign-In Error: \(error.localizedDescription)")
                            self?.errorMessage = "Firebase Authentication Failed: \(error.localizedDescription)"
                            self?.isLoading = false
                            return
                        }
                        
                        print("✅ Firebase Auth Signed In: \(authResult?.user.uid ?? "Unknown UID")")
                        
                        // BLOCKING: Fetch App Config
                        self?.appConfigService.fetchConfig { [weak self] success in
                            self?.isLoading = false // Ensure loading is stopped
                            
                            guard success else {
                                self?.errorMessage = "Failed to load application configuration."
                                return
                            }
                            
                            self?.isAuthenticated = true

                            // Trigger Data Sync
                            if let userId = self?.user?.id {
                                 self?.startDataSync(userId: userId)
                            } else if let mobile = self?.user?.mobile {
                                 self?.startDataSync(userId: mobile)
                            }
                        }
                    }
                    
                } catch {
                    self?.errorMessage = "Failed to decode response"
                    print("❌ Decoding Error: \(error)")
                }
            }
        }.resume()
    }
    
    // MARK: - Update MPIN
    func updateMPIN(mpin: String, completion: @escaping (Bool, String?) -> Void) {
        guard let _ = user else {
            completion(false, "User not logged in")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Get ID Token for Authorization
        let currentUser = Auth.auth().currentUser
        currentUser?.getIDToken(completion: { [weak self] token, error in
            guard let self = self else { return }
            
            if let error = error {
                self.isLoading = false
                self.errorMessage = "Failed to get auth token: \(error.localizedDescription)"
                completion(false, error.localizedDescription)
                return
            }
            
            guard let token = token else {
                self.isLoading = false
                self.errorMessage = "Failed to get auth token"
                completion(false, "Failed to get auth token")
                return
            }
            
            // Prepare Request
            let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown-device-id"
            let requestBody: [String: String] = ["mpin": mpin, "deviceId": deviceId]
            
            guard let url = URL(string: "\(self.baseURL)/update-mpin") else {
                self.isLoading = false
                self.errorMessage = "Invalid URL"
                completion(false, "Invalid URL")
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
                 // Log request details
                 if let requestBodyString = String(data: request.httpBody!, encoding: .utf8) {
                     print("""
                     🔵 API REQUEST - UPDATE MPIN
                     ========================
                     URL: \(url.absoluteString)
                     Method: POST
                     Body: \(requestBodyString)
                     ========================
                     """)
                 }
            } catch {
                self.isLoading = false
                self.errorMessage = "Failed to encode request"
                completion(false, "Failed to encode request")
                return
            }
            
            URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        completion(false, error.localizedDescription)
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        self?.errorMessage = "Invalid server response"
                        completion(false, "Invalid server response")
                        return
                    }
                    
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        print("""
                        \(httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 ? "🟢" : "🔴") API RESPONSE - UPDATE MPIN
                        ========================
                        Status: \(httpResponse.statusCode)
                        Body: \(responseString)
                        ========================
                        """)
                    }
                    
                    if (200...299).contains(httpResponse.statusCode) {
                        // Trigger Notification
                        if let userId = self?.user?.uid {
                            NotificationService.send(
                                to: userId,
                                title: "Security Update",
                                message: "Your MPIN was successfully changed.",
                                type: "security"
                            )
                        }
                        
                        completion(true, nil)
                    } else {
                        let errorMsg = self?.parseErrorMessage(from: data) ?? "Update failed"
                        self?.errorMessage = errorMsg
                        completion(false, errorMsg)
                    }
                }
            }.resume()
        })
    }

    // MARK: - Update Name
    func updateName(name: String, completion: @escaping (Bool, String?) -> Void) {
        guard let userId = user?.uid else {
            completion(false, "User not logged in")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        userRef.updateData(["name": name]) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(false, error.localizedDescription)
                } else {
                    // Update local user object
                    if self?.user != nil {
                        // Create a new User object with updated name
                        // We need to use the initializer we'll add extension for or just structural init if internal
                        // Assuming structural init is available since it's a simple struct
                        // We'll trust fetchUserProfile to eventually sync, but for immediate UI:
                        // Trigger fetch to be safe and clean
                        self?.fetchUserProfile(userId: userId)
                    }
                    completion(true, nil)
                    
                    // Propagate changes to friends' lists
                    self?.updateFriendRecords(userId: userId, data: ["name": name])
                    
                    // Trigger Notification
                    NotificationService.send(
                        to: userId,
                        title: "Profile Updated",
                        message: "Your display name has been updated.",
                        type: "security"
                    )
                }
            }
        }
    }

    // MARK: - Fetch User Profile
    func fetchUserProfile(userId: String) {
        userListener?.remove() // Remove existing listener if any
        
        let db = Firestore.firestore()
        userListener = db.collection("users").document(userId).addSnapshotListener { [weak self] snapshot, error in
            DispatchQueue.main.async {
                if let data = snapshot?.data() {
                    let mobile = data["mobile"] as? String
                    let name = data["name"] as? String ?? "User"
                    let profileImageUrl = data["profileImageUrl"] as? String
                    let storageUsed = data["storageUsed"] as? Int64
                    
                    // Manually create User object to avoid JSON/Timestamp serialization issues
                    let updatedUser = User(
                        uid: userId,
                        mobile: mobile,
                        name: name,
                        profileImageUrl: profileImageUrl,
                        storageUsed: storageUsed,
                        addedAt: nil, // Self doesn't have an addedAt date
                        sharedCardsCount: (data["sharedCardsCount"] as? NSNumber)?.intValue,
                        sharedDocsCount: (data["sharedDocsCount"] as? NSNumber)?.intValue
                    )
                    
                    self?.user = updatedUser
                    print("✅ User Profile Synced: \(updatedUser.name), Mobile: \(updatedUser.mobile ?? "nil")")
                } else if let error = error {
                    print("🔴 Error listening to user profile: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Data Sync
    private func startDataSync(userId: String) {
        print("🚀 Starting Parallel Data Sync for User: \(userId)")
        
        // Also sync profile data to ensure we have latest mobile/image
        fetchUserProfile(userId: userId)
        
        // Execute in parallel (async but non-blocking to main thread)
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            let group = DispatchGroup()
            
            group.enter()
            DispatchQueue.main.async {
                self.notificationService.startListening(userId: userId)
                group.leave()
            }
            
            group.enter()
            DispatchQueue.main.async {
                self.friendsService.startListening(userId: userId)
                group.leave()
            }
            
            group.enter()
            DispatchQueue.main.async {
                self.documentsService.startListening(userId: userId)
                group.leave()
            }
            
            group.enter()
            DispatchQueue.main.async {
                self.cardsService.startListening(userId: userId)
                group.leave()
            }
        }
    }
}
import Foundation
import FirebaseFirestore
import SwiftUI
import Combine

// MARK: - Notifications
// MARK: - Notifications
class NotificationService: ObservableObject {
    @Published var notifications: [NotificationItem] = []
    @Published var error: String?
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()
    
    func startListening(userId: String) {
        // Prevent duplicate listeners
        listener?.remove()
        
        print("🔔 NotificationService: Starting listener for user \(userId)")
        
        listener = db.collection("users").document(userId).collection("notifications")
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("🔴 NotificationService Error: \(error.localizedDescription)")
                    self?.error = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("⚠️ NotificationService: No documents found")
                    return
                }
                
                self?.notifications = documents.compactMap { doc -> NotificationItem? in
                    let data = doc.data()
                    guard let title = data["title"] as? String,
                          let message = data["message"] as? String,
                          let typeString = data["type"] as? String else { return nil }
                    
                    let type: NotificationType = (typeString == "security") ? .security : .alert
                    let date = data["date"] as? String ?? ""
                    let isRead = data["isRead"] as? Bool ?? false
                    let requestType = data["requestType"] as? String
                    let senderId = data["senderId"] as? String
                    
                    return NotificationItem(id: doc.documentID, type: type, title: title, message: message, date: date, isRead: isRead, requestType: requestType, senderId: senderId)
                }
                self?.error = nil // Clear error on success
                print("🟢 NotificationService: Synced \(self?.notifications.count ?? 0) items")
            }
    }
    
    func addNotification(userId: String, title: String, message: String, type: String = "alert", completion: ((Error?) -> Void)? = nil) {
        // Simple date formatter for display sorting if needed, or use timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, h:mm a"
        let dateString = dateFormatter.string(from: Date())
        
        let data: [String: Any] = [
            "title": title,
            "message": message,
            "type": type,
            "date": dateString,
            "isRead": false,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("users").document(userId).collection("notifications").addDocument(data: data) { error in
            if let error = error {
                print("🔴 NotificationService: Error adding notification: \(error.localizedDescription)")
            } else {
                print("🟢 NotificationService: Notification added")
            }
            completion?(error)
        }
    }
    
    func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    func retry(userId: String) {
        if error != nil {
            print("🔄 NotificationService: Retrying...")
            startListening(userId: userId)
        }
    }
    
    // MARK: - Actions
    func delete(id: String, userId: String) {
        print("🗑️ NotificationService: Deleting notification \(id)")
        db.collection("users").document(userId).collection("notifications").document(id).delete { error in
            if let error = error {
                print("🔴 Error deleting notification: \(error.localizedDescription)")
            }
        }
    }
    
    func markAsRead(id: String, userId: String) {
        print("👀 NotificationService: Marking notification \(id) as read")
        db.collection("users").document(userId).collection("notifications").document(id).updateData(["isRead": true]) { error in
            if let error = error {
                print("🔴 Error marking notification as read: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Sending Notifications
    static func send(to userId: String, title: String, message: String, type: String, senderId: String? = nil, senderName: String? = nil, requestType: String? = nil) {
        let db = Firestore.firestore()
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short)
        
        var data: [String: Any] = [
            "title": title,
            "message": message,
            "type": type,
            "date": timestamp,
            "isRead": false,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        if let senderId = senderId { data["senderId"] = senderId }
        // if let senderName = senderName { data["senderName"] = senderName }
        if let requestType = requestType { data["requestType"] = requestType }
        
        db.collection("users").document(userId).collection("notifications").addDocument(data: data) { error in
            if let error = error {
                print("🔴 NotificationService Send Error: \(error.localizedDescription)")
            }
        }
    }
}


// MARK: - Friends
class FriendsService: ObservableObject {
    // Ideally use a FriendModel, but for now using a simple structure or just count check
    @Published var friendsCount: Int = 0
    @Published var friends: [User] = []
    @Published var error: String?
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()
    
    func startListening(userId: String) {
        listener?.remove()
        print("👥 FriendsService: Starting listener for user \(userId)")
        
        listener = db.collection("users").document(userId).collection("friends")
            .order(by: "addedAt", descending: true)
            .addSnapshotListener(includeMetadataChanges: true) { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("🔴 FriendsService Error: \(error.localizedDescription)")
                        self?.error = error.localizedDescription
                        return
                    }
                    
                    guard let documents = snapshot?.documents else { return }
                    
                    self?.friendsCount = documents.count
                    self?.friends = documents.compactMap { doc -> User? in
                        return self?.mapDataToUser(uid: doc.documentID, data: doc.data())
                    }
                    
                    self?.error = nil
                    print("🟢 FriendsService: Synced \(documents.count) friends")
                }
            }
    }
    
    func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    // ... retry ... (keep existing)
    func retry(userId: String) {
        if error != nil {
            print("🔄 FriendsService: Retrying...")
            startListening(userId: userId)
        }
    }

    // ... searchUser ... (keep existing)
    func searchUser(query: String, completion: @escaping (User?, String?) -> Void) {
        print("🔍 FriendsService: Searching for \(query)")
        
        let usersRef = db.collection("users")
        
        let isMobile = query.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil && query.count > 6
        
        var queryObj: Query?
        
        if isMobile {
            queryObj = usersRef.whereField("mobile", isEqualTo: query).limit(to: 1)
        } else {
             // Assume it's a UID
             let docRef = usersRef.document(query)
             docRef.getDocument { (snapshot, error) in
                 if let error = error {
                     completion(nil, error.localizedDescription)
                     return
                 }
                 
                 if let snapshot = snapshot, snapshot.exists, let data = snapshot.data() {
                    let user = self.mapDataToUser(uid: snapshot.documentID, data: data)
                    completion(user, nil)
                 } else {
                     completion(nil, "User not found")
                 }
             }
             return
        }
        
        queryObj?.getDocuments { (snapshot, error) in
            if let error = error {
                completion(nil, error.localizedDescription)
                return
            }
            
            if let document = snapshot?.documents.first {
                let user = self.mapDataToUser(uid: document.documentID, data: document.data())
                completion(user, nil)
            } else {
                completion(nil, "User not found")
            }
        }
    }
    
    // MARK: - Request Feature
    func sendRequest(fromUser: User, toFriend friend: User, requestType: String, message: String, completion: @escaping (Bool) -> Void) {
        
        // Notify Friend
        NotificationService.send(
            to: friend.uid,
            title: "Request from \(fromUser.name)",
            message: message,
            type: "alert",
            senderId: fromUser.uid,
            requestType: requestType
        )
        
        // Notify Sender
        NotificationService.send(
            to: fromUser.uid,
            title: "Request Sent",
            message: "You requested \(requestType == "card" ? "a card" : "a document") from \(friend.name).",
            type: "security"
        )
        
        // Assuming success for async "fire and forget" notification or should we wait?
        // Original code waited for friend's notification addDocument callback.
        // NotificationService.send is fire-and-forget (void return).
        // I will just complete(true) for UX speed.
        print("✅ Requests queued for notifications")
        completion(true)
    }
    
    // ... addFriend ... (keep existing)
    func addFriend(currentUser: User, friend: User, completion: @escaping (Bool, String?) -> Void) {
        print("➕ FriendsService: Adding friend \(friend.name)")
        
        // Use batch write to ensure both updates succeed or fail together
        let batch = db.batch()
        
        // 1. Add friend to current user's list
        let currentUserFriendRef = db.collection("users").document(currentUser.uid).collection("friends").document(friend.uid)
        let currentUserFriendData: [String: Any] = [
            "uid": friend.uid,
            "name": friend.name,
            "mobile": friend.mobile ?? "",
            "profileImageUrl": friend.profileImageUrl ?? "",
            "addedAt": FieldValue.serverTimestamp()
        ]
        batch.setData(currentUserFriendData, forDocument: currentUserFriendRef)
        
        // 2. Add current user to friend's list (bidirectional friendship)
        let friendUserFriendRef = db.collection("users").document(friend.uid).collection("friends").document(currentUser.uid)
        let friendUserFriendData: [String: Any] = [
            "uid": currentUser.uid,
            "name": currentUser.name,
            "mobile": currentUser.mobile ?? "",
            "profileImageUrl": currentUser.profileImageUrl ?? "",
            "addedAt": FieldValue.serverTimestamp()
        ]
        batch.setData(friendUserFriendData, forDocument: friendUserFriendRef)
        
        // Commit batch
        batch.commit { error in
            if let error = error {
                print("🔴 FriendsService: Batch commit error: \(error.localizedDescription)")
                completion(false, error.localizedDescription)
            } else {
                print("✅ FriendsService: Successfully added bidirectional friendship")
                
                // Notify Sender
                NotificationService.send(
                    to: currentUser.uid,
                    title: "Friend Added",
                    message: "You added \(friend.name) to your secure circle.",
                    type: "security"
                )
                
                // Notify Friend
                NotificationService.send(
                    to: friend.uid,
                    title: "New Connection",
                    message: "\(currentUser.name) added you to their secure circle.",
                    type: "alert",
                    senderId: currentUser.uid
                )
                
                completion(true, nil)
            }
        }
    }
    
    // NEW: Delete Friend
    func deleteFriend(currentUser: User, friend: User) {
        print("➖ FriendsService: Deleting friend \(friend.uid)")
        
        // Use batch write to ensure both deletions succeed or fail together
        let batch = db.batch()
        
        // 1. Remove friend from current user's list
        let currentUserFriendRef = db.collection("users").document(currentUser.uid).collection("friends").document(friend.uid)
        batch.deleteDocument(currentUserFriendRef)
        
        // 2. Remove current user from friend's list (bidirectional removal)
        let friendUserFriendRef = db.collection("users").document(friend.uid).collection("friends").document(currentUser.uid)
        batch.deleteDocument(friendUserFriendRef)
        
        // Commit batch
        batch.commit { [weak self] error in
            if let error = error {
                print("🔴 Error removing friend: \(error.localizedDescription)")
                self?.error = "Failed to remove friend"
            } else {
                print("✅ FriendsService: Successfully removed bidirectional friendship")
                
                // Notifications
                
                // Notify Sender
                NotificationService.send(
                    to: currentUser.uid,
                    title: "Friend Removed",
                    message: "You removed \(friend.name) from your trusted circle.",
                    type: "security"
                )
                
                // Notify Friend
                NotificationService.send(
                    to: friend.uid,
                    title: "Access Revoked",
                    message: "\(currentUser.name) removed you from their trusted circle.",
                    type: "security",
                    senderId: currentUser.uid
                )
            }
        }
    }
    
    // Helper to map dictionary to User struct
    private func mapDataToUser(uid: String, data: [String: Any]) -> User {
        let timestamp = data["addedAt"] as? Timestamp
        let date = timestamp?.dateValue()
        
        return User(
            uid: uid,
            mobile: data["mobile"] as? String,
            name: data["name"] as? String ?? "Unknown",
            profileImageUrl: data["profileImageUrl"] as? String,
            storageUsed: data["storageUsed"] as? Int64,
            addedAt: date,
            sharedCardsCount: (data["sharedCardsCount"] as? NSNumber)?.intValue,
            sharedDocsCount: (data["sharedDocsCount"] as? NSNumber)?.intValue
        )
    }
}

// MARK: - Documents
class DocumentsService: ObservableObject {
    @Published var folders: [DocFolder] = []
    @Published var currentFolderDocuments: [DocumentFile] = []
    @Published var currentFolderFolders: [DocFolder] = []
    @Published var isFetchingDocuments = false
    @Published var isFetchingFolders = false
    
    var isLoading: Bool {
        return isFetchingDocuments || isFetchingFolders
    }
    @Published var totalDocuments: Int = 0
    @Published var usedStorageMB: Double = 0.0
    @Published var sharedDocsCount: Int = 0
    @Published var error: String?
    
    var appConfigService: AppConfigService?
    
    private var listener: ListenerRegistration?
    private var userListener: ListenerRegistration?
    private var folderDocumentsListener: ListenerRegistration?
    private var folderFoldersListener: ListenerRegistration?
    private let db = Firestore.firestore()
    
    func startListening(userId: String, parentFolderId: String? = nil) {
        listener?.remove()
        userListener?.remove()
        print("📄 DocumentsService: Starting listener for user \(userId), parentFolderId: \(parentFolderId ?? "root")")
        
        // Listen to User Document for sharedDocsCount
        userListener = db.collection("users").document(userId).addSnapshotListener { [weak self] snapshot, error in
            guard let data = snapshot?.data() else { return }
            self?.sharedDocsCount = (data["sharedDocsCount"] as? NSNumber)?.intValue ?? 0
        }
        
        // Listening to folders filtered by parentFolderId
        let collectionRef = db.collection("users").document(userId).collection("folders")
        let query: Query
        
        if let parentId = parentFolderId {
            query = collectionRef.whereField("parentFolderId", isEqualTo: parentId)
        } else {
            query = collectionRef.whereField("parentFolderId", isEqualTo: NSNull())
        }
        
        listener = query.addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("🔴 DocumentsService Error: \(error.localizedDescription)")
                    self?.error = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self?.folders = documents.compactMap { doc -> DocFolder? in
                    let data = doc.data()
                    let name = data["name"] as? String ?? "Unnamed"
                    let itemCount = data["itemCount"] as? Int ?? 0
                    let icon = data["icon"] as? String ?? "folder"
                    let parentFolderId = data["parentFolderId"] as? String
                    let depth = data["depth"] as? Int ?? 0
                    return DocFolder(id: doc.documentID, name: name, itemCount: itemCount, icon: icon, parentFolderId: parentFolderId, depth: depth)
                }
                
                // Calculate totals from folders (itemCounts) - this is approximate
                // Real count will be updated by updateStorageSize
                // Note: folderItemCount calculation removed as it's not used
                
                // Update storage size in background (non-blocking) - this will also update totalDocuments accurately
                DispatchQueue.global(qos: .utility).async {
                    self?.updateStorageSize(userId: userId, fileSize: 0, isAdd: false)
                } 
                
                self?.error = nil
                print("🟢 DocumentsService: Synced \(self?.folders.count ?? 0) folders")
            }
    }
    
    func stopListening() {
        listener?.remove()
        userListener?.remove()
        listener = nil
        userListener = nil
    }
    
    func retry(userId: String) {
        if error != nil {
            print("🔄 DocumentsService: Retrying...")
            startListening(userId: userId)
        }
    }
    
    // MARK: - Fetch Documents in Folder
    func fetchDocumentsInFolder(userId: String, folderId: String?) {
        folderDocumentsListener?.remove()
        print("📂 DocumentsService: Fetching documents in folder \(folderId ?? "root")")
        
        let collectionRef = db.collection("users").document(userId).collection("documents")
        let query: Query
        
        if let folderId = folderId {
            if folderId == "SHARED_ROOT" {
                 // Fetch all shared documents (no folderId constraint, but isShared == true)
                 query = collectionRef.whereField("isShared", isEqualTo: true)
            } else {
                query = collectionRef.whereField("folderId", isEqualTo: folderId)
            }
        } else {
            // Root - verify we are not showing shared docs here unless we want them mixed (user asked for separate folder)
            // For now, exclude shared docs from root if possible, or just filter by folderId == null which handles it
             query = collectionRef.whereField("folderId", isEqualTo: NSNull())
        }
        
        isFetchingDocuments = true
        folderDocumentsListener = query.order(by: "createdAt", descending: true)
            .addSnapshotListener(includeMetadataChanges: true) { [weak self] snapshot, error in
                self?.isFetchingDocuments = false
                if let error = error {
                    print("🔴 DocumentsService Folder Documents Error: \(error.localizedDescription)")
                    self?.error = error.localizedDescription
                    return
                }
                
                guard let snapshot = snapshot else {
                    print("⚠️ DocumentsService: No snapshot received")
                    DispatchQueue.main.async {
                        self?.currentFolderDocuments = []
                    }
                    return
                }
                
                // Log snapshot information
                print("📂 DocumentsService: Snapshot received - \(snapshot.documents.count) documents, \(snapshot.documentChanges.count) changes (fromCache: \(snapshot.metadata.isFromCache), hasPendingWrites: \(snapshot.metadata.hasPendingWrites))")
                
                // Log document changes for debugging
                for change in snapshot.documentChanges {
                    let doc = change.document
                    let data = doc.data()
                    let name = data["name"] as? String ?? "Unnamed"
                    switch change.type {
                    case .added:
                        print("➕ DocumentsService: Document added - ID: \(doc.documentID), Name: \(name)")
                    case .modified:
                        print("✏️ DocumentsService: Document modified - ID: \(doc.documentID), Name: \(name)")
                    case .removed:
                        print("🗑️ DocumentsService: Document removed - ID: \(doc.documentID), Name: \(name)")
                    }
                }
                
                let documents = snapshot.documents.compactMap { doc -> DocumentFile? in
                    let data = doc.data()
                    let name = data["name"] as? String ?? "Unnamed"
                    let type = data["type"] as? String ?? "document"
                    let url = data["url"] as? String ?? ""
                    let size = data["size"] as? Int ?? 0
                    let timestamp = data["createdAt"] as? Timestamp
                    let createdAt = timestamp?.dateValue()
                    
                    let isShared = data["isShared"] as? Bool ?? false
                    let sharedBy = data["sharedBy"] as? String
                    let sharedByName = data["sharedByName"] as? String
                    
                    return DocumentFile(
                        id: doc.documentID,
                        name: name,
                        type: type,
                        url: url,
                        size: size,
                        createdAt: createdAt,
                        isShared: isShared,
                        sharedBy: sharedBy,
                        sharedByName: sharedByName
                    )
                }
                
                DispatchQueue.main.async {
                    self?.currentFolderDocuments = documents
                    print("🟢 DocumentsService: Updated \(documents.count) documents in folder (UI updated on main thread)")
                }
            }
    }
    
    // MARK: - Fetch Folders in Folder
    func fetchFoldersInFolder(userId: String, parentFolderId: String?) {
        folderFoldersListener?.remove()
        print("📁 DocumentsService: Fetching folders in parent \(parentFolderId ?? "root")")
        
        let collectionRef = db.collection("users").document(userId).collection("folders")
        let query: Query
        
        if let parentId = parentFolderId {
            query = collectionRef.whereField("parentFolderId", isEqualTo: parentId)
        } else {
            query = collectionRef.whereField("parentFolderId", isEqualTo: NSNull())
        }
        
        isFetchingFolders = true
        folderFoldersListener = query.addSnapshotListener { [weak self] snapshot, error in
            self?.isFetchingFolders = false
            if let error = error {
                print("🔴 DocumentsService Folder Folders Error: \(error.localizedDescription)")
                self?.error = error.localizedDescription
                return
            }
            
            guard let documents = snapshot?.documents else {
                self?.currentFolderFolders = []
                return
            }
            
            self?.currentFolderFolders = documents.compactMap { doc -> DocFolder? in
                let data = doc.data()
                let name = data["name"] as? String ?? "Unnamed"
                let itemCount = data["itemCount"] as? Int ?? 0
                let icon = data["icon"] as? String ?? "folder"
                let parentFolderId = data["parentFolderId"] as? String
                let depth = data["depth"] as? Int ?? 0
                return DocFolder(id: doc.documentID, name: name, itemCount: itemCount, icon: icon, parentFolderId: parentFolderId, depth: depth)
            }
            
            print("🟢 DocumentsService: Loaded \(self?.currentFolderFolders.count ?? 0) folders in parent")
        }
    }
    
    func stopListeningToFolder() {
        folderDocumentsListener?.remove()
        folderFoldersListener?.remove()
        folderDocumentsListener = nil
        folderFoldersListener = nil
        currentFolderDocuments = []
        currentFolderFolders = []
    }
    
    // MARK: - Create Folder
    func createFolder(userId: String, folderName: String, parentFolderId: String?, parentDepth: Int, maxDepth: Int, completion: @escaping (Bool, String?) -> Void) {
        print("📁 DocumentsService: Creating folder '\(folderName)' for user \(userId), parent: \(parentFolderId ?? "root")")
        
        // First, get the actual parent folder depth from Firestore to verify nesting limit
        if let parentId = parentFolderId {
            // Fetch parent folder to get its actual depth
            db.collection("users").document(userId).collection("folders").document(parentId).getDocument { [weak self] snapshot, error in
                guard let self = self else {
                    completion(false, "Service unavailable")
                    return
                }
                
                if let error = error {
                    print("🔴 DocumentsService: Error fetching parent folder: \(error.localizedDescription)")
                    completion(false, "Failed to verify folder depth: \(error.localizedDescription)")
                    return
                }
                
                guard let data = snapshot?.data() else {
                    completion(false, "Parent folder not found")
                    return
                }
                
                let actualParentDepth = data["depth"] as? Int ?? 0
                let newDepth = actualParentDepth + 1
                
                print("📁 DocumentsService: Parent folder depth: \(actualParentDepth), new folder depth will be: \(newDepth), maxDepth: \(maxDepth)")
                
                // Check depth limit based on actual parent depth
                if newDepth >= maxDepth {
                    completion(false, "Maximum folder nesting depth (\(maxDepth)) reached. Cannot create folder at this level.")
                    return
                }
                
                // Proceed with folder creation
                self.createFolderWithDepth(userId: userId, folderName: folderName, parentFolderId: parentId, depth: newDepth, completion: completion)
            }
        } else {
            // Root level folder - depth will be 0
            let newDepth = 0
            print("📁 DocumentsService: Creating root folder, depth: \(newDepth), maxDepth: \(maxDepth)")
            
            if newDepth >= maxDepth {
                completion(false, "Maximum folder nesting depth (\(maxDepth)) reached")
                return
            }
            
            createFolderWithDepth(userId: userId, folderName: folderName, parentFolderId: nil, depth: newDepth, completion: completion)
        }
    }
    
    // MARK: - Create Folder With Depth (Internal helper)
    private func createFolderWithDepth(userId: String, folderName: String, parentFolderId: String?, depth: Int, completion: @escaping (Bool, String?) -> Void) {
        var data: [String: Any] = [
            "name": folderName,
            "itemCount": 0,
            "icon": "folder",
            "depth": depth,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        if let parentId = parentFolderId {
            data["parentFolderId"] = parentId
        } else {
            data["parentFolderId"] = NSNull()
        }
        
        db.collection("users").document(userId).collection("folders").addDocument(data: data) { [weak self] error in
            if let error = error {
                print("🔴 DocumentsService Create Folder Error: \(error.localizedDescription)")
                completion(false, error.localizedDescription)
            } else {
                print("🟢 DocumentsService: Folder '\(folderName)' created successfully at depth \(depth)")
                
                // Update parent folder itemCount in background (non-blocking)
                if let parentId = parentFolderId {
                    DispatchQueue.global(qos: .utility).async {
                        self?.updateFolderItemCount(userId: userId, folderId: parentId)
                    }
                }
                
                completion(true, nil)
            }
        }
    }
    
    // MARK: - Edit Folder
    func updateFolder(userId: String, folderId: String, newName: String, completion: @escaping (Bool, String?) -> Void) {
        print("✏️ DocumentsService: Updating folder \(folderId) to '\(newName)'")
        
        db.collection("users").document(userId).collection("folders").document(folderId).updateData([
            "name": newName
        ]) { error in
            if let error = error {
                print("🔴 DocumentsService Update Folder Error: \(error.localizedDescription)")
                completion(false, error.localizedDescription)
            } else {
                print("🟢 DocumentsService: Folder updated successfully")
                completion(true, nil)
            }
        }
    }
    
    // MARK: - Delete Folder (Recursive - deletes all child folders, documents, and images)
    func deleteFolder(userId: String, folderId: String, completion: @escaping (Bool, String?) -> Void) {
        print("🗑️ DocumentsService: Deleting folder \(folderId) and all its contents recursively")
        
        // First, get the parent folder ID to update its itemCount later
        db.collection("users").document(userId).collection("folders").document(folderId).getDocument { [weak self] snapshot, error in
            guard let self = self else {
                completion(false, "Service unavailable")
                return
            }
            
            if let error = error {
                print("🔴 DocumentsService: Error fetching folder: \(error.localizedDescription)")
                completion(false, error.localizedDescription)
                return
            }
            
            guard snapshot?.exists == true else {
                print("🔴 DocumentsService: Folder not found")
                completion(false, "Folder not found")
                return
            }
            
            let parentFolderId = snapshot?.data()?["parentFolderId"] as? String
            
            // Recursively delete all contents of this folder
            self.deleteFolderContentsRecursively(userId: userId, folderId: folderId) { [weak self] success, error in
                guard let self = self else {
                    completion(false, "Service unavailable")
                    return
                }
                
                if !success {
                    print("🔴 DocumentsService: Error deleting folder contents: \(error ?? "Unknown error")")
                    completion(false, error ?? "Failed to delete folder contents")
                    return
                }
                
                // Now delete the folder itself
                self.db.collection("users").document(userId).collection("folders").document(folderId).delete { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            print("🔴 DocumentsService Delete Folder Error: \(error.localizedDescription)")
                            completion(false, error.localizedDescription)
                        } else {
                            print("🟢 DocumentsService: Folder and all contents deleted successfully")
                            // Update parent folder itemCount if it exists
                            if let parentId = parentFolderId {
                                DispatchQueue.global(qos: .utility).async {
                                    self.updateFolderItemCount(userId: userId, folderId: parentId)
                                }
                            }
                            completion(true, nil)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Recursively Delete Folder Contents
    private func deleteFolderContentsRecursively(userId: String, folderId: String, completion: @escaping (Bool, String?) -> Void) {
        print("📂 DocumentsService: Deleting contents of folder \(folderId)")
        
        let documentsRef = db.collection("users").document(userId).collection("documents")
        let foldersRef = db.collection("users").document(userId).collection("folders")
        let storage = Storage.storage()
        
        // Get all documents in this folder
        documentsRef.whereField("folderId", isEqualTo: folderId).getDocuments { [weak self] documentsSnapshot, documentsError in
            guard let self = self else {
                completion(false, "Service unavailable")
                return
            }
            
            if let documentsError = documentsError {
                print("🔴 DocumentsService: Error fetching documents: \(documentsError.localizedDescription)")
                completion(false, documentsError.localizedDescription)
                return
            }
            
            // Delete all documents and their storage files
            let documents = documentsSnapshot?.documents ?? []
            let documentDeleteGroup = DispatchGroup()
            var documentDeleteErrors: [String] = []
            
            for doc in documents {
                documentDeleteGroup.enter()
                let docData = doc.data()
                let storageUrl = docData["url"] as? String ?? ""
                let docId = doc.documentID
                
                // Delete from Firestore
                documentsRef.document(docId).delete { error in
                    if let error = error {
                        print("🔴 DocumentsService: Error deleting document \(docId): \(error.localizedDescription)")
                        documentDeleteErrors.append("Document \(docId): \(error.localizedDescription)")
                    } else {
                        print("🟢 DocumentsService: Deleted document \(docId)")
                    }
                    
                    // Delete from Storage
                    if !storageUrl.isEmpty {
                        let storageRef = storage.reference(forURL: storageUrl)
                        storageRef.delete { error in
                            if let error = error {
                                print("⚠️ DocumentsService: Error deleting storage file for \(docId): \(error.localizedDescription)")
                            }
                        }
                    }
                    
                    documentDeleteGroup.leave()
                }
            }
            
            // Get all child folders
            foldersRef.whereField("parentFolderId", isEqualTo: folderId).getDocuments { [weak self] foldersSnapshot, foldersError in
                guard let self = self else {
                    completion(false, "Service unavailable")
                    return
                }
                
                if let foldersError = foldersError {
                    print("🔴 DocumentsService: Error fetching child folders: \(foldersError.localizedDescription)")
                    // Continue even if there's an error fetching folders
                }
                
                // Recursively delete all child folders
                let childFolders = foldersSnapshot?.documents ?? []
                let folderDeleteGroup = DispatchGroup()
                var folderDeleteErrors: [String] = []
                
                for folderDoc in childFolders {
                    folderDeleteGroup.enter()
                    let childFolderId = folderDoc.documentID
                    
                    // Recursively delete child folder and its contents
                    self.deleteFolderContentsRecursively(userId: userId, folderId: childFolderId) { success, error in
                        if success {
                            // Delete the child folder itself
                            foldersRef.document(childFolderId).delete { error in
                                if let error = error {
                                    print("🔴 DocumentsService: Error deleting child folder \(childFolderId): \(error.localizedDescription)")
                                    folderDeleteErrors.append("Folder \(childFolderId): \(error.localizedDescription)")
                                } else {
                                    print("🟢 DocumentsService: Deleted child folder \(childFolderId)")
                                }
                                folderDeleteGroup.leave()
                            }
                        } else {
                            print("🔴 DocumentsService: Error deleting contents of child folder \(childFolderId): \(error ?? "Unknown")")
                            folderDeleteErrors.append("Folder \(childFolderId): \(error ?? "Unknown")")
                            folderDeleteGroup.leave()
                        }
                    }
                }
                
                // Wait for all deletions to complete
                documentDeleteGroup.notify(queue: .main) {
                    folderDeleteGroup.notify(queue: .main) {
                        if documentDeleteErrors.isEmpty && folderDeleteErrors.isEmpty {
                            print("🟢 DocumentsService: All folder contents deleted successfully")
                            completion(true, nil)
                        } else {
                            let allErrors = (documentDeleteErrors + folderDeleteErrors).joined(separator: "; ")
                            print("⚠️ DocumentsService: Some deletions failed: \(allErrors)")
                            // Still return success if we deleted most items, but log errors
                            completion(true, nil)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Upload Document
    func uploadDocument(userId: String, fileURL: URL, fileName: String, folderId: String?, completion: @escaping (Bool, String?) -> Void) {
        // Use Firebase Auth UID for storage path if available, otherwise use userId parameter
        let storageUserId = Auth.auth().currentUser?.uid ?? userId
        print("📄 DocumentsService: Uploading document '\(fileName)' for user \(storageUserId) (Auth UID: \(Auth.auth().currentUser?.uid ?? "none"))")
        
        guard Auth.auth().currentUser != nil else {
            completion(false, "User not authenticated. Please log in again.")
            return
        }
        
        let storage = Storage.storage()
        let fileRef = storage.reference().child("users/\(storageUserId)/documents/\(UUID().uuidString)_\(fileName)")
        
        fileRef.putFile(from: fileURL, metadata: nil) { [weak self] metadata, error in
            if let error = error {
                print("🔴 DocumentsService Upload Document Error: \(error.localizedDescription)")
                completion(false, error.localizedDescription)
                return
            }
            
            fileRef.downloadURL { url, error in
                if let error = error {
                    print("🔴 DocumentsService Get Download URL Error: \(error.localizedDescription)")
                    completion(false, error.localizedDescription)
                    return
                }
                
                guard let downloadURL = url else {
                    completion(false, "Failed to get download URL")
                    return
                }
                
                var data: [String: Any] = [
                    "name": fileName,
                    "type": "document",
                    "url": downloadURL.absoluteString,
                    "size": metadata?.size ?? 0,
                    "createdAt": FieldValue.serverTimestamp()
                ]
                
                if let folderId = folderId {
                    data["folderId"] = folderId
                } else {
                    data["folderId"] = NSNull()
                }
                
                self?.db.collection("users").document(userId).collection("documents").addDocument(data: data) { [weak self] error in
                    if let error = error {
                        print("🔴 DocumentsService Save Document Metadata Error: \(error.localizedDescription)")
                        completion(false, error.localizedDescription)
                    } else {
                        print("🟢 DocumentsService: Document '\(fileName)' uploaded successfully")
                        let fileSize = Int64(metadata?.size ?? 0)
                        
                        // Update folder itemCount and storage in background (non-blocking)
                        DispatchQueue.global(qos: .utility).async {
                            if let folderId = folderId {
                                self?.updateFolderItemCount(userId: userId, folderId: folderId)
                            }
                            // Update centralized storage size
                            self?.updateStorageSize(userId: userId, fileSize: fileSize, isAdd: true)
                        }
                        
                        completion(true, nil)
                    }
                }
            }
        }
    }
    
    // MARK: - Share Document
    func shareDocument(userId: String, document: DocumentFile, friendId: String, notificationService: NotificationService, completion: @escaping (Bool, String?) -> Void) {
        
        // Fetch sender name first
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self else {
                completion(false, "Service unavailable")
                return
            }
            
            let senderName = snapshot?.data()?["name"] as? String ?? "Unknown"
            
            let data: [String: Any] = [
                "name": document.name,
                "type": document.type,
                "url": document.url,
                "size": document.size,
                "createdAt": FieldValue.serverTimestamp(),
                "isShared": true,
                "sharedBy": userId,
                "sharedByName": senderName,
                "folderId": NSNull() // Shared documents go to root, but filtered by query
            ]
            
            self.db.collection("users").document(friendId).collection("documents").addDocument(data: data) { error in
                if let error = error {
                    print("🔴 DocumentsService Share Error: \(error.localizedDescription)")
                    completion(false, error.localizedDescription)
                } else {
                    print("🟢 DocumentsService: Document shared")
                    
                    // Update shared counts
                    let batch = self.db.batch()
                    let senderRef = self.db.collection("users").document(userId)
                    let receiverRef = self.db.collection("users").document(friendId)
                    
                    batch.updateData(["sharedDocsCount": FieldValue.increment(Int64(1))], forDocument: senderRef)
                    batch.updateData(["sharedDocsCount": FieldValue.increment(Int64(1))], forDocument: receiverRef)
                    
                    batch.commit { error in
                        if let error = error {
                            print("🔴 DocumentsService Batch Error: \(error.localizedDescription)")
                        } else {
                            print("🟢 DocumentsService: Counts updated successfully")
                        }
                    }
                    
                    // Send Notifications
                    // To Receiver
                    notificationService.addNotification(userId: friendId, title: "Document Shared", message: "A document '\(document.name)' was shared with you.", type: "alert")
                    
                    // To Sender
                    notificationService.addNotification(userId: userId, title: "Document Shared", message: "You successfully shared '\(document.name)' with your friend.", type: "alert")
                    
                    completion(true, nil)
                }
            }
        }
    }
    
    // MARK: - Upload Image
    func uploadImage(userId: String, image: UIImage, fileName: String, folderId: String?, completion: @escaping (Bool, String?) -> Void) {
        // Use Firebase Auth UID for storage path if available, otherwise use userId parameter
        let storageUserId = Auth.auth().currentUser?.uid ?? userId
        print("🖼️ DocumentsService: Uploading image '\(fileName)' for user \(storageUserId) (Auth UID: \(Auth.auth().currentUser?.uid ?? "none"))")
        
        guard Auth.auth().currentUser != nil else {
            completion(false, "User not authenticated. Please log in again.")
            return
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(false, "Failed to convert image to data")
            return
        }
        
        let storage = Storage.storage()
        let fileRef = storage.reference().child("users/\(storageUserId)/images/\(UUID().uuidString)_\(fileName)")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        fileRef.putData(imageData, metadata: metadata) { [weak self] metadata, error in
            if let error = error {
                print("🔴 DocumentsService Upload Image Error: \(error.localizedDescription)")
                completion(false, error.localizedDescription)
                return
            }
            
            fileRef.downloadURL { url, error in
                if let error = error {
                    print("🔴 DocumentsService Get Download URL Error: \(error.localizedDescription)")
                    completion(false, error.localizedDescription)
                    return
                }
                
                guard let downloadURL = url else {
                    completion(false, "Failed to get download URL")
                    return
                }
                
                var data: [String: Any] = [
                    "name": fileName,
                    "type": "image",
                    "url": downloadURL.absoluteString,
                    "size": imageData.count,
                    "createdAt": FieldValue.serverTimestamp()
                ]
                
                if let folderId = folderId {
                    data["folderId"] = folderId
                } else {
                    data["folderId"] = NSNull()
                }
                
                self?.db.collection("users").document(userId).collection("documents").addDocument(data: data) { [weak self] error in
                    if let error = error {
                        print("🔴 DocumentsService Save Image Metadata Error: \(error.localizedDescription)")
                        completion(false, error.localizedDescription)
                    } else {
                        print("🟢 DocumentsService: Image '\(fileName)' uploaded successfully")
                        let fileSize = Int64(imageData.count)
                        
                        // Update folder itemCount and storage in background (non-blocking)
                        DispatchQueue.global(qos: .utility).async {
                            if let folderId = folderId {
                                self?.updateFolderItemCount(userId: userId, folderId: folderId)
                            }
                            // Update centralized storage size
                            self?.updateStorageSize(userId: userId, fileSize: fileSize, isAdd: true)
                        }
                        
                        completion(true, nil)
                    }
                }
            }
        }
    }
    
    // MARK: - Update Folder Item Count (Recursive - updates folder and all parents)
    private func updateFolderItemCount(userId: String, folderId: String) {
        // Count both documents and folders in this folder
        let documentsRef = db.collection("users").document(userId).collection("documents")
        let foldersRef = db.collection("users").document(userId).collection("folders")
        
        // Count documents
        documentsRef.whereField("folderId", isEqualTo: folderId).getDocuments { [weak self] documentsSnapshot, documentsError in
            guard let self = self else { return }
            
            if let documentsError = documentsError {
                print("🔴 DocumentsService: Error counting documents in folder: \(documentsError.localizedDescription)")
                return
            }
            
            let documentsCount = documentsSnapshot?.documents.count ?? 0
            
            // Count folders (subfolders)
            foldersRef.whereField("parentFolderId", isEqualTo: folderId).getDocuments { [weak self] foldersSnapshot, foldersError in
                guard let self = self else { return }
                
                if let foldersError = foldersError {
                    print("🔴 DocumentsService: Error counting folders in folder: \(foldersError.localizedDescription)")
                    return
                }
                
                let foldersCount = foldersSnapshot?.documents.count ?? 0
                let totalCount = documentsCount + foldersCount
                
                // Update folder itemCount
                self.db.collection("users").document(userId).collection("folders").document(folderId).updateData([
                    "itemCount": totalCount
                ]) { error in
                    if let error = error {
                        print("🔴 DocumentsService: Error updating folder itemCount: \(error.localizedDescription)")
                    } else {
                        print("🟢 DocumentsService: Updated folder \(folderId) itemCount to \(totalCount) (documents: \(documentsCount), folders: \(foldersCount))")
                        
                        // Get parent folder and recursively update it
                        self.db.collection("users").document(userId).collection("folders").document(folderId).getDocument { snapshot, error in
                            if let error = error {
                                print("🔴 DocumentsService: Error getting folder parent: \(error.localizedDescription)")
                                return
                            }
                            
                            guard let data = snapshot?.data(),
                                  let parentFolderId = data["parentFolderId"] as? String else {
                                // No parent folder (reached root), stop recursion
                                print("🟢 DocumentsService: Reached root, itemCount update complete")
                                return
                            }
                            
                            // Recursively update parent folder
                            print("📂 DocumentsService: Updating parent folder \(parentFolderId)")
                            self.updateFolderItemCount(userId: userId, folderId: parentFolderId)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Update Folder Item Count for Root (when folderId is nil)
    private func updateRootFolderItemCount(userId: String) {
        // Count documents in root (where folderId is NSNull)
        let documentsRef = db.collection("users").document(userId).collection("documents")
        documentsRef.whereField("folderId", isEqualTo: NSNull()).getDocuments { snapshot, error in
            if let error = error {
                print("🔴 DocumentsService: Error counting root documents: \(error.localizedDescription)")
                return
            }
            
            let count = snapshot?.documents.count ?? 0
            print("🟢 DocumentsService: Root folder has \(count) documents (no folder itemCount to update for root)")
        }
    }
    
    // MARK: - Update Storage Size
    func updateStorageSize(userId: String, fileSize: Int64, isAdd: Bool) {
        // Get all documents and calculate total storage
        let documentsRef = db.collection("users").document(userId).collection("documents")
        documentsRef.getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error {
                print("🔴 DocumentsService: Error calculating storage size: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                // No documents, set storage to 0
                DispatchQueue.main.async {
                    self.usedStorageMB = 0.0
                    self.totalDocuments = 0
                }
                return
            }
            
            // Calculate total size in bytes
            var totalSizeBytes: Int64 = 0
            for doc in documents {
                if let size = doc.data()["size"] as? Int64 {
                    totalSizeBytes += size
                } else if let size = doc.data()["size"] as? Int {
                    totalSizeBytes += Int64(size)
                }
            }
            
            // Convert to MB
            let totalSizeMB = Double(totalSizeBytes) / (1024.0 * 1024.0)
            
            // Update on main thread
            DispatchQueue.main.async {
                self.usedStorageMB = totalSizeMB
                self.totalDocuments = documents.count
                print("🟢 DocumentsService: Updated storage size to \(String(format: "%.2f", totalSizeMB)) MB (\(documents.count) files)")
            }
        }
    }
    
    // MARK: - Update Document/Image Name
    func updateDocumentName(userId: String, documentId: String, newName: String, completion: @escaping (Bool, String?) -> Void) {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            print("🔴 DocumentsService: Cannot update document name to empty string")
            completion(false, "Document name cannot be empty")
            return
        }
        
        print("✏️ DocumentsService: Updating document \(documentId) name to '\(trimmedName)'")
        
        db.collection("users").document(userId).collection("documents").document(documentId).updateData([
            "name": trimmedName,
            "updatedAt": FieldValue.serverTimestamp()
        ]) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("🔴 DocumentsService Update Document Name Error: \(error.localizedDescription)")
                    completion(false, error.localizedDescription)
                } else {
                    print("🟢 DocumentsService: Document name updated successfully to '\(trimmedName)'")
                    // The real-time listener will automatically pick up this change
                    // Small delay to ensure Firestore propagates the change
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        completion(true, nil)
                    }
                }
            }
        }
    }
    
    // MARK: - Delete Document/Image
    func deleteDocument(userId: String, documentId: String, folderId: String?, completion: @escaping (Bool, String?) -> Void) {
        print("🗑️ DocumentsService: Deleting document \(documentId)")
        
        // Get document data to get file size and storage path
        db.collection("users").document(userId).collection("documents").document(documentId).getDocument { [weak self] snapshot, error in
            guard let self = self else {
                completion(false, "Service unavailable")
                return
            }
            
            if let error = error {
                print("🔴 DocumentsService: Error getting document: \(error.localizedDescription)")
                completion(false, error.localizedDescription)
                return
            }
            
            guard let data = snapshot?.data() else {
                completion(false, "Document not found")
                return
            }
            
            let fileSize = (data["size"] as? Int64) ?? (data["size"] as? Int).map { Int64($0) } ?? 0
            let storageUrl = data["url"] as? String ?? ""
            
            // Delete from Firestore
            self.db.collection("users").document(userId).collection("documents").document(documentId).delete { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("🔴 DocumentsService Delete Document Error: \(error.localizedDescription)")
                        completion(false, error.localizedDescription)
                    } else {
                        print("🟢 DocumentsService: Document deleted successfully")
                        // The real-time listener will automatically pick up this deletion
                        
                        // Delete from Firebase Storage in background
                        if !storageUrl.isEmpty {
                            let storageRef = Storage.storage().reference(forURL: storageUrl)
                            storageRef.delete { error in
                                if let error = error {
                                    print("⚠️ DocumentsService: Error deleting storage file: \(error.localizedDescription)")
                                } else {
                                    print("🟢 DocumentsService: Storage file deleted successfully")
                                }
                            }
                        }
                        
                        // Update folder itemCount and storage in background (non-blocking)
                        DispatchQueue.global(qos: .utility).async {
                            if let folderId = folderId {
                                self.updateFolderItemCount(userId: userId, folderId: folderId)
                            } else {
                                self.updateRootFolderItemCount(userId: userId)
                            }
                            // Update centralized storage size
                            self.updateStorageSize(userId: userId, fileSize: fileSize, isAdd: false)
                        }
                        
                        // Small delay to ensure Firestore propagates the deletion
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            completion(true, nil)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Crypto Service
class CryptoService {
    static let shared = CryptoService()
    private let keychainTag = "com.docLock.keys.dataEncryptionKey"
    
    private init() {}
    
    // MARK: - Key Management
    private func getOrGenerateKey() -> SymmetricKey {
        if let keyData = retrieveKeyFromKeychain() {
            return SymmetricKey(data: keyData)
        } else {
            let newKey = SymmetricKey(size: .bits256)
            saveKeyToKeychain(key: newKey)
            return newKey
        }
    }
    
    private func saveKeyToKeychain(key: SymmetricKey) {
        let keyData = key.withUnsafeBytes { Data($0) }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keychainTag.data(using: .utf8)!,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock // Secure access
        ]
        
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func retrieveKeyFromKeychain() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keychainTag.data(using: .utf8)!,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            return dataTypeRef as? Data
        }
        return nil
    }
    
    // MARK: - Encryption / Decryption
    
    /// Encrypts a string using AES-GCM.
    /// Returns a Base64 encoded string of the combined sealed box (Nonce + Ciphertext + Tag).
    func encrypt(_ text: String) -> String? {
        guard let data = text.data(using: .utf8) else { return nil }
        let key = getOrGenerateKey()
        
        do {
            // AES-GCM provides authentication (Tag) ensuring data integrity.
            // It automatically generates a unique Nonce for every encryption call.
            let sealedBox = try AES.GCM.seal(data, using: key)
            return sealedBox.combined?.base64EncodedString()
        } catch {
            print("Encryption Error: \(error)")
            return nil
        }
    }
    
    /// Decrypts a Base64 encoded string using AES-GCM.
    func decrypt(_ base64String: String) -> String? {
        guard let data = Data(base64Encoded: base64String) else { return nil }
        let key = getOrGenerateKey()
        
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return String(data: decryptedData, encoding: .utf8)
        } catch {
            print("Decryption Error: \(error)")
            return nil // Failed to decrypt (Key mismatch or Tampered data)
        }
    }
}

// MARK: - Cards
class CardsService: ObservableObject {
    @Published var cards: [CardModel] = []
    @Published var error: String?
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()
    
    func startListening(userId: String) {
        listener?.remove()
        print("💳 CardsService: Starting listener for user \(userId)")
        
        listener = db.collection("users").document(userId).collection("cards")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("🔴 CardsService Error: \(error.localizedDescription)")
                    self?.error = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self?.cards = documents.compactMap { doc -> CardModel? in
                    let data = doc.data()
                    guard let typeString = data["type"] as? String,
                          let name = data["cardName"] as? String else { return nil }
                    
                    let holder = data["cardHolder"] as? String ?? ""
                    
                    // Decrypt sensitive data
                    let rawNumber = data["cardNumber"] as? String ?? ""
                    let rawCVV = data["cvv"] as? String ?? ""
                    let rawExpiry = data["expiry"] as? String ?? ""
                    
                    // Attempt decryption, fallback to raw if fail
                    let number = CryptoService.shared.decrypt(rawNumber) ?? rawNumber
                    let cvv = CryptoService.shared.decrypt(rawCVV) ?? rawCVV
                    let expiry = CryptoService.shared.decrypt(rawExpiry) ?? rawExpiry
                    
                    let type: CardType = (typeString == "Debit Card") ? .debit : .credit
                    
                    return CardModel(
                        id: doc.documentID,
                        type: type,
                        cardName: name,
                        cardNumber: number,
                        cardHolder: holder,
                        expiry: expiry,
                        cvv: cvv,
                        colorStart: type == .debit ? Color(red: 0.95, green: 0.85, blue: 0.4) : Color(red: 0.9, green: 0.4, blue: 0.6),
                        colorEnd: type == .debit ? Color(red: 0.9, green: 0.7, blue: 0.2) : Color(red: 0.95, green: 0.6, blue: 0.75),
                        isShared: data["isShared"] as? Bool ?? false,
                        sharedBy: data["sharedBy"] as? String
                    )
                }
                
                self?.error = nil
                print("🟢 CardsService: Synced \(self?.cards.count ?? 0) cards")
            }
    }
    
    func addCard(userId: String, card: CardModel, completion: @escaping (Bool, String?) -> Void) {
        guard let encNumber = CryptoService.shared.encrypt(card.cardNumber),
              let encCVV = CryptoService.shared.encrypt(card.cvv) else {
            completion(false, "Encryption failed")
            return
        }
        
        // Optionally encrypt expiry as well if desired, but user focused on sensitive data. 
        // Let's encrypt expiry too for good measure.
        let encExpiry = CryptoService.shared.encrypt(card.expiry) ?? card.expiry
        
        let data: [String: Any] = [
            "type": card.type.rawValue,
            "cardName": card.cardName,
            "cardNumber": encNumber,
            "cardHolder": card.cardHolder, // Usually not encrypted for search, but can be
            "expiry": encExpiry,
            "cvv": encCVV,
            "colorStartHex": card.colorStart.toHex() ?? "",
            "colorEndHex": card.colorEnd.toHex() ?? "",
            "createdAt": FieldValue.serverTimestamp(),
            "isShared": false
        ]
        
        db.collection("users").document(userId).collection("cards").addDocument(data: data) { error in
            if let error = error {
                print("🔴 CardsService Add Error: \(error.localizedDescription)")
                completion(false, error.localizedDescription)
            } else {
                print("🟢 CardsService: Card added")
                completion(true, nil)
            }
        }
    }
    
    func shareCard(userId: String, card: CardModel, friendId: String, notificationService: NotificationService, completion: @escaping (Bool, String?) -> Void) {
        guard let encNumber = CryptoService.shared.encrypt(card.cardNumber),
              let encCVV = CryptoService.shared.encrypt(card.cvv) else {
            completion(false, "Encryption failed")
            return
        }
        
        // Encrypt expiry as well
        let encExpiry = CryptoService.shared.encrypt(card.expiry) ?? card.expiry
        
        let data: [String: Any] = [
            "type": card.type.rawValue,
            "cardName": card.cardName,
            "cardNumber": encNumber,
            "cardHolder": card.cardHolder,
            "expiry": encExpiry,
            "cvv": encCVV,
            "colorStartHex": card.colorStart.toHex() ?? "",
            "colorEndHex": card.colorEnd.toHex() ?? "",
            "createdAt": FieldValue.serverTimestamp(),
            "isShared": true,
            "sharedBy": userId
        ]
        
        db.collection("users").document(friendId).collection("cards").addDocument(data: data) { [weak self] error in
            if let error = error {
                print("🔴 CardsService Share Error: \(error.localizedDescription)")
                completion(false, error.localizedDescription)
            } else {
                print("🟢 CardsService: Card shared")
                
                // Update shared counts
                let batch = self?.db.batch()
                let senderRef = self?.db.collection("users").document(userId)
                let receiverRef = self?.db.collection("users").document(friendId)
                
                if let senderRef = senderRef {
                    batch?.updateData(["sharedCardsCount": FieldValue.increment(Int64(1))], forDocument: senderRef)
                }
                if let receiverRef = receiverRef {
                    batch?.updateData(["sharedCardsCount": FieldValue.increment(Int64(1))], forDocument: receiverRef)
                }
                
                batch?.commit { error in
                    if let error = error {
                        print("🔴 CardsService Batch Error: \(error.localizedDescription)")
                    } else {
                        print("🟢 CardsService: Counts updated successfully")
                    }
                }
                
                // Send Notifications
                // To Receiver
                notificationService.addNotification(userId: friendId, title: "Card Shared", message: "A card verified by your friend was shared with you.", type: "alert")
                
                // To Sender
                notificationService.addNotification(userId: userId, title: "Card Shared", message: "You successfully shared \(card.cardName) with your friend.", type: "alert")
                
                completion(true, nil)
            }
        }
    }
    
    func updateCard(userId: String, cardId: String, card: CardModel, completion: @escaping (Bool, String?) -> Void) {
        guard let encNumber = CryptoService.shared.encrypt(card.cardNumber),
              let encCVV = CryptoService.shared.encrypt(card.cvv) else {
            completion(false, "Encryption failed")
            return
        }
        
        let encExpiry = CryptoService.shared.encrypt(card.expiry) ?? card.expiry
        
        let data: [String: Any] = [
            "type": card.type.rawValue,
            "cardName": card.cardName,
            "cardNumber": encNumber,
            "cardHolder": card.cardHolder,
            "expiry": encExpiry,
            "cvv": encCVV,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("users").document(userId).collection("cards").document(cardId).updateData(data) { error in
            if let error = error {
                print("🔴 CardsService Update Error: \(error.localizedDescription)")
                completion(false, error.localizedDescription)
            } else {
                print("🟢 CardsService: Card updated")
                completion(true, nil)
            }
        }
    }
    
    func deleteCard(userId: String, cardId: String, completion: @escaping (Bool, String?) -> Void) {
        db.collection("users").document(userId).collection("cards").document(cardId).delete { error in
            if let error = error {
                print("🔴 CardsService Delete Error: \(error.localizedDescription)")
                completion(false, error.localizedDescription)
            } else {
                print("🟢 CardsService: Card deleted")
                completion(true, nil)
            }
        }
    }
    
    func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    func retry(userId: String) {
        if error != nil {
            print("🔄 CardsService: Retrying...")
            startListening(userId: userId)
        }
    }
}

// MARK: - App Config
class AppConfigService: ObservableObject {
    @Published var maxStorageLimit: Int = 200 // Default 200MB
    @Published var maxCreditCardsLimit: Int = 10 // Default 10
    @Published var maxFolderDepth: Int = 3 // Default max nesting depth
    @Published var error: String?
    
    private let db = Firestore.firestore()
    
    func fetchConfig(completion: @escaping (Bool) -> Void) {
        print("⚙️ AppConfigService: Fetching configuration...")
        
        db.collection("appConfig").document("global").getDocument { [weak self] snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("🔴 AppConfigService Error: \(error.localizedDescription)")
                    self?.error = error.localizedDescription
                    completion(false) // Failure
                    return
                }
                
                guard let data = snapshot?.data() else {
                    print("⚠️ AppConfigService: No config data found, using defaults")
                    completion(true) // Success (using defaults)
                    return
                }
                
                let storageBytes = data["maxStorageLimit"] as? Int ?? 209715200
                self?.maxStorageLimit = storageBytes / (1024 * 1024) // Convert to MB
                self?.maxCreditCardsLimit = data["maxCreditCardsLimit"] as? Int ?? 5
                self?.maxFolderDepth = data["maxFolderNestingAllowed"] as? Int ?? 3
                
                print("🟢 AppConfigService: Loaded config (Storage: \(self?.maxStorageLimit ?? 0)MB, Cards: \(self?.maxCreditCardsLimit ?? 0))")
                completion(true) // Success
            }
        }
    }
}
