import SwiftUI

struct LoginView: View {
    @ObservedObject var authService: AuthService
    @Binding var showSignup: Bool
    var onMobileVerified: (String, Bool) -> Void // Returns (mobile, exists)
    
    @State private var phoneNumber = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var isVerifying = false
    
    var isValidNumber: Bool {
        // Must be exactly 10 digits
        guard phoneNumber.count == 10 else { return false }
        
        // First digit must be greater than 5 (6, 7, 8, or 9)
        guard let firstDigit = phoneNumber.first?.wholeNumberValue else { return false }
        guard firstDigit > 5 else { return false }
        
        // All characters must be digits
        return phoneNumber.allSatisfy { $0.isNumber }
    }
    
    // Theme Color: #8b5cf6 -> RGB(139, 92, 246)
    let themeColor = Color(red: 0.55, green: 0.36, blue: 0.96)
    // Disabled Color: #b2aadf -> RGB(178, 170, 223)
    let disabledThemeColor = Color(red: 0.70, green: 0.67, blue: 0.87)

    let typewriterPhrases = ["GO PAPERLESS", "ONE SCAN ACCESS", "STAY SECURE"]

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 50))
                .foregroundColor(themeColor) // Updated Logo Color
                .padding(.top, 20)
            
            TypewriterCycleView(phrases: typewriterPhrases)
                .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2)) // Dark Navy Text
                .frame(height: 40) // Fixed height to prevent jumping
            
            Text("Sign in to your secure vault")
                .foregroundColor(.gray)

            VStack(alignment: .leading, spacing: 5) {
                Text("Mobile Number")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.4))
                
                TextField("Enter 10-digit number", text: $phoneNumber)
                    .keyboardType(.numberPad)
                    .focused($isTextFieldFocused)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke((isTextFieldFocused || !phoneNumber.isEmpty) ? Color(red: 0.55, green: 0.36, blue: 0.96) : Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .onChange(of: phoneNumber) { newValue in
                        // Filter out non-numeric characters
                        phoneNumber = newValue.filter { $0.isNumber }
                        
                        // Limit to 10 digits
                        if phoneNumber.count > 10 {
                            phoneNumber = String(phoneNumber.prefix(10))
                        }
                    }

            }
            .padding(.top, 20)

            Button(action: {
                verifyMobile()
            }) {
                HStack {
                    if isVerifying {
                        ProgressView()
                            .tint(.white)
                            .padding(.trailing, 8)
                    }
                    Text(isVerifying ? "Verifying..." : "Get OTP")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isValidNumber && !isVerifying ? themeColor : disabledThemeColor)
                .foregroundColor(.white)
                .cornerRadius(15)
            }
            .disabled(!isValidNumber || isVerifying || (authService.lockoutDate != nil && authService.lockoutDate! > Date()))
            .padding(.top, 10)

            if let lockoutDate = authService.lockoutDate, lockoutDate > Date() {
                VStack(spacing: 4) {
                    Text("Your account is locked")
                        .foregroundColor(.red)
                        .font(.caption)
                        .fontWeight(.bold)
                    
                    TimelineView(.periodic(from: .now, by: 1.0)) { context in
                        let remaining = Int(lockoutDate.timeIntervalSince(context.date))
                        if remaining > 0 {
                            Text("Time remaining: \(remaining)s")
                                .foregroundColor(.red)
                                .font(.caption)
                        } else {
                            Text("Lockout expired")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                    }
                }
                .padding(.top, 5)
            }

            HStack {
                Text("New to DocLock?")
                    .foregroundColor(.gray)
                Button("Create Account") {
                    withAnimation {
                        showSignup = true
                    }
                }
                .fontWeight(.bold)
                .foregroundColor(themeColor)
            }
            .font(.footnote)
            
            Spacer().frame(height: 20)
            
            HStack {
                Image(systemName: "lock.fill")
                Text("Secured with 256-bit encryption")
            }
            .font(.caption)
            .foregroundColor(.gray)
            .padding(10)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.horizontal)
        .onAppear {
            // Auto focus when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }
    
    func verifyMobile() {
        isVerifying = true
        authService.verifyMobile(mobile: phoneNumber) { exists, message in
            isVerifying = false
            onMobileVerified(phoneNumber, exists)
        }
    }
}