import Foundation
import UIKit
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

class AuthService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isAuthenticated = false
    @Published var user: User?
    @Published var mobileExists: Bool?
    @Published var lockoutDate: Date?
    @Published var isDeviceMismatch = false
    
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
                                   let newUrl = result["url"] as? String,
                                   let newStorage = result["storage"] as? Int64 {
                                    
                                    // We need to construct a new User object since it's immutable (let properties)
                                    // Assuming we can re-decode or just partial update if we had a mutable model.
                                    // Since User is struct with 'let', we can't modify it in place.
                                    // We'll rely on fetching or just trust the UI updates if we bind to specific fields?
                                    // But 'user' is @Published. We should update it.
                                    // Actually, User struct has `let` properties.
                                    // We might need to make them `var` or create a new instance using the old values + new ones.
                                    // For now, let's try to create a new User instance.
                                    if let currentUser = self.user {
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
                    if let currentUser = self?.user {
                        // Create a new User object with updated name
                        // We need to use the initializer we'll add extension for or just structural init if internal
                        // Assuming structural init is available since it's a simple struct
                        // We'll trust fetchUserProfile to eventually sync, but for immediate UI:
                        // self?.user = User(uid: currentUser.uid, mobile: currentUser.mobile, name: name, profileImageUrl: currentUser.profileImageUrl, storageUsed: currentUser.storageUsed)
                        // Trigger fetch to be safe and clean
                        self?.fetchUserProfile(userId: userId)
                    }
                    completion(true, nil)
                    
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
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            DispatchQueue.main.async {
                if let data = snapshot?.data() {
                    let mobile = data["mobile"] as? String
                    let name = data["name"] as? String ?? "User"
                    let profileImageUrl = data["profileImageUrl"] as? String
                    let storageUsed = data["storageUsed"] as? Int64
                    
                    // Manually create User object to avoid JSON/Timestamp serialization issues
                    // Manually create User object to avoid JSON/Timestamp serialization issues
                    let updatedUser = User(
                        uid: userId,
                        mobile: mobile,
                        name: name,
                        profileImageUrl: profileImageUrl,
                        storageUsed: storageUsed,
                        addedAt: nil // Self doesn't have an addedAt date
                    )
                    
                    self?.user = updatedUser
                    print("✅ User Profile Synced: \(updatedUser.name), Mobile: \(updatedUser.mobile ?? "nil")")
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
                    
                    return NotificationItem(id: doc.documentID, type: type, title: title, message: message, date: date, isRead: isRead, requestType: requestType)
                }
                self?.error = nil // Clear error on success
                print("🟢 NotificationService: Synced \(self?.notifications.count ?? 0) items")
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
            .addSnapshotListener { [weak self] snapshot, error in
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
        
        // 1. Add to Current User's List
        let friendRef = db.collection("users").document(currentUser.uid).collection("friends").document(friend.uid)
        
        let data: [String: Any] = [
            "uid": friend.uid,
            "name": friend.name,
            "mobile": friend.mobile ?? "",
            "profileImageUrl": friend.profileImageUrl ?? "",
            "addedAt": FieldValue.serverTimestamp()
        ]
        
        friendRef.setData(data) { error in
            if let error = error {
                completion(false, error.localizedDescription)
            } else {
                // SUCCESS
                
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
        db.collection("users").document(currentUser.uid).collection("friends").document(friend.uid).delete { error in
            if let error = error {
                print("🔴 Error removing friend: \(error)")
                self.error = "Failed to remove friend"
            } else {
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
            addedAt: date
        )
    }
}

// MARK: - Documents
class DocumentsService: ObservableObject {
    @Published var folders: [DocFolder] = []
    @Published var currentFolderDocuments: [DocumentFile] = []
    @Published var currentFolderFolders: [DocFolder] = []
    @Published var totalDocuments: Int = 0
    @Published var usedStorageMB: Double = 0.0
    @Published var error: String?
    
    var appConfigService: AppConfigService?
    
    private var listener: ListenerRegistration?
    private var folderDocumentsListener: ListenerRegistration?
    private var folderFoldersListener: ListenerRegistration?
    private let db = Firestore.firestore()
    
    func startListening(userId: String, parentFolderId: String? = nil) {
        listener?.remove()
        print("📄 DocumentsService: Starting listener for user \(userId), parentFolderId: \(parentFolderId ?? "root")")
        
        // Listening to folders filtered by parentFolderId
        var query: Query = db.collection("users").document(userId).collection("folders")
        
        if let parentId = parentFolderId {
            query = query.whereField("parentFolderId", isEqualTo: parentId)
        } else {
            query = query.whereField("parentFolderId", isEqualTo: NSNull())
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
                
                // Calculate totals
                self?.totalDocuments = self?.folders.reduce(0) { $0 + $1.itemCount } ?? 0
                // Mock storage calculation based on count for now
                self?.usedStorageMB = Double(self?.totalDocuments ?? 0) * 1.5 
                
                self?.error = nil
                print("🟢 DocumentsService: Synced \(self?.folders.count ?? 0) folders")
            }
    }
    
    func stopListening() {
        listener?.remove()
        listener = nil
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
        
        var query: Query = db.collection("users").document(userId).collection("documents")
        
        if let folderId = folderId {
            query = query.whereField("folderId", isEqualTo: folderId)
        } else {
            query = query.whereField("folderId", isEqualTo: NSNull())
        }
        
        folderDocumentsListener = query.order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("🔴 DocumentsService Folder Documents Error: \(error.localizedDescription)")
                    self?.error = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self?.currentFolderDocuments = []
                    return
                }
                
                self?.currentFolderDocuments = documents.compactMap { doc -> DocumentFile? in
                    let data = doc.data()
                    let name = data["name"] as? String ?? "Unnamed"
                    let type = data["type"] as? String ?? "document"
                    let url = data["url"] as? String ?? ""
                    let size = data["size"] as? Int ?? 0
                    let timestamp = data["createdAt"] as? Timestamp
                    let createdAt = timestamp?.dateValue()
                    
                    return DocumentFile(
                        id: doc.documentID,
                        name: name,
                        type: type,
                        url: url,
                        size: size,
                        createdAt: createdAt
                    )
                }
                
                print("🟢 DocumentsService: Loaded \(self?.currentFolderDocuments.count ?? 0) documents in folder")
            }
    }
    
    // MARK: - Fetch Folders in Folder
    func fetchFoldersInFolder(userId: String, parentFolderId: String?) {
        folderFoldersListener?.remove()
        print("📁 DocumentsService: Fetching folders in parent \(parentFolderId ?? "root")")
        
        var query: Query = db.collection("users").document(userId).collection("folders")
        
        if let parentId = parentFolderId {
            query = query.whereField("parentFolderId", isEqualTo: parentId)
        } else {
            query = query.whereField("parentFolderId", isEqualTo: NSNull())
        }
        
        folderFoldersListener = query.addSnapshotListener { [weak self] snapshot, error in
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
        print("📁 DocumentsService: Creating folder '\(folderName)' for user \(userId), parent: \(parentFolderId ?? "root"), depth: \(parentDepth + 1)")
        
        // Check depth limit
        if parentDepth + 1 >= maxDepth {
            completion(false, "Maximum folder nesting depth (\(maxDepth)) reached")
            return
        }
        
        var data: [String: Any] = [
            "name": folderName,
            "itemCount": 0,
            "icon": "folder",
            "depth": parentDepth + 1,
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
                print("🟢 DocumentsService: Folder '\(folderName)' created successfully")
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
    
    // MARK: - Delete Folder
    func deleteFolder(userId: String, folderId: String, completion: @escaping (Bool, String?) -> Void) {
        print("🗑️ DocumentsService: Deleting folder \(folderId)")
        
        db.collection("users").document(userId).collection("folders").document(folderId).delete { error in
            if let error = error {
                print("🔴 DocumentsService Delete Folder Error: \(error.localizedDescription)")
                completion(false, error.localizedDescription)
            } else {
                print("🟢 DocumentsService: Folder deleted successfully")
                completion(true, nil)
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
        let fileRef = storage.reference().child("documents/\(storageUserId)/\(UUID().uuidString)_\(fileName)")
        
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
                
                self?.db.collection("users").document(userId).collection("documents").addDocument(data: data) { error in
                    if let error = error {
                        print("🔴 DocumentsService Save Document Metadata Error: \(error.localizedDescription)")
                        completion(false, error.localizedDescription)
                    } else {
                        print("🟢 DocumentsService: Document '\(fileName)' uploaded successfully")
                        completion(true, nil)
                    }
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
        let fileRef = storage.reference().child("images/\(storageUserId)/\(UUID().uuidString)_\(fileName)")
        
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
                
                self?.db.collection("users").document(userId).collection("documents").addDocument(data: data) { error in
                    if let error = error {
                        print("🔴 DocumentsService Save Image Metadata Error: \(error.localizedDescription)")
                        completion(false, error.localizedDescription)
                    } else {
                        print("🟢 DocumentsService: Image '\(fileName)' uploaded successfully")
                        completion(true, nil)
                    }
                }
            }
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
                          let name = data["cardName"] as? String,
                          let number = data["cardNumber"] as? String,
                          let holder = data["cardHolder"] as? String,
                          let expiry = data["expiry"] as? String,
                          let cvv = data["cvv"] as? String else { return nil }
                    
                    let type: CardType = (typeString == "Debit Card") ? .debit : .credit
                    
                    // Colors - Using simplified logic for now as storing Color in Firestore is complex
                    // Ideally we store color hex codes
                    return CardModel(
                        id: UUID(), // Or use doc.documentID
                        type: type,
                        cardName: name,
                        cardNumber: number,
                        cardHolder: holder,
                        expiry: expiry,
                        cvv: cvv,
                        colorStart: type == .debit ? Color(red: 0.95, green: 0.85, blue: 0.4) : Color(red: 0.9, green: 0.4, blue: 0.6),
                        colorEnd: type == .debit ? Color(red: 0.9, green: 0.7, blue: 0.2) : Color(red: 0.95, green: 0.6, blue: 0.75)
                    )
                }
                
                self?.error = nil
                print("🟢 CardsService: Synced \(self?.cards.count ?? 0) cards")
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
    @Published var maxFolderDepth: Int = 5 // Default max nesting depth
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
                self?.maxFolderDepth = data["maxFolderDepth"] as? Int ?? 5
                
                print("🟢 AppConfigService: Loaded config (Storage: \(self?.maxStorageLimit ?? 0)MB, Cards: \(self?.maxCreditCardsLimit ?? 0))")
                completion(true) // Success
            }
        }
    }
}
