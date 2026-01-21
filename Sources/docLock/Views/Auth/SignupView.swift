import SwiftUI

struct SignupView: View {
    @ObservedObject var authService: AuthService
    let prefilledMobile: String
    var onBack: () -> Void
    var onOTPRequested: (String, String) -> Void // Returns (fullName, mobile)
    
    @State private var fullName = ""
    @State private var phoneNumber = ""
    enum Field: Hashable {
        case name, phone
    }
    @FocusState private var focusedField: Field?
    
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
        ScrollViewReader { scrollProxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 50))
                        .foregroundColor(themeColor)
                        .padding(.top, 20)
                        .id("Top")
            
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
                        .focused($focusedField, equals: .name)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke((focusedField == .name || !fullName.isEmpty) ? Color(red: 0.55, green: 0.36, blue: 0.96) : Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                        .colorScheme(.light)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .phone }

                }
                
                // Mobile Number Input
                VStack(alignment: .leading, spacing: 5) {
                    Text("Mobile Number")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.4))
                    
                    TextField("10-digit mobile number", text: $phoneNumber)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .phone)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke((focusedField == .phone || !phoneNumber.isEmpty) ? Color(red: 0.55, green: 0.36, blue: 0.96) : Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                        .colorScheme(.light)
                        .submitLabel(.done)
                        .onSubmit { focusedField = nil }
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
                onOTPRequested(fullName, phoneNumber)
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
                        onBack()
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
        .padding(.bottom, 40)
        } // End ScrollView
        .onChange(of: focusedField) { focused in
            if focused == nil { withAnimation { scrollProxy.scrollTo("Top", anchor: .top) } }
        }
        .onTapGesture {
            focusedField = nil
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
        .onAppear {
            if !prefilledMobile.isEmpty {
                phoneNumber = prefilledMobile
            }
        }
        } // End ScrollViewReader
    } // End body
}
