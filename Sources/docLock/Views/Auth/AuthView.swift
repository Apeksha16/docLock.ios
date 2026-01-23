import SwiftUI
import UIKit

struct AuthView: View {
    @ObservedObject var authService: AuthService
    var onLoginSuccess: (String) -> Void
    var onSignupSuccess: (String, String) -> Void
    
    @State private var isAnimating = false
    @State private var logoScale: CGFloat = 0.8
    @State private var particles: [Particle] = []
    @State private var shimmerOffset: CGFloat = -200
    
    // Premium Colors
    let primaryGradient = LinearGradient(
        colors: [Color(red: 0.39, green: 0.40, blue: 0.95), Color(red: 0.49, green: 0.31, blue: 0.97)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    let secondaryGradient = LinearGradient(
        colors: [Color(red: 0.59, green: 0.33, blue: 0.98), Color(red: 0.37, green: 0.40, blue: 0.96)],
        startPoint: .topTrailing,
        endPoint: .bottomLeading
    )
    
    var body: some View {
        ZStack {
            // Animated Gradient Background
            AnimatedPremiumBackground()
                .ignoresSafeArea()
            
            // Floating Particles
            ForEach(particles) { particle in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.6), Color.white.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .blur(radius: 2)
            }
            
            VStack(spacing: 0) {
                Spacer()
                
                // Premium Glass Card
                VStack(spacing: 35) {
                    // Animated Logo
                    ZStack {
                        // Glow Effect
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(red: 0.59, green: 0.33, blue: 0.98).opacity(0.4),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 60
                                )
                            )
                            .frame(width: 120, height: 120)
                            .blur(radius: 20)
                            .scaleEffect(isAnimating ? 1.2 : 1.0)
                            .opacity(isAnimating ? 0.6 : 0.4)
                            .animation(
                                Animation.easeInOut(duration: 2.0)
                                    .repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                        
                        // Logo
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundStyle(primaryGradient)
                            .scaleEffect(logoScale)
                            .shadow(color: Color(red: 0.59, green: 0.33, blue: 0.98).opacity(0.5), radius: 15, x: 0, y: 5)
                    }
                    .padding(.top, 20)
                    
                    // App Name with Typewriter Effect
                    VStack(spacing: 12) {
                        Text("DocLock")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.white, Color.white.opacity(0.9)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                            .opacity(isAnimating ? 1 : 0)
                            .offset(y: isAnimating ? 0 : 20)
                        
                        Text("Your documents, encrypted & secure")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .opacity(isAnimating ? 1 : 0)
                            .offset(y: isAnimating ? 0 : 20)
                    }
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: isAnimating)
                    
                    Spacer().frame(height: 20)
                    
                    // Premium Google Sign-In Button
                    PremiumGoogleButton(
                        isLoading: authService.isLoading,
                        action: signInWithGoogle
                    )
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 30)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: isAnimating)
                    
                    // Security Badge
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(red: 0.16, green: 0.73, blue: 0.56))
                        
