import SwiftUI

struct SwipeToDismissModifier: ViewModifier {
    @Environment(\.presentationMode) var presentationMode
    
    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture()
                    .onEnded { value in
                        // Detect swipe from left edge (start location < 50) and substantial movement to right (> 100)
                        if value.startLocation.x < 50 && value.translation.width > 100 {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
            )
    }
}

extension View {
    func swipeToDismiss() -> some View {
        self.modifier(SwipeToDismissModifier())
    }
}
