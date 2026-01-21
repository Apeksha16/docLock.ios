import SwiftUI

struct MPINView: View {
    let mobileNumber: String
    @ObservedObject var authService: AuthService
    let isLoginFlow: Bool // true for login, false for signup
    let fullName: String // Full name for signup flow
    var onBack: () -> Void
    
    @State private var mpin = ""
    @FocusState private var isFocused: Bool
    @State private var errorMessage: String?

    var maskedMobileNumber: String {
        guard mobileNumber.count == 10 else {
            return "******" + (mobileNumber.isEmpty ? "9998" : String(mobileNumber.suffix(4)))
        }
        return "******" + String(mobileNumber.suffix(4))
    }
    
    var body: some View {
        ScrollViewReader { scrollProxy in // START ScrollViewReader
            ScrollView(showsIndicators: false) {
                VStack(spacing: 25) {
                    // ID for scrolling
                    Color.clear.frame(height: 1).id("Top")
            
            // Header Icon
            ZStack {
                Circle()
                    .fill(Color(red: 0.9, green: 0.9, blue: 1.0)) // Light lavender bg
                    .frame(width: 80, height: 80)
                Image(systemName: "lock.fill") // Simple lock icon
                    .font(.system(size: 35))
                    .foregroundColor(Color(red: 0.55, green: 0.36, blue: 0.96)) // Theme color
            }
            .padding(.top, 20)
            
            Text("Verify it's you")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            Text("Enter the 4-digit code sent to \n\(maskedMobileNumber)")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)

            ZStack {
                // Visual representation - Rounded Squares
                HStack(spacing: 15) {
                    ForEach(0..<4, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.96, green: 0.96, blue: 0.98)) // Very light gray
                            .frame(width: 50, height: 50)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        (isFocused && index == mpin.count) ? Color(red: 0.55, green: 0.36, blue: 0.96) : // Active focus
                                        (index < mpin.count ? Color(red: 0.55, green: 0.36, blue: 0.96) : Color.clear), // Filled
                                        lineWidth: 2
                                    )
                            )
                            .overlay(
                                Text(index < mpin.count ? "•" : "")
                                    .font(.title)
                                    .bold()
                                    .foregroundColor(.black)
                            )
                    }
                }
                
                // Hidden text field to capture input
                TextField("", text: $mpin)
                    .keyboardType(.numberPad)
                    .focused($isFocused)
                    .accentColor(.clear)
                    .foregroundColor(.clear)
                    .frame(width: 250, height: 50)
                    .contentShape(Rectangle())
                    .disabled(authService.isLoading) // Disable input while verifying
                    .onChange(of: mpin) { newValue in
                        // Filter out non-numeric characters
                        let filtered = newValue.filter { $0.isNumber }
                        
                        if filtered != newValue {
                            mpin = filtered
                        }
                        
                        // Limit to 4 digits
                        if mpin.count > 4 {
                            mpin = String(mpin.prefix(4))
                        }
                        
                        // Clear error when typing
                        if errorMessage != nil {
                            errorMessage = nil
                        }
                        
                        // Auto submit when 4 digits entered with delay
                        if mpin.count == 4 {
                            // Close keyboard to show the full UI state
                            isFocused = false 
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                if isLoginFlow {
                                    performLogin()
                                } else {
                                    performSignup()
                                }
                            }
                        }
                    }
            }
            .padding(.vertical, 20)
            
            if authService.isLoading {
                VStack(spacing: 15) {
                    ProgressView()
                        .scaleEffect(1.2) // Slightly smaller than before to match inline style
                        .tint(Color(red: 0.55, green: 0.36, blue: 0.96))
                    Text("Verifying...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 20) // Add some bottom padding
            } else {
                // Error Message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, 8)
                }
                
                // Resend Code Link
                Button("Resend code in 30s") {
                    // Action
                }
                .font(.footnote)
                .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.9))
                
                Spacer().frame(height: 20)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 40)
        } // End ScrollView
        .onChange(of: isFocused) { focused in
            if !focused { withAnimation { scrollProxy.scrollTo("Top", anchor: .top) } }
        }
        .onTapGesture {
            isFocused = false
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isFocused = false
                }
            }
        }

        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = false
        }
        .onChange(of: authService.errorMessage) { newError in
            errorMessage = newError
            if newError != nil {
                mpin = "" // Clear MPIN on error
            }
        }
        .onChange(of: authService.isAuthenticated) { isAuth in
            // When authentication succeeds, the ContentView will handle navigation
            if isAuth {
                mpin = "" // Clear MPIN on success
                errorMessage = nil
            }
        }
        .onChange(of: authService.isDeviceMismatch) { isMismatch in
            if isMismatch {
                // Return to login screen
                onBack()
                
                // Reset the flag immediately so it doesn't trigger again unexpectedly
                // Using a small delay to ensure view transition starts
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    authService.isDeviceMismatch = false
                }
            }
        }
        } // End ScrollViewReader
    } // End Body
    
    func performLogin() {
        errorMessage = nil
        authService.login(mobile: mobileNumber, mpin: mpin)
    }
    
    func performSignup() {
        errorMessage = nil
        // For signup, we need the full name. Since we don't have it here,
        // we'll need to get it from ContentView. For now, let's use an empty name
        // but ideally this should be passed from SignupView
        authService.signup(mobile: mobileNumber, mpin: mpin, name: fullName)
    }
}
