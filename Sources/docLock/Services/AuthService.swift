import Foundation
import UIKit
import FirebaseFirestore
import FirebaseAuth

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
    
    // Base URL from your Cloud Function
    private let baseURL = "http://192.168.29.38:3000/api/auth"
    
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
                            guard success else {
                                self?.isLoading = false
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
                            guard success else {
                                self?.isLoading = false
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
    
    // MARK: - Data Sync
    private func startDataSync(userId: String) {
        print("🚀 Starting Parallel Data Sync for User: \(userId)")
        
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
                    
                    return NotificationItem(id: UUID(), type: type, title: title, message: message, date: date, isRead: isRead)
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
}

// MARK: - Friends
class FriendsService: ObservableObject {
    // Ideally use a FriendModel, but for now using a simple structure or just count check
    @Published var friendsCount: Int = 0
    // @Published var friends: [FriendModel] = [] 
    @Published var error: String?
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()
    
    func startListening(userId: String) {
        listener?.remove()
        print("👥 FriendsService: Starting listener for user \(userId)")
        
        listener = db.collection("users").document(userId).collection("friends")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("🔴 FriendsService Error: \(error.localizedDescription)")
                    self?.error = error.localizedDescription
                    return
                }
                
                guard let count = snapshot?.documents.count else { return }
                self?.friendsCount = count
                self?.error = nil
                print("🟢 FriendsService: Synced \(count) friends")
            }
    }
    
    func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    func retry(userId: String) {
        if error != nil {
            print("🔄 FriendsService: Retrying...")
            startListening(userId: userId)
        }
    }
}

// MARK: - Documents
class DocumentsService: ObservableObject {
    @Published var folders: [DocFolder] = []
    @Published var totalDocuments: Int = 0
    @Published var usedStorageMB: Double = 0.0
    @Published var error: String?
    
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()
    
    func startListening(userId: String) {
        listener?.remove()
        print("📄 DocumentsService: Starting listener for user \(userId)")
        
        // Listening to 'folders' or documents metadata collection
        // Adjusting logic to match existing UI structure (folders)
        listener = db.collection("users").document(userId).collection("folders")
            .addSnapshotListener { [weak self] snapshot, error in
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
                    return DocFolder(name: name, itemCount: itemCount, icon: icon)
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
                
                print("🟢 AppConfigService: Loaded config (Storage: \(self?.maxStorageLimit ?? 0)MB, Cards: \(self?.maxCreditCardsLimit ?? 0))")
                completion(true) // Success
            }
        }
    }
}
