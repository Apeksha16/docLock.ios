import SwiftUI

struct TypewriterText: View {
    let text: String
    @State private var animatedText = ""
    @State private var showCursor = true
    @State private var timer: Timer? = nil

    var body: some View {
        HStack(spacing: 0) {
            Text(animatedText)
                .font(.system(size: 28, weight: .bold, design: .rounded))
            
            Text("|")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(showCursor ? .primary : .clear)
                .padding(.bottom, 2)
        }
        .multilineTextAlignment(.center)
        .onAppear {
            animateText()
            startCursorBlink()
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
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { timer in
            if charIndex < chars.count {
                animatedText.append(chars[charIndex])
                charIndex += 1
            } else {
                timer.invalidate()
            }
        }
    }
    
    private func startCursorBlink() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            withAnimation {
                showCursor.toggle()
            }
        }
    }
}
