import SwiftUI

struct SignupView: View {
    @Binding var showMPIN: Bool
    @Binding var showLogin: Bool // To navigate back to Login
    @State private var fullName = ""
    @State private var phoneNumber = ""
    
    // Theme Color: #8b5cf6 -> RGB(139, 92, 246)
    let themeColor = Color(red: 0.55, green: 0.36, blue: 0.96)
    // Disabled Color: #b2aadf -> RGB(178, 170, 223)
    let disabledThemeColor = Color(red: 0.70, green: 0.67, blue: 0.87)
    
    var isValid: Bool {
        return !fullName.isEmpty && phoneNumber.count == 10
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
                    
                    CustomTextField(placeholder: "Enter your full name", text: $fullName, keyboardType: .default)

                }
                
                // Mobile Number Input
                VStack(alignment: .leading, spacing: 5) {
                    Text("Mobile Number")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.4))
                    
                    CustomTextField(placeholder: "10-digit mobile number", text: $phoneNumber, keyboardType: .numberPad)
                        .onChange(of: phoneNumber) { newValue in
                            if newValue.count > 10 {
                                phoneNumber = String(newValue.prefix(10))
                            }
                        }

                }
            }
            .padding(.top, 10)

            Button(action: {
                withAnimation {
                    showMPIN = true
                }
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
    }
}
