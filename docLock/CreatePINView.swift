import SwiftUI

struct CreatePINView: View {
    @Binding var isPresented: Bool
    @State private var pin: String = ""
    
    // UI Constants based on screenshot
    let dotSize: CGFloat = 16
    let dotSpacing: CGFloat = 20
    let keypadButtonSize: CGFloat = 70
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag Handle
            Image(systemName: "chevron.compact.down")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 12)
                .foregroundColor(.gray.opacity(0.4))
                .padding(.top, 15)
                .padding(.bottom, 30)
            
            // Title
            Text("Create PIN")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                .padding(.bottom, 8)
            
            // Subtitle
            Text("Create a 4-digit PIN")
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
                        }
                    }
                }
                
                HStack(spacing: 40) {
                    Spacer().frame(width: keypadButtonSize) // Empty space for alignment
                    
                    KeypadButton(number: "0", action: {
                        appendDigit("0")
                    })
                    
                    Button(action: {
                        deleteDigit()
                    }) {
                        Image(systemName: "delete.left")
                            .font(.title2)
                            .foregroundColor(Color(red: 0.4, green: 0.4, blue: 1.0)) // Blue like screenshot
                            .frame(width: keypadButtonSize, height: keypadButtonSize)
                            .background(Color.white) // Empty background
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.blue, lineWidth: 1.5)
                            )
                            .cornerRadius(15) // Wait, design has image inside a box? 
                            // Actually looking at screenshot, backspace is an icon on bottom right
                            // Let's match the "X" icon inside a box roughly
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .background(Color.white)
        .cornerRadius(30)
    }
    
    func appendDigit(_ digit: String) {
        if pin.count < 4 {
            pin.append(digit)
            if pin.count == 4 {
                // Pin Complete Logic
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    // For now, just dismiss, later save logic
                    isPresented = false
                }
            }
        }
    }
    
    func deleteDigit() {
        if !pin.isEmpty {
            pin.removeLast()
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
