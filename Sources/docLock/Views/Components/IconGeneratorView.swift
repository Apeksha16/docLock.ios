import SwiftUI

/// A view to generate the DocLock app icon
/// Use this view to create a 1024x1024 icon by:
/// 1. Run this view in a preview or simulator
/// 2. Take a screenshot at 1024x1024 size
/// 3. Export and add to AppIcon.appiconset
struct IconGeneratorView: View {
    var body: some View {
        ZStack {
            // Background gradient matching app theme
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.07, blue: 0.2),
                    Color(red: 0.1, green: 0.12, blue: 0.25)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Lock icon in center
            VStack(spacing: 20) {
                // Lock symbol
                ZStack {
                    // Lock body
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .frame(width: 200, height: 240)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 4)
                        )
                    
                    // Lock shackle
                    Path { path in
                        path.move(to: CGPoint(x: 100, y: 60))
                        path.addArc(
                            center: CGPoint(x: 100, y: 100),
                            radius: 40,
                            startAngle: .degrees(180),
                            endAngle: .degrees(0),
                            clockwise: false
                        )
                        path.addLine(to: CGPoint(x: 140, y: 100))
                        path.addLine(to: CGPoint(x: 140, y: 60))
                        path.closeSubpath()
                    }
                    .fill(Color.white)
                    
                    // Document icon inside lock
                    Image(systemName: "doc.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Color.orange)
                        .offset(y: 20)
                }
                
                // App name
                Text("DocLock")
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 1024, height: 1024)
        .ignoresSafeArea()
    }
}

#Preview {
    IconGeneratorView()
}
