import SwiftUI

struct StorageCircleView: View {
    var label: String = "STORAGE"
    var color: Color = Color(red: 0.3, green: 0.2, blue: 0.9)

    var body: some View {
        ZStack {
            // Concentric Circles
            Circle()
                .fill(Color.white.opacity(0.5))
                .frame(width: 280, height: 280)
                .shadow(color: Color.gray.opacity(0.1), radius: 10, x: 0, y: 5)
            
            Circle()
                .stroke(Color.gray.opacity(0.05), lineWidth: 30)
                .frame(width: 230, height: 230)

            Circle()
                .stroke(Color.gray.opacity(0.05), lineWidth: 170)
                .frame(width: 170, height: 170)
                .mask(Circle().stroke(lineWidth: 20)) // Fix stroke overlap if needed, or just keep simple for now
            // Actually the previous implementation was fine, just keeping stroke circles
             Circle()
                .stroke(Color.gray.opacity(0.05), lineWidth: 20)
                .frame(width: 170, height: 170)
            
            // Decorative dots stack
            VStack(spacing: 4) {
                Circle().fill(Color.blue.opacity(0.5)).frame(width: 12, height: 12)
                Circle().fill(Color.pink.opacity(0.3)).frame(width: 12, height: 12)
                Circle().fill(Color.orange.opacity(0.3)).frame(width: 12, height: 12)
                Spacer()
            }
            .frame(height: 100)
            .offset(y: -40) // Positioned slightly up

            // Center Text
            VStack {
                Text("0%")
                    .font(.system(size: 40, weight: .heavy))
                    .foregroundColor(color) // Dynamic color
                Text(label.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                    .tracking(1)
            }
        }
    }
}
