import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background Gradient (Light Pastel)
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.95, green: 0.95, blue: 1.0), Color.white]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            // Card Content
            VStack {
                Spacer()
                
                VStack(spacing: 20) {
                    // Logo
                    Image(systemName: "lock.shield.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(red: 0.8, green: 0.2, blue: 0.8), Color(red: 0.2, green: 0.6, blue: 1.0)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
                        .padding(.top, 40)
                    
                    // App Name
                    Text("DocLock")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                    
                    // Tagline
                    Text("Your secure digital sanctuary")
                        .font(.body)
                        .foregroundColor(.gray)
                        .padding(.bottom, 20)
                    
                    // Loader Dots
                    HStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color(red: 0.7, green: 0.5, blue: 1.0))
                                .frame(width: 10, height: 10)
                                .opacity(isAnimating ? 1.0 : 0.3)
                                .animation(
                                    Animation.easeInOut(duration: 0.6)
                                        .repeatForever()
                                        .delay(0.2 * Double(index)),
                                    value: isAnimating
                                )
                        }
                    }
                    .padding(.top, 20)
                    
                    // Status Text
                    Text("DECRYPTING VAULT...")
                        .font(.caption)
                        .fontWeight(.bold)
                        .tracking(2) // Letter spacing
                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.9))
                        .padding(.bottom, 40)
                }
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(30)
                .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 10)
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    SplashScreenView()
}
