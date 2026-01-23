import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthService()
    @State private var showSplash = true
    @State private var showMPIN = false
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
                }
                if !authService.isAuthenticated {
                    if showMPIN {
                        MPINView(
                            mobileNumber: mobileNumber,
                            authService: authService,
                            isLoginFlow: isLoginFlow,
                            fullName: fullName,
                            onBack: {
                                withAnimation(.spring()) {
                                    showMPIN = false
                                }
                            }
                        )
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
                    } else {
                        AuthView(
                            authService: authService,
                            onLoginSuccess: { mobile in
                                mobileNumber = mobile
                                isLoginFlow = true
                                withAnimation(.spring()) {
                                    showMPIN = true
                                }
                            },
                            onSignupSuccess: { name, mobile in
                                fullName = name
                                mobileNumber = mobile
                                isLoginFlow = false
                                withAnimation(.spring()) {
                                    showMPIN = true
                                }
                            }
                        )
                        .transition(.opacity)
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
            // Attempt to restore session immediately
            authService.restoreSession()
            
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
