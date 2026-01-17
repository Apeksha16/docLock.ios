import SwiftUI

struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .focused($isFocused)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Color.blue : Color.gray.opacity(0.3), lineWidth: isFocused ? 2 : 1)
            )
            .cornerRadius(12)
            .keyboardType(keyboardType)
    }
}
