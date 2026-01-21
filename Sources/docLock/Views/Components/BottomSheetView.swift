import SwiftUI

struct BottomSheetView<Content: View>: View {
    let content: Content
    @State private var sheetOffset: CGFloat = 800

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 0) {
                // Drag Handle
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 6)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                
                content
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    Color(red: 0.98, green: 0.98, blue: 0.96)
                    
                    // Decorative Pops (matching AddFriendView style)
                    GeometryReader { proxy in
                        Circle()
                            .fill(Color(red: 0.55, green: 0.36, blue: 0.96).opacity(0.1))
                            .frame(width: 150, height: 150)
                            .position(x: 50, y: 100)
                            .blur(radius: 20)
                        
                        Circle()
                            .fill(Color(red: 0.55, green: 0.36, blue: 0.96).opacity(0.05))
                            .frame(width: 200, height: 200)
                            .position(x: proxy.size.width - 20, y: 50)
                            .blur(radius: 30)
                    }
                }
                .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight]))
            )
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
            .offset(y: sheetOffset)
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                sheetOffset = 0
            }
        }
    }
}
