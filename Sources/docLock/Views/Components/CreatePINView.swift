import SwiftUI

struct CreatePINView: View {
    @Binding var isPresented: Bool
    @ObservedObject var authService: AuthService
    @State private var pin: String = ""
    @State private var isLoading = false
    @State private var shakeDots = false
    @State private var toastMessage: String?
    @State private var toastType: ToastType = .error
    
    @State private var step: PinStep = .create
    @State private var firstPin: String = ""
    
    enum PinStep {
        case create
        case confirm
    }
    
    // UI Constants based on screenshot
    let dotSize: CGFloat = 16
    let dotSpacing: CGFloat = 20
    let keypadButtonSize: CGFloat = 70
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag Handle - Removed
            Color.clear
                .frame(height: 30)
            
            // Title
            Text(step == .create ? "Change MPIN" : "Confirm MPIN")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                .padding(.bottom, 8)
                .id(step) // Animate transition if needed
                .transition(.opacity)
            
            // Subtitle
            Text(step == .create ? "Enter your new 4-digit PIN" : "Re-enter to confirm")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.bottom, 40)
            
            // PIN Dots Overlay
            HStack(spacing: dotSpacing) {
                ForEach(0..<4) { index in
                    Circle()
                        .fill(index < pin.count ? Color(red: 0.1, green: 0.8, blue: 0.7) : Color.gray.opacity(0.2))
                        .frame(width: dotSize, height: dotSize)
                }
            }
            .modifier(ShakeEffect(animatableData: shakeDots ? 1 : 0))
            .padding(.bottom, 60)
            
            // Keypad
            VStack(spacing: 25) {
                ForEach(0..<3) { row in
                    HStack(spacing: 40) {
                        ForEach(1...3, id: \.self) { col in
                            let number = row * 3 + col
                            KeypadButton(number: "\(number)", action: {
                                appendDigit("\(number)")
                            })
                            .disabled(isLoading)
                        }
                    }
                }
                
                HStack(spacing: 40) {
                    Spacer().frame(width: keypadButtonSize) // Empty space for alignment
                    
                    KeypadButton(number: "0", action: {
                        appendDigit("0")
                    })
                    .disabled(isLoading)
                    
                    Button(action: {
                        deleteDigit()
                    }) {
                        Image(systemName: "delete.left.fill")
                            .font(.title2)
                            .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                            .frame(width: keypadButtonSize, height: keypadButtonSize)
                            .contentShape(Rectangle()) // Better touch area
                    }
                    .disabled(isLoading)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
            
            // Loading Indicator / Spacer
            if isLoading {
                ProgressView()
                    .padding(.bottom, 20)
            } else {
                Spacer().frame(height: 40) // Placeholder for layout stability
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .presentationDetents([.height(680)]) // Keep height constraint but fill it
        .presentationDragIndicator(.visible)
        .animation(.easeInOut, value: step)
        .overlay(
            Group {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.3)
                            .edgesIgnoringSafeArea(.all)
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    }
                }
            }
        )
    }
    
    func appendDigit(_ digit: String) {
        if pin.count < 4 {
            pin.append(digit)
            if pin.count == 4 {
                handlePinComplete()
            }
        }
    }
    
    func handlePinComplete() {
        if step == .create {
            // Move to Confirm Step
            firstPin = pin
            
            // Small delay for user to see the last dot filled
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                pin = ""
                step = .confirm
            }
        } else {
            // Verify Confirmation
            if pin == firstPin {
                // Match! Call API
                updateMPIN()
            } else {
                // Mismatch
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
                withAnimation {
                    shakeDots = true
                    pin = ""
                    // Optionally go back to start or stay on confirm? 
                    // Usually better to let them try confirm again, or reset everything if strictly secure.
                    // Let's reset to confirm attempt for now. 
                    // User said "confirm the mpin again and once it is same then update".
                    // If they fail validation, maybe they forgot first one? 
                    // Let's stay on confirm step but clear it.
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    shakeDots = false
                }
            }
        }
    }
    
    func updateMPIN() {
        isLoading = true
        authService.updateMPIN(mpin: pin) { success, errorMsg in
            isLoading = false
            if success {
                // Success Feedback
                 let generator = UINotificationFeedbackGenerator()
                 generator.notificationOccurred(.success)
                withAnimation {
                    isPresented = false
                }
            } else {
                // API Error
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
                withAnimation {
                    shakeDots = true
                    pin = ""
                    step = .create // Reset flow on API failure? Or just stay?
                    // Safe to reset to start to ensure they know what they are setting.
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    shakeDots = false
                }
            }
        }
    }
    
    func deleteDigit() {
        if !pin.isEmpty {
            pin.removeLast()
        } else if step == .confirm {
             // Optional: Allow deleting back to step 1?
             // For simplicity, just let them clear pin.
             // If pin is empty and they hit delete, maybe go back to create?
             step = .create
             pin = firstPin // Restore first pin so they can edit it? Or just clear?
             // Let's just go back to clear.
             pin = ""
        }
    }
}

struct KeypadButton: View {
    let number: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(number)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 70, height: 70)
                .background(Color(red: 0.05, green: 0.07, blue: 0.15)) // Dark Navy
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
        }
    }
}

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0))
    }
}
