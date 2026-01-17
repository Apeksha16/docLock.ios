import Foundation
import UIKit

struct LoginRequest: Encodable {
    let mobile: String
    let mpin: String
    let deviceId: String
}

struct LoginResponse: Decodable {
    let message: String
    let token: String
    let user: User?
}

struct User: Decodable {
    let uid: String
    let name: String
}

class AuthService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    @Published var user: User?

    // Base URL from your Cloud Function
    private let baseURL = "https://api-to72oyfxda-uc.a.run.app/api/auth/login"

    func login(mobile: String, mpin: String) {
        print("AuthService: login called with mobile: \(mobile)")
        isLoading = true
        errorMessage = nil

        // TODO: Get real Device ID if needed, for now using static or UUID
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown-device-id"
        print("AuthService: Device ID: \(deviceId)")
        
        // Construct Request Body
        let requestBody = LoginRequest(mobile: mobile, mpin: mpin, deviceId: deviceId)
        
        guard let url = URL(string: baseURL) else {
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
        } catch {
            self.errorMessage = "Failed to encode request"
            self.isLoading = false
            print("AuthService: Failed to encode request")
            return
        }
        
        print("AuthService: Sending request to \(url)")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            print("AuthService: Response received")
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    self?.errorMessage = "Invalid server response"
                    return
                }

                guard (200...299).contains(httpResponse.statusCode) else {
                    self?.errorMessage = "Login failed with status code: \(httpResponse.statusCode)"
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
                    self?.isAuthenticated = true
                    print("Login Successful. Token: \(loginResponse.token)")
                    // Consider storing token in Keychain
                } catch {
                    self?.errorMessage = "Failed to decode response"
                    print("Decoding Error: \(error)")
                }
            }
        }.resume()
    }
}
