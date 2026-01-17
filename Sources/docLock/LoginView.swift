import SwiftUI

struct LoginView: View {
    @Binding var showSignup: Bool
    @Binding var showMPIN: Bool
    
    @State private var phoneNumber = ""
    
    var isValidNumber: Bool {
        return phoneNumber.count == 10
    }
    
    // Theme Color: #8b5cf6 -> RGB(139, 92, 246)
    let themeColor = Color(red: 0.55, green: 0.36, blue: 0.96)
    // Disabled Color: #b2aadf -> RGB(178, 170, 223)
    let disabledThemeColor = Color(red: 0.70, green: 0.67, blue: 0.87)

    @State private var typewriterIndex = 0
    let typewriterPhrases = ["GO PAPERLESS", "ONE SCAN ACCESS", "STAY SECURE"]
    @State private var currentPhrase = "GO PAPERLESS"

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 50))
                .foregroundColor(themeColor) // Updated Logo Color
                .padding(.top, 20)
            
            TypewriterText(text: currentPhrase)
                .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2)) // Dark Navy Text
                .frame(height: 40) // Fixed height to prevent jumping
                .onAppear {
                    startTypewriterCycle()
                }
            
            Text("Sign in to your secure vault")
                .foregroundColor(.gray)

            VStack(alignment: .leading, spacing: 5) {
                Text("Mobile Number")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.4))
                
                CustomTextField(placeholder: "Enter 10-digit number", text: $phoneNumber, keyboardType: .numberPad)
                    .onChange(of: phoneNumber) { newValue in
                        if newValue.count > 10 {
                            phoneNumber = String(newValue.prefix(10))
                        }
                    }

            }
            .padding(.top, 20)

            Button(action: {
                withAnimation {
                    showMPIN = true
                }
            }) {
                Text("Get OTP") 
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isValidNumber ? themeColor : disabledThemeColor)
                    .foregroundColor(.white)
                    .cornerRadius(15)
            }
            .disabled(!isValidNumber)
            .padding(.top, 10)

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
    }
    func startTypewriterCycle() {
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            typewriterIndex = (typewriterIndex + 1) % typewriterPhrases.count
            currentPhrase = typewriterPhrases[typewriterIndex]
        }
    }
}