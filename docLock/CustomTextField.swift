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
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke((isFocused || !text.isEmpty) ? Color(red: 0.55, green: 0.36, blue: 0.96) : Color.gray.opacity(0.3), lineWidth: 1)
            )
            .keyboardType(keyboardType)
    }
}
