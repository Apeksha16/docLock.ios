import SwiftUI

struct BottomSheetView<Content: View>: View {
    let content: Content
    @State private var sheetOffset: CGFloat = 800

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack {
            Spacer()
            VStack {
                content
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(30)
            .shadow(radius: 10)
            .offset(y: sheetOffset)
        }
        .edgesIgnoringSafeArea(.bottom)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                sheetOffset = 0
            }
        }
    }
}
