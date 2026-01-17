import SwiftUI

struct ContentView: View {
    @State private var showMPIN = false
    @State private var isAuthenticated = false
    @State private var typewriterIndex = 0
    let typewriterPhrases = ["Go PAPERLESS", "ONE SCAN ACCESS", "STAY SECURE"]
    @State private var currentPhrase = "Go PAPERLESS"

    var body: some View {
        if isAuthenticated {
            DashboardView(isAuthenticated: $isAuthenticated)
        } else {
            ZStack {
                // Background - Dark Navy
                Color(red: 0.05, green: 0.07, blue: 0.2) // Deep Navy Blue
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    // Typewriter Effect Area - White text now
                    Spacer()
                    TypewriterText(text: currentPhrase)
                        .foregroundColor(.white)
                        .padding(.bottom, 30) // Give space for the sheet
                        
                    // Bottom Sheet
                    BottomSheetView {
                        if showMPIN {
                            MPINView(isAuthenticated: $isAuthenticated)
                                .transition(.move(edge: .trailing))
                                .gesture(
                                    DragGesture()
                                        .onEnded { value in
                                            // Swipe right to go back
                                            if value.translation.width > 50 {
                                                withAnimation {
                                                    showMPIN = false
                                                }
                                            }
                                        }
                                )
                        } else {
                            LoginView(showMPIN: $showMPIN)
                                .transition(.move(edge: .leading))
                        }
                    }
                    .frame(height: 400) // Adjust height as needed
                }
            }
            .onAppear {
                startTypewriterCycle()
            }
        }
    }
    
    func startTypewriterCycle() {
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            typewriterIndex = (typewriterIndex + 1) % typewriterPhrases.count
            currentPhrase = typewriterPhrases[typewriterIndex]
        }
    }
}

#Preview {
    ContentView()
}
