import SwiftUI

struct StorageCircleView: View {
    var storagePercent: Double
    var cardsPercent: Double
    var qrsPercent: Double
    var selectedCategory: String // "Storage", "Cards", "QRs"
    
    // Fixed Colors (Clean, Vibrant yet Soft)
    let storageColor = Color(red: 0.2, green: 0.4, blue: 0.9) // Blue
    let cardsColor = Color(red: 0.85, green: 0.2, blue: 0.6)   // Pink
    let qrsColor = Color.orange

    var body: some View {
        ZStack {
            // 1. OUTER RING - STORAGE
            CleanRingView(
                percent: storagePercent,
                color: storageColor,
                radius: 125, // Slightly tighter radius
                isSelected: selectedCategory == "Documents"
            )
            
            // 2. MIDDLE RING - CARDS
            CleanRingView(
                percent: cardsPercent,
                color: cardsColor,
                radius: 100,
                isSelected: selectedCategory == "Cards"
            )
            
            // 3. INNER RING - QRs
            CleanRingView(
                percent: qrsPercent,
                color: qrsColor,
                radius: 75,
                isSelected: selectedCategory == "QRs"
            )
            
            // Center Content
            VStack(spacing: 4) {
                Text("\(Int(getSelectedPercent() * 100))%")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(getSelectedColor()) // Matches selected ring color for emphasis
                    .contentTransition(.numericText())
                
                Text(selectedCategory.uppercased())
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                    .tracking(2)
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: selectedCategory)
        }
    }
    
    func getSelectedColor() -> Color {
        switch selectedCategory {
        case "Documents": return storageColor
        case "Cards": return cardsColor
        case "QRs": return qrsColor
        default: return .gray
        }
    }
    
    func getSelectedPercent() -> Double {
        switch selectedCategory {
        case "Documents": return storagePercent
        case "Cards": return cardsPercent
        case "QRs": return qrsPercent
        default: return 0
        }
    }
}

struct CleanRingView: View {
    var percent: Double
    var color: Color
    var radius: CGFloat
    var isSelected: Bool
    
    var body: some View {
        ZStack {
            // Track (Subtle & Clean)
            Circle()
                .stroke(color.opacity(0.08), lineWidth: 12)
                .frame(width: radius * 2, height: radius * 2)
            
            // Progress
            Circle()
                .trim(from: 0, to: CGFloat(percent))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: radius * 2, height: radius * 2)
                .rotationEffect(.degrees(-90))
                .opacity(isSelected ? 1.0 : 0.25) // Fade out unselected rings significantly for "clean" look
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: percent)
                .animation(.easeInOut(duration: 0.3), value: isSelected)
        }
    }
}
