import SwiftUI

struct CustomActionModal: View {
    let icon: String // system name
    let iconBgColor: Color
    let title: String
    let subtitle: String?
    let message: String
    let primaryButtonText: String
    let primaryButtonColor: Color
    let onPrimaryAction: () -> Void
    let onCancel: () -> Void
    var isLoading: Bool = false // Optional loading state
    
    @State private var sheetOffset: CGFloat = 800
    
    var body: some View {
        ZStack {
            // Glass background effect - blurred and dimmed
            ZStack {
                // Base dimmed background
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                
                // Blur effect for glassmorphism
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .edgesIgnoringSafeArea(.all)
            }
            .onTapGesture {
                if !isLoading {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        onCancel()
                    }
                }
            }
            
            VStack(spacing: 20) {
                // Drag Handle
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 4)
                    .padding(.top, 10)
                
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(iconBgColor)
                        .frame(width: 60, height: 60)
                    Image(systemName: icon)
                        .font(.title)
                        .foregroundColor(.white)
                }
                .padding(.top, 10)
                
                // Text Content
                VStack(spacing: 8) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    
                    Text(message)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 30)
                        .fixedSize(horizontal: false, vertical: true) // Allow text wrapping
                }
                
                // Buttons
                VStack(spacing: 15) {
                    Button(action: {
                        if !isLoading {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                onPrimaryAction()
                            }
                        }
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            }
                            Text(primaryButtonText)
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isLoading ? primaryButtonColor.opacity(0.7) : primaryButtonColor)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                    }
                    .disabled(isLoading)
                    .padding(.horizontal, 30)
                    
                    Button(action: {
                        if !isLoading {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                onCancel()
                            }
                        }
                    }) {
                        Text(primaryButtonColor == .red ? "Wait, I changed my mind" : "Cancel") // Dynamic text based on context or passed in
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                    }
                    .disabled(isLoading)
                    .padding(.bottom, 50)
                }
            }
            .background(
                ZStack {
                    // Glass effect background with slight translucency
                    Color.white.opacity(0.95)
                    
                    // Subtle decorative blur elements for depth
                    GeometryReader { proxy in
                        Circle()
                            .fill(iconBgColor.opacity(0.1))
                            .frame(width: 200, height: 200)
                            .position(x: proxy.size.width * 0.8, y: -50)
                            .blur(radius: 40)
                        
                        Circle()
                            .fill(iconBgColor.opacity(0.05))
                            .frame(width: 150, height: 150)
                            .position(x: proxy.size.width * 0.2, y: proxy.size.height * 0.3)
                            .blur(radius: 30)
                    }
                }
                .edgesIgnoringSafeArea(.bottom) // Extend background to very bottom
            )
            .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight])) // Clip top corners only
            .offset(y: sheetOffset)
            .frame(maxHeight: UIScreen.main.bounds.height * 0.6, alignment: .bottom)
            .transition(.move(edge: .bottom))
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    sheetOffset = 0
                }
            }
        }
        .zIndex(100)
        .edgesIgnoringSafeArea(.all)
    }
}

// Extension to round specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
