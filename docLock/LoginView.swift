import SwiftUI

struct LoginView: View {
    @Binding var showMPIN: Bool
    @State private var phoneNumber = ""
    
    var isValidNumber: Bool {
        return phoneNumber.count == 10
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
                .padding(.top, 20)
            
            Text("STAY SECURE.")
                .font(.title)
                .fontWeight(.bold)
            
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
                Text("Get MPIN") 
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isValidNumber ? Color(red: 0.7, green: 0.75, blue: 1.0) : Color.gray.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(15)
            }
            .disabled(!isValidNumber)
            .padding(.top, 10)

            HStack {
                Text("New to DocLock?")
                    .foregroundColor(.gray)
                Button("Create Account") {
                    // Action
                }
                .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.9))
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
}
