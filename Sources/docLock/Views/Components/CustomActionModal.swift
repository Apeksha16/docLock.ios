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
    
    @State private var sheetOffset: CGFloat = 800
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        onCancel()
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
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            onPrimaryAction()
                        }
                    }) {
                        Text(primaryButtonText)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(primaryButtonColor)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                    .padding(.horizontal, 30)
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            onCancel()
                        }
                    }) {
                        Text(primaryButtonColor == .red ? "Wait, I changed my mind" : "Cancel") // Dynamic text based on context or passed in
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                    }
                    .padding(.bottom, 50)
                }
            }
            .background(
                Color.white
                    .edgesIgnoringSafeArea(.bottom) // Extend background to very bottom
            )
            .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight])) // Clip top corners only
            .offset(y: sheetOffset)
            .frame(maxHeight: .infinity, alignment: .bottom)
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
