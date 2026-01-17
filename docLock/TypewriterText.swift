import SwiftUI

struct TypewriterText: View {
    let text: String
    @State private var animatedText = ""
    @State private var timer: Timer? = nil

    var body: some View {
        Text(animatedText)
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(.white) // White for dark background
            .multilineTextAlignment(.center)
            .onAppear {
                animateText()
            }
            .onChange(of: text) { _ in
                animateText()
            }
    }

    private func animateText() {
        timer?.invalidate()
        animatedText = ""
        var charIndex = 0
        let chars = Array(text)
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if charIndex < chars.count {
                animatedText.append(chars[charIndex])
                charIndex += 1
            } else {
                timer.invalidate()
            }
        }
    }
}
