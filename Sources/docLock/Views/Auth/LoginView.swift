import SwiftUI

struct LoginView: View {
    @ObservedObject var authService: AuthService
    var onSignup: (String) -> Void
    var onOTPRequested: (String) -> Void
    
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
        ScrollViewReader { scrollProxy in // START ScrollViewReader
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    headerView
                    
                    inputView
            
                    verifyButton
                        .padding(.top, 10)

                    if let lockoutDate = authService.lockoutDate, lockoutDate > Date() {
                        lockoutView(lockoutDate: lockoutDate)
                    }

                    footerView
                    
                    Spacer().frame(height: 20)
                    
                    encryptionBadge
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            } // End of ScrollView
            .onChange(of: isTextFieldFocused) { focused in
                if !focused {
                    withAnimation {
                        scrollProxy.scrollTo("Top", anchor: .top)
                    }
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isTextFieldFocused = false
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 50))
                .foregroundColor(themeColor) // Updated Logo Color
                .padding(.top, 20)
                .id("Top") // Tag top element
            
            TypewriterCycleView(phrases: typewriterPhrases)
                .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2)) // Dark Navy Text
                .frame(height: 40) // Fixed height to prevent jumping
            
            Text("Your primary documents, \nencrypted & synced.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal, 40)
        }
    }
    
    private var inputView: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Mobile Number")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.4))
            
            HStack {
                Text("+91")
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                
                Divider().frame(height: 20)
                
                TextField("Enter 10-digit number", text: $phoneNumber)
                    .keyboardType(.numberPad)
                    .focused($isTextFieldFocused)
                    .onChange(of: phoneNumber) { newValue in
                        // Filter out non-numeric characters
                        phoneNumber = newValue.filter { $0.isNumber }
                        
                        // Limit to 10 digits
                        if phoneNumber.count > 10 {
                            phoneNumber = String(phoneNumber.prefix(10))
                        }
                    }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke((isTextFieldFocused || !phoneNumber.isEmpty) ? themeColor : Color.gray.opacity(0.3), lineWidth: 1)
            )
            .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
            .colorScheme(.light) // Force light mode colors for text field
        }
        .padding(.horizontal)
    }
    
    private var verifyButton: some View {
        Button(action: verifyMobileNumber) {
            HStack {
                if isVerifying {
                    ProgressView()
                        .tint(.white)
                        .padding(.trailing, 10)
                }
                Text("Verify Mobile")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isValidNumber ? themeColor : disabledThemeColor)
            .foregroundColor(.white)
            .cornerRadius(15)
        }
        .disabled(!isValidNumber || isVerifying)
        .padding(.horizontal)
    }
    
    private func lockoutView(lockoutDate: Date) -> some View {
        VStack(spacing: 5) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text("Account Locked")
                .fontWeight(.bold)
            Text("Too many failed attempts. Try again after \(lockoutDate, style: .time)")
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var footerView: some View {
        HStack {
            Text("Don't have an account?")
                .foregroundColor(.gray)
            Button("Sign Up") {
                onSignup(phoneNumber)
            }
            .fontWeight(.bold)
            .foregroundColor(themeColor)
        }
        .font(.footnote)
    }
    
    private var encryptionBadge: some View {
        HStack {
            Image(systemName: "checkmark.shield.fill")
                .foregroundColor(.green)
            Text("Military Grade Encryption")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color.gray.opacity(0.05))
        .clipShape(Capsule())
    }
    
    private func verifyMobileNumber() {
        isVerifying = true
        authService.verifyMobile(mobile: phoneNumber) { exists, message in
            isVerifying = false
            if exists {
                onOTPRequested(phoneNumber)
            } else {
                authService.errorMessage = "Mobile number not found. Please sign up."
            }
        }
    }
}