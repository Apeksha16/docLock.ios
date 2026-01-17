import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthService()
    @State private var showSplash = true
    @State private var showMPIN = false
    @State private var showSignup = false
    @State private var mobileNumber = "" // Store mobile number for MPIN view
    @State private var fullName = "" // Store full name for signup flow
    @State private var isLoginFlow = true // Track if MPIN is for login or signup
    @State private var toastMessage: String?
    @State private var toastType: ToastType = .error

    var body: some View {
        ZStack {
            if showSplash {
                SplashScreenView()
                    .transition(.opacity)
            } else {
                if authService.isAuthenticated {
                    DashboardView(isAuthenticated: Binding(
                        get: { authService.isAuthenticated },
                        set: { newValue in
                            authService.isAuthenticated = newValue
                            if !newValue {
                                showMPIN = false
                            }
                        }
                    ), authService: authService)
                } else {
                    ZStack {
                        // Background - Dark Navy Blue
                        Color(red: 0.05, green: 0.07, blue: 0.2) // Deep Navy Blue
                            .edgesIgnoringSafeArea(.all)

                        VStack {
                            Spacer()
                            // Bottom Sheet
                            BottomSheetView {
                                if showMPIN {
                                    MPINView(
                                        mobileNumber: mobileNumber,
                                        authService: authService,
                                        isLoginFlow: isLoginFlow,
                                        fullName: fullName,
                                        onBack: {
                                            withAnimation {
                                                showMPIN = false
                                                if !isLoginFlow {
                                                    showSignup = true
                                                }
                                            }
                                        }
                                    )
                                    .transition(.move(edge: .trailing))
                                    .gesture(
                                        DragGesture()
                                            .onEnded { value in
                                                // Swipe right to go back
                                                if value.translation.width > 50 {
                                                    withAnimation {
                                                        showMPIN = false
                                                        if !isLoginFlow {
                                                            showSignup = true
                                                        }
                                                    }
                                                }
                                            }
                                    )
                                } else if showSignup {
                                    SignupView(
                                        prefilledMobile: mobileNumber,
                                        showMPIN: $showMPIN,
                                        showLogin: Binding(get: { !showSignup }, set: { _ in 
                                            withAnimation {
                                                showSignup = false
                                                mobileNumber = ""
                                            }
                                        }),
                                        onGetOTP: { mobile, name in
                                            mobileNumber = mobile
                                            fullName = name
                                            isLoginFlow = false
                                            withAnimation {
                                                showMPIN = true
                                            }
                                        }
                                    )
                                    .transition(.move(edge: .trailing))
                                } else {
                                    LoginView(
                                        authService: authService,
                                        showSignup: $showSignup,
                                        onMobileVerified: { mobile, exists in
                                            mobileNumber = mobile
                                            if exists {
                                                // Mobile exists, go to MPIN for login
                                                isLoginFlow = true
                                                withAnimation {
                                                    showMPIN = true
                                                    toastMessage = "Mobile number verified"
                                                    toastType = .success
                                                }
                                            } else {
                                                // Mobile doesn't exist, go to signup
                                                withAnimation {
                                                    showSignup = true
                                                    toastMessage = "Mobile number not found. Please sign up."
                                                    toastType = .error
                                                }
                                            }
                                        }
                                    )
                                    .transition(.move(edge: .leading))
                                }
                            }
                        }
                    }
                }
            }
            
            // Toast Message
            if let toastMessage = toastMessage {
                ToastView(message: toastMessage, type: toastType, show: .constant(true))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            self.toastMessage = nil
                        }
                    }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation {
                    showSplash = false
                }
            }
        }
        .onChange(of: authService.isAuthenticated) { newValue in
            if newValue {
                toastMessage = authService.successMessage ?? "Login successful"
                toastType = .success
            } else {
                showMPIN = false // Reset to Login screen on logout
                mobileNumber = "" // Clear mobile number on logout
                fullName = "" // Clear full name on logout
                showSignup = false
                isLoginFlow = true
            }
        }
        .onChange(of: authService.successMessage) { message in
            if let message = message, authService.isAuthenticated {
                toastMessage = message
                toastType = .success
            }
        }
        .onChange(of: authService.errorMessage) { message in
            if let message = message {
                toastMessage = message
                toastType = .error
            }
        }
    }
}

#Preview {
    ContentView()
}
