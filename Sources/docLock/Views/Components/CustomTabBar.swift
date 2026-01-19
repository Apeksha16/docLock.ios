import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: String
    @Namespace private var animation // Create namespace
    
    var body: some View {
        HStack(spacing: 35) {
            // Home Tab
            TabBarButton(
                icon: "house.fill",
                text: "Home",
                isSelected: selectedTab == "Home",
                color: Color(red: 0.3, green: 0.2, blue: 0.9),
                namespace: animation
            ) {
                withAnimation(.spring()) {
                    selectedTab = "Home"
                }
            }
            
            // Friends Tab
            TabBarButton(
                icon: "person.2.fill",
                text: "Friends",
                isSelected: selectedTab == "Friends",
                color: Color.orange,
                namespace: animation
            ) {
                withAnimation(.spring()) {
                    selectedTab = "Friends"
                }
            }
            
            // Profile Tab
            TabBarButton(
                icon: "person.crop.circle.fill",
                text: "Profile",
                isSelected: selectedTab == "Profile",
                color: Color(red: 0.28, green: 0.65, blue: 0.66),
                namespace: animation
            ) {
                withAnimation(.spring()) {
                    selectedTab = "Profile"
                }
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 8)
        .background(Color.white)
        .cornerRadius(35)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 25) // Reduced outer padding (bar is wider)
        // User asked for "outer padding to less" -> meaning less space between bar and edge.
        // Previous was 15. Wait, 15 is already small.
        // Maybe they meant "padding of outer white container" meaning INSIDE the container?
        // "Make the padding of outer white container to less" -> The white container's padding.
        // inner padding: .padding(.horizontal, 20) -> now 15. .padding(.vertical, 10) -> now 8.
        // "and shift bottombar to more down".
        // I will stick with this. 

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
