import SwiftUI

struct ContentView: View {
    @State private var showSplash = true
    @State private var showMPIN = false
    @State private var showSignup = false
    @State private var isAuthenticated = false

    var body: some View {
        ZStack {
            if showSplash {
                SplashScreenView()
                    .transition(.opacity)
            } else {
                if isAuthenticated {
                    DashboardView(isAuthenticated: $isAuthenticated)
                } else {
                    ZStack {
                        if showMPIN {
                            MPINView(isAuthenticated: $isAuthenticated)
                                .transition(.move(edge: .trailing))
                                .gesture(
                                    DragGesture()
                                        .onEnded { value in
                                            // Swipe right to go back
                                            if value.translation.width > 50 {
                                                withAnimation {
                                                    showMPIN = false
                                                }
                                            }
                                        }
                                )
                        } else if showSignup {
                            SignupView(showMPIN: $showMPIN, showLogin: Binding(get: { !showSignup }, set: { _ in showSignup = false }))
                                .transition(.move(edge: .trailing))
                        } else {
                            LoginView(showSignup: $showSignup, showMPIN: $showMPIN)
                                .transition(.move(edge: .leading))
                        }
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
        .onChange(of: isAuthenticated) { newValue in
            if !newValue {
                showMPIN = false // Reset to Login screen on logout
            }
        }
    }
}

#Preview {
    ContentView()
}
