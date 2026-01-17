import SwiftUI

struct FeatureCard: View {
    let icon: String // System icon name
    let title: String
    let subtitle: String
    let iconColor: Color
    let iconBgColor: Color

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(iconBgColor)
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(iconColor)
            }
            .padding(.top, 5)
            
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(width: 110, height: 130)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.gray.opacity(0.1), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}
