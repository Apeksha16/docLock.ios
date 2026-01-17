import SwiftUI

struct SignupView: View {
    let prefilledMobile: String
    @Binding var showMPIN: Bool
    @Binding var showLogin: Bool // To navigate back to Login
    var onGetOTP: (String, String) -> Void // Returns (mobile, fullName)
    
    @State private var fullName = ""
    @State private var phoneNumber = ""
    @FocusState private var isNameFieldFocused: Bool
    
    // Theme Color: #8b5cf6 -> RGB(139, 92, 246)
    let themeColor = Color(red: 0.55, green: 0.36, blue: 0.96)
    // Disabled Color: #b2aadf -> RGB(178, 170, 223)
    let disabledThemeColor = Color(red: 0.70, green: 0.67, blue: 0.87)
    
    var isValidMobileNumber: Bool {
        // Must be exactly 10 digits
        guard phoneNumber.count == 10 else { return false }
        
        // First digit must be greater than 5 (6, 7, 8, or 9)
        guard let firstDigit = phoneNumber.first?.wholeNumberValue else { return false }
        guard firstDigit > 5 else { return false }
        
        // All characters must be digits
        return phoneNumber.allSatisfy { $0.isNumber }
    }
    
    var isValid: Bool {
        return !fullName.trimmingCharacters(in: .whitespaces).isEmpty && isValidMobileNumber
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 50))
                .foregroundColor(themeColor)
                .padding(.top, 20)
            
            Text("Create Account")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
            
            Text("Join DocLock today")
                .font(.subheadline)
                .foregroundColor(.gray)

            VStack(alignment: .leading, spacing: 15) {
                // Full Name Input
                VStack(alignment: .leading, spacing: 5) {
                    Text("Full Name")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.4))
                    
                    TextField("Enter your full name", text: $fullName)
                        .focused($isNameFieldFocused)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke((isNameFieldFocused || !fullName.isEmpty) ? Color(red: 0.55, green: 0.36, blue: 0.96) : Color.gray.opacity(0.3), lineWidth: 1)
                        )

                }
                
                // Mobile Number Input
                VStack(alignment: .leading, spacing: 5) {
                    Text("Mobile Number")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.4))
                    
                    TextField("10-digit mobile number", text: $phoneNumber)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke((!phoneNumber.isEmpty) ? Color(red: 0.55, green: 0.36, blue: 0.96) : Color.gray.opacity(0.3), lineWidth: 1)
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
            }
            .padding(.top, 10)

            Button(action: {
                onGetOTP(phoneNumber, fullName)
            }) {
                Text("Get OTP")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isValid ? themeColor : disabledThemeColor)
                    .foregroundColor(.white)
                    .cornerRadius(15)
            }
            .disabled(!isValid)
            .padding(.top, 10)

            HStack {
                Text("Already have an account?")
                    .foregroundColor(.gray)
                Button("Sign In") {
                    withAnimation {
                        showLogin = true
                    }
                }
                .fontWeight(.bold)
                .foregroundColor(themeColor)
            }
            .font(.footnote)
            
            Spacer().frame(height: 20)
            
            HStack {
                Image(systemName: "checkmark.shield")
                Text("Your data is safe with us")
            }
            .font(.caption)
            .foregroundColor(.gray)
            .padding(10)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(.horizontal)
        .onAppear {
            // Prefill mobile number if provided
            if !prefilledMobile.isEmpty {
                phoneNumber = prefilledMobile
            }
            // Auto focus on name field when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isNameFieldFocused = true
            }
        }
    }
}
