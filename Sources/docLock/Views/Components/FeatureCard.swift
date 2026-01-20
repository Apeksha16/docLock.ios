import SwiftUI

struct FeatureCard: View {
    let icon: String // System icon name
    let title: String
    let iconColor: Color
    let iconBgColor: Color

    var body: some View {
        VStack(spacing: 12) {
            // Icon Container - Soft Circle with Gradient
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [iconBgColor.opacity(0.25), iconBgColor.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(iconColor)
            }
            .padding(.top, 8)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
            }
            .padding(.bottom, 10)
        }
        .frame(width: 105, height: 130)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: iconColor.opacity(0.08), radius: 8, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.gray.opacity(0.05), lineWidth: 1)
        )
    }
}
