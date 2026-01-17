import SwiftUI

struct LoginView: View {
    @StateObject private var authService = AuthService()
    @State private var mobile: String = ""
    @State private var mpin: String = ""

    // Computed property for mobile validation
    var isMobileValid: Bool {
        guard mobile.count <= 10 else { return false }
        // Check if only digits
        guard CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: mobile)) else { return false }
        
        if mobile.count > 0 {
             let firstDigit = Int(String(mobile.prefix(1))) ?? 0
             if firstDigit <= 5 { return false }
        }
        
        return mobile.count == 10
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("DocLock Login")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 40)

            VStack(alignment: .leading, spacing: 5) {
                TextField("Mobile Number", text: $mobile)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .onChange(of: mobile) { newValue in
                        // Enforce max length 10
                        if newValue.count > 10 {
                            mobile = String(newValue.prefix(10))
                        }
                    }

                if !mobile.isEmpty && !isMobileValid {
                    Text("Enter a valid 10-digit mobile number starting with 6-9")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .padding(.horizontal)

            SecureField("MPIN", text: $mpin)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .padding(.horizontal)

            if let errorMessage = authService.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button(action: {
                print("Login Button Tapped")
                authService.login(mobile: mobile, mpin: mpin)
            }) {
                ZStack {
                    if authService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Login")
                            .fontWeight(.bold)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background((isMobileValid && !mpin.isEmpty && !authService.isLoading) ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)
            .disabled(!isMobileValid || mpin.isEmpty || authService.isLoading)

            Spacer()
        }
        .padding()
        .alert(isPresented: $authService.isAuthenticated) {
            Alert(title: Text("Success"), message: Text("Welcome, \(authService.user?.name ?? "User")!"), dismissButton: .default(Text("OK")))
        }
    }
}
