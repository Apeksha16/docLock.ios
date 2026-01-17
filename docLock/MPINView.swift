import SwiftUI

struct MPINView: View {
    @Binding var isAuthenticated: Bool
    @State private var mpin = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 25) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
                .padding(.top, 20)
            
            Text("Enter MPIN")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Please enter your 4-digit security PIN")
                .foregroundColor(.gray)

            ZStack {
                // Visual representation
                HStack(spacing: 20) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .stroke(Color.blue, lineWidth: 2)
                            .background(Circle().fill(index < mpin.count ? Color.blue : Color.clear))
                            .frame(width: 20, height: 20)
                    }
                }
                
                // Hidden text field to capture input - Placed ON TOP of visuals
                TextField("", text: $mpin)
                    .keyboardType(.numberPad)
                    .focused($isFocused)
                    .accentColor(.clear)
                    .foregroundColor(.clear)
                    .frame(width: 200, height: 50) // Ensure it has size
                    .contentShape(Rectangle()) // Make the whole area tappable
                    .onChange(of: mpin) { newValue in
                        if newValue.count > 4 {
                            mpin = String(newValue.prefix(4))
                        }
                        if mpin.count == 4 {
                             // Auto submit logic if desired
                        }
                    }
            }
            .padding(.vertical, 20)
            // Removed onAppear auto-focus

            Button(action: {
                if mpin.count == 4 {
                    withAnimation {
                        isAuthenticated = true
                    }
                }
            }) {
                Text("Unlock")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 0.7, green: 0.75, blue: 1.0))
                    .foregroundColor(.white)
                    .cornerRadius(15)
            }

            Spacer().frame(height: 20)
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = false
        }
    }
}
