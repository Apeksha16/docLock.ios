import SwiftUI

struct MPINView: View {
    @Binding var isAuthenticated: Bool
    @State private var mpin = ""
    @FocusState private var isFocused: Bool
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 25) {
            
            if isLoading {
                Spacer()
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.blue)
                Text("Verifying...")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
            } else {
                // Header Icon
                ZStack {
                    Circle()
                        .fill(Color(red: 0.9, green: 0.9, blue: 1.0)) // Light lavender bg
                        .frame(width: 80, height: 80)
                    Image(systemName: "lock.fill") // Simple lock icon
                        .font(.system(size: 35))
                        .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.9)) // Deep purple/blue
                }
                .padding(.top, 20)
                
                Text("Verify it's you")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                Text("Enter the 4-digit code sent to \n******9998") // Hardcoded for demo
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)

                ZStack {
                    // Visual representation - Rounded Squares
                    HStack(spacing: 15) {
                        ForEach(0..<4, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 0.96, green: 0.96, blue: 0.98)) // Very light gray
                                .frame(width: 50, height: 50)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(index < mpin.count ? Color.blue : Color.clear, lineWidth: 1.5)
                                )
                                .overlay(
                                    Text(index < mpin.count ? "•" : "")
                                        .font(.largeTitle)
                                        .bold()
                                        .foregroundColor(.black)
                                )
                        }
                    }
                    
                    // Hidden text field to capture input
                    TextField("", text: $mpin)
                        .keyboardType(.numberPad)
                        .focused($isFocused)
                        .accentColor(.clear)
                        .foregroundColor(.clear)
                        .frame(width: 250, height: 50)
                        .contentShape(Rectangle())
                        .onChange(of: mpin) { newValue in
                            if newValue.count > 4 {
                                mpin = String(newValue.prefix(4))
                            }
                            if mpin.count == 4 {
                                // Auto submit
                                performLogin()
                            }
                        }
                }
                .padding(.vertical, 20)
                
                // Resend Code Link
                Button("Resend code in 30s") {
                    // Action
                }
                .font(.footnote)
                .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.9))
                
                Spacer().frame(height: 20)
            }
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = false
        }
    }
    
    func performLogin() {
        withAnimation {
            isLoading = true
        }
        
        // Simulate network call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                isAuthenticated = true
            }
        }
    }
}
