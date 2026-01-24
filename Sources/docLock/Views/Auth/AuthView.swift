import SwiftUI
import UIKit

struct AuthView: View {
    @ObservedObject var authService: AuthService
    var onLoginSuccess: (String) -> Void
    var onSignupSuccess: (String, String) -> Void
    
    // Animation states
    @State private var isAnimating = false
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            // Clean Light Background
            Color(red: 0.96, green: 0.97, blue: 0.99)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                Spacer()
                
                // Main Content
                VStack(spacing: 40) {
                    
                    // Logo Section
                    VStack(spacing: 20) {
                        // Logo Container
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 120, height: 120)
                                .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 5)
                            
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(red: 0.39, green: 0.40, blue: 0.95), Color(red: 0.25, green: 0.20, blue: 0.85)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .scaleEffect(isAnimating ? 1 : 0.8)
                        .opacity(isAnimating ? 1 : 0)
                        
                        // App Title & Tagline
                        VStack(spacing: 12) {
                            Text("DocLock")
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                            
                            Text("Your documents, encrypted & secure")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                    }
                    
                    Spacer().frame(height: 20)
                    
                    // Login Card Section
                    VStack(spacing: 30) {
                        // Google Sign In Button
                        Button(action: signInWithGoogle) {
                            HStack(spacing: 15) {
                                if authService.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "globe")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Text("Continue with Google")
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.39, green: 0.40, blue: 0.95), Color(red: 0.25, green: 0.20, blue: 0.85)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color(red: 0.39, green: 0.40, blue: 0.95).opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .disabled(authService.isLoading)
                        
                        // Security Badge
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(red: 0.16, green: 0.73, blue: 0.56))
                            
                            Text("Secured by AES-256 Encryption")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.gray.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 30)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 30)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: showContent)
                }
                .padding(.bottom, 50)
                
                Spacer()
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            isAnimating = true
        }
        
        withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
            showContent = true
        }
    }
    
    private func signInWithGoogle() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            authService.errorMessage = "Unable to present Google Sign-In"
            return
        }
        
        var topViewController = rootViewController
        while let presented = topViewController.presentedViewController {
            topViewController = presented
        }
        
        authService.signInWithGoogle(presentingViewController: topViewController)
    }
}



