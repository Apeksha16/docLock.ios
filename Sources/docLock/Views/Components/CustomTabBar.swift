import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: String
    @Namespace private var animation // Create namespace
    
    var body: some View {
        HStack {
            // Home Tab
            TabBarButton(
                icon: "square.grid.2x2",
                text: "Home",
                isSelected: selectedTab == "Home",
                color: Color(red: 0.3, green: 0.2, blue: 0.9),
                namespace: animation
            ) {
                withAnimation(.spring()) {
                    selectedTab = "Home"
                }
            }
            
            Spacer()
            
            // Friends Tab
            TabBarButton(
                icon: "person.3.fill",
                text: "Friends",
                isSelected: selectedTab == "Friends",
                color: Color.orange,
                namespace: animation
            ) {
                withAnimation(.spring()) {
                    selectedTab = "Friends"
                }
            }
            
            Spacer()
            
            // Profile Tab
            TabBarButton(
                icon: "person.fill",
                text: "Profile",
                isSelected: selectedTab == "Profile",
                color: Color.purple,
                namespace: animation
            ) {
                withAnimation(.spring()) {
                    selectedTab = "Profile"
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(Color.white)
        .cornerRadius(40)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 20)
    }
}

struct TabBarButton: View {
    let icon: String
    let text: String // Kept for API compatibility but unused
    let isSelected: Bool
    let color: Color
    let namespace: Namespace.ID // Add namespace
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .white : .gray)
                
                if isSelected {
                    Text(text)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .fixedSize() // Ensure text doesn't truncate
                        .matchedGeometryEffect(id: "TabLabel-\(text)", in: namespace)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, isSelected ? 20 : 0)
            .background(
                ZStack {
                    if isSelected {
                        Capsule()
                            .fill(color)
                            .matchedGeometryEffect(id: "TabBackground-\(text)", in: namespace)
                    }
                }
            )
            .clipShape(Capsule())
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
    }
}