                        Text("Secured by AES-256 Encryption")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 8)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.7), value: isAnimating)
                }
                .padding(40)
                .frame(maxWidth: 500)
                .background(
                    ZStack {
                        // Glassmorphic Background
                        RoundedRectangle(cornerRadius: 40)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 40)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.25),
                                                Color.white.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 40)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.6),
                                                Color.white.opacity(0.2)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                        
                        // Shimmer Effect
                        RoundedRectangle(cornerRadius: 40)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.clear,
                                        Color.white.opacity(0.3),
                                        Color.clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .offset(x: shimmerOffset)
                            .mask(RoundedRectangle(cornerRadius: 40))
                    }
                )
                .shadow(color: Color.black.opacity(0.2), radius: 30, x: 0, y: 15)
                .shadow(color: Color(red: 0.59, green: 0.33, blue: 0.98).opacity(0.3), radius: 40, x: 0, y: 20)
                .padding(.horizontal, 30)
                
                Spacer()
            }
        }
        .onAppear {
            startAnimations()
            generateParticles()
        }
    }
    
    private func startAnimations() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            logoScale = 1.0
            isAnimating = true
        }
        
        // Shimmer animation
        withAnimation(
            Animation.linear(duration: 3.0)
                .repeatForever(autoreverses: false)
        ) {
            shimmerOffset = 400
        }
    }
    
    private func generateParticles() {
        for i in 0..<15 {
            let delay = Double(i) * 0.1
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let particle = Particle(
                    position: CGPoint(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    ),
                    size: CGFloat.random(in: 3...8)
                )
                particles.append(particle)
                
                // Animate particle
                withAnimation(
                    Animation.linear(duration: Double.random(in: 3...6))
                        .repeatForever(autoreverses: false)
                ) {
                    if let index = particles.firstIndex(where: { $0.id == particle.id }) {
                        particles[index].position.y += CGFloat.random(in: 100...300)
                        if particles[index].position.y > UIScreen.main.bounds.height + 50 {
                            particles[index].position.y = -50
                            particles[index].position.x = CGFloat.random(in: 0...UIScreen.main.bounds.width)
                        }
                    }
                }
            }
        }
    }
    
    private func signInWithGoogle() {
        // Get the root view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            authService.errorMessage = "Unable to present Google Sign-In"
            return
        }
        
        // Find the topmost view controller
        var topViewController = rootViewController
        while let presented = topViewController.presentedViewController {
            topViewController = presented
        }
        
        authService.signInWithGoogle(presentingViewController: topViewController)
    }
}

// MARK: - Premium Google Button
struct PremiumGoogleButton: View {
    let isLoading: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var buttonScale: CGFloat = 1.0
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                buttonScale = 0.95
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    buttonScale = 1.0
                }
                action()
            }
        }) {
            HStack(spacing: 15) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.2)
                } else {
                    // Google Icon
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "globe")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                
                Text("Continue with Google")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                ZStack {
                    // Gradient Background
                    LinearGradient(
                        colors: [
                            Color(red: 0.39, green: 0.40, blue: 0.95),
                            Color(red: 0.49, green: 0.31, blue: 0.97)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    
                    // Shine Effect
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.3),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .rotationEffect(.degrees(-45))
                    .offset(x: isPressed ? 300 : -300)
                }
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.5),
                                Color.white.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: Color(red: 0.39, green: 0.40, blue: 0.95).opacity(0.5), radius: 20, x: 0, y: 10)
            .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 5)
        }
        .scaleEffect(buttonScale)
        .disabled(isLoading)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: buttonScale)
    }
}

// MARK: - Animated Background
struct AnimatedPremiumBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        ZStack {
            // Base Gradient
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.15, blue: 0.35),
                    Color(red: 0.25, green: 0.20, blue: 0.45),
                    Color(red: 0.20, green: 0.15, blue: 0.40)
                ],
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            
            // Animated Overlay Gradients
            LinearGradient(
                colors: [
                    Color(red: 0.39, green: 0.40, blue: 0.95).opacity(0.3),
                    Color(red: 0.49, green: 0.31, blue: 0.97).opacity(0.2),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .rotationEffect(.degrees(animateGradient ? 360 : 0))
            
            LinearGradient(
                colors: [
                    Color(red: 0.59, green: 0.33, blue: 0.98).opacity(0.2),
                    Color.clear,
                    Color(red: 0.37, green: 0.40, blue: 0.96).opacity(0.3)
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            .rotationEffect(.degrees(animateGradient ? -360 : 0))
        }
        .onAppear {
            withAnimation(
                Animation.linear(duration: 20)
                    .repeatForever(autoreverses: false)
            ) {
                animateGradient = true
            }
        }
    }
}

// MARK: - Particle Model
struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let size: CGFloat
}


