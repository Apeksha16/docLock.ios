import SwiftUI
import Combine

struct TypewriterText: View {
    let text: String
    var onComplete: (() -> Void)? = nil
    @State private var animatedText = ""
    @State private var showCursor = true
    @State private var timer: Timer? = nil
    @State private var isDeleting = false
    @State private var isVisible = false

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
            isVisible = true
            animateText()
        }
        .onDisappear {
            // CRITICAL: Clean up all timers to prevent memory leaks
            isVisible = false
            timer?.invalidate()
            timer = nil
        }
        .onChange(of: text) { _ in
            isDeleting = false
            animateText()
        }
        .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
            // Only blink cursor when view is visible
            if isVisible {
                withAnimation {
                    showCursor.toggle()
                }
            }
        }
    }

    private func animateText() {
        timer?.invalidate()
        
        if isDeleting {
            // Delete character by character
            deleteText()
        } else {
            // Type out character by character
            animatedText = ""
            var charIndex = 0
            let chars = Array(text)
            
            timer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { timer in
                if charIndex < chars.count {
                    animatedText.append(chars[charIndex])
                    charIndex += 1
                } else {
                    // Wait a bit before deleting
                    timer.invalidate()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        isDeleting = true
                        deleteText()
                    }
                }
            }
        }
    }
    
    private func deleteText() {
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if !animatedText.isEmpty {
                animatedText.removeLast()
            } else {
                timer.invalidate()
                isDeleting = false
                // Notify completion
                onComplete?()
            }
        }
    }
}

struct TypewriterCycleView: View {
    let phrases: [String]
    @State private var currentIndex = 0
    
    init(phrases: [String]) {
        self.phrases = phrases
    }
    
    var body: some View {
        TypewriterText(
            text: phrases.isEmpty ? "" : phrases[currentIndex],
            onComplete: {
                // Move to next phrase after deletion completes
                if phrases.count > 1 {
                    currentIndex = (currentIndex + 1) % phrases.count
                }
            }
        )
    }
}
