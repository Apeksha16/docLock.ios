import SwiftUI

struct BottomSheetView<Content: View>: View {
    let content: Content

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
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}
