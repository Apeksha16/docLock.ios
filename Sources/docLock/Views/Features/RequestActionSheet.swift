import SwiftUI

struct RequestActionSheet: View {
    let friend: User
    let currentUser: User
    @ObservedObject var friendsService: FriendsService
    @Binding var isPresented: Bool
    
    @State private var message: String = ""
    @State private var isLoading = false
    @State private var sentSuccess = false
    @State private var sheetOffset: CGFloat = 800
    @State private var iconScale: CGFloat = 0.5
    @State private var iconRotation: Double = -180
    @FocusState private var isTextFieldFocused: Bool
    @State private var keyboardHeight: CGFloat = 0
    
    // Theme Color (matching AddFriendView deep red/pink or generic theme)
    // FriendsView uses various colors, but this sheet seems to use a specific gradient.
    // We'll stick to the existing colors but apply the structure.
    
    var body: some View {
        ZStack {
            // Premium Animated Dimmed Background
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }
            
            // Premium Sheet Content
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 0) {
                    // Drag Handle
                    Capsule()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.gray.opacity(0.4),
                                    Color.gray.opacity(0.3)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 50, height: 5)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                    
                    VStack(spacing: 24) {
                        if !sentSuccess {
                            // Premium Animated Header
                            VStack(spacing: 18) {
                                // Premium Icon with Glow
                                ZStack {
                                    // Main Icon Background
                                    RoundedRectangle(cornerRadius: 35)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color(hex: "BF092F"),
                                                    Color(hex: "BF092F").opacity(0.8)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 90, height: 90)
                                    
                                    Image(systemName: "lock.doc.fill")
                                        .font(.system(size: 38, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                .scaleEffect(iconScale)
                                .rotationEffect(.degrees(iconRotation))
                                .padding(.top, 8)
                                
                                VStack(spacing: 8) {
                                    Text("Secure Request")
                                        .font(.system(size: 26, weight: .bold, design: .rounded))
                                        .foregroundStyle(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color(red: 0.05, green: 0.07, blue: 0.2),
                                                    Color(red: 0.1, green: 0.12, blue: 0.25)
                                                ]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                    
                                    Text("Ask \(friend.name) to share safely.")
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundStyle(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.gray.opacity(0.9),
                                                    Color.gray.opacity(0.7)
                                                ]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                }
                            }
                            .padding(.bottom, 8)
                        }
                        
                        if sentSuccess {
                            // Premium Success State
                            VStack(spacing: 25) {
                                ZStack {
                                    // Outer Glow
                                    Circle()
                                        .fill(
                                            RadialGradient(
                                                gradient: Gradient(colors: [
                                                    Color(red: 0.28, green: 0.65, blue: 0.66).opacity(0.3),
                                                    Color.clear
                                                ]),
                                                center: .center,
                                                startRadius: 20,
                                                endRadius: 80
                                            )
                                        )
                                        .frame(width: 160, height: 160)
                                        .scaleEffect(sentSuccess ? 1.2 : 0.8)
                                        .opacity(sentSuccess ? 1 : 0)
                                        .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: true), value: sentSuccess)

                                    // Icon Background
                                    Circle()
                                        .fill(Color(red: 0.9, green: 0.98, blue: 0.98))
                                        .frame(width: 100, height: 100)
                                        .shadow(color: Color(red: 0.28, green: 0.65, blue: 0.66).opacity(0.2), radius: 15, x: 0, y: 10)
                                    
                                    // Checkmark Icon
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 44, weight: .bold))
                                        .foregroundColor(Color(red: 0.28, green: 0.65, blue: 0.66))
                                        .scaleEffect(sentSuccess ? 1.0 : 0.5)
                                        .rotationEffect(.degrees(sentSuccess ? 0 : -90))
                                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: sentSuccess)
                                }
                                .padding(.top, 10)
                                
                                VStack(spacing: 8) {
                                    Text("Request Sent!")
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                                    
                                    Text("We've notified \(friend.name) securely.\nYou'll be alerted when they respond.")
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 40)
                                        .lineSpacing(4)
                                }
                                .padding(.bottom, 20)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 20) // Consistent sheet padding
                            .background(
                                ZStack {
                                    Color.white
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.95, green: 1.0, blue: 0.98),
                                            Color.white
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                }
                            )
                            .cornerRadius(30)
                            .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: -5)
                            .transition(.scale(scale: 0.9).combined(with: .opacity))
                            .onAppear {
                                // Auto-close after 1 second
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        isPresented = false
                                    }
                                }
                            }
                        } else {
                            // Premium Input Area
                            VStack(alignment: .leading, spacing: 10) {
                                Text("PERSONAL NOTE")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(.gray.opacity(0.8))
                                    .tracking(1)
                                
                                TextField("e.g. Hey! Need that insurance policy...", text: $message)
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .padding(16)
                                    .background(
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [
                                                            Color(red: 0.99, green: 0.99, blue: 0.99),
                                                            Color.white
                                                        ]),
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                            
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [
                                                            Color.gray.opacity(0.25),
                                                            Color.gray.opacity(0.1)
                                                        ]),
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 1.5
                                                )
                                        }
                                    )
                                    .focused($isTextFieldFocused)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                                    .accentColor(Color(hex: "BF092F"))
                                    .onSubmit {
                                        isTextFieldFocused = false
                                    }
                                    .disabled(isLoading || sentSuccess) // Disable input when loading or success
                            }
                            .padding(.horizontal, 24)
                            
                            // Premium Action Buttons
                            HStack(spacing: 16) {
                                // Request Card Button
                                PremiumActionButton(
                                    icon: "creditcard.fill",
                                    title: "Ask for Card",
                                    color: .pink,
                                    isLoading: isLoading,
                                    isDisabled: message.count < 3,
                                    action: { sendRequest(type: "card") }
                                )
                                
                                // Request Doc Button
                                PremiumActionButton(
                                    icon: "doc.text.fill",
                                    title: "Ask for Doc",
                                    color: .blue,
                                    isLoading: isLoading,
                                    isDisabled: message.count < 3,
                                    action: { sendRequest(type: "document") }
                                )
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 20)
                        }
                    }
                    .padding(.top, sentSuccess ? 0 : 4)
                }
                .padding(.bottom, keyboardHeight)
                .background(
                    ZStack {
                        if sentSuccess {
                            Color.white
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.95, green: 1.0, blue: 0.98),
                                    Color.white
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        } else {
                            // Glass morphism background
                            RoundedRectangle(cornerRadius: 32)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white,
                                            Color(red: 0.99, green: 0.99, blue: 0.99)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
                )
                .clipShape(RoundedCorner(radius: 32, corners: [.topLeft, .topRight]))
                .overlay(
                   RoundedCorner(radius: 32, corners: [.topLeft, .topRight])
                       .stroke(Color.white.opacity(0.5), lineWidth: 1)
               )
                .offset(y: sheetOffset)
                .shadow(color: Color.black.opacity(0.1), radius: 10, y: -5)
                // Removed max height to allow it to grow with content/keyboard or stay at bottom
            }
        }
        .edgesIgnoringSafeArea(.all)
        .zIndex(150)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { output in
            if let keyboardFrame = output.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeOut(duration: 0.25)) {
                    self.keyboardHeight = keyboardFrame.height
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                self.keyboardHeight = 0
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                sheetOffset = 0
            }
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                iconScale = 1.0
                iconRotation = 0
            }
            // Autofocus the text field immediately
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isTextFieldFocused = true
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height > 0 {
                        sheetOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height > 100 {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            isPresented = false
                        }
                    } else {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            sheetOffset = 0
                        }
                    }
                }
        )
    }
    
    func sendRequest(type: String) {
        // Disable if input is less than 3 characters
        guard message.count >= 3 else {
            return
        }
        
        // First, dismiss the keyboard
        isTextFieldFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        // Show loader after a tiny delay to ensure keyboard dismissal animation starts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isLoading = true
            let msg = self.message
            
            self.friendsService.sendRequest(fromUser: self.currentUser, toFriend: self.friend, requestType: type, message: msg) { success in
                DispatchQueue.main.async {
                    self.isLoading = false
                    if success {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                            self.sentSuccess = true
                        }
                        // Success state will handle auto-close in its onAppear
                    } else {
                        // Handle error - reset loading state
                        self.isLoading = false
                    }
                }
            }
        }
    }
}

// Premium Action Button Component
struct PremiumActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    init(icon: String, title: String, color: Color, isLoading: Bool, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.color = color
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                action()
            }
        }) {
            VStack(spacing: 12) {
                ZStack {
                    // Icon Background
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    color.opacity(0.15),
                                    color.opacity(0.08)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    color,
                                    color.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: color))
                    }
                }
                
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                color,
                                color.opacity(0.8)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                ZStack {
                    // Glass morphism background
                    RoundedRectangle(cornerRadius: 22)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white,
                                    Color(red: 0.99, green: 0.99, blue: 0.99)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Color accent
                    RoundedRectangle(cornerRadius: 22)
                        .fill(color.opacity(0.05))
                    
                    // Border
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    color.opacity(0.3),
                                    color.opacity(0.15)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                }
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .opacity(isDisabled || isLoading ? 0.5 : 1.0)
        }
        .buttonStyle(ActionButtonStyle())
        .disabled(isLoading || isDisabled)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isLoading {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                            isPressed = true
                        }
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isPressed = false
                    }
                }
        )
    }
}

// Action Button Style
struct ActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
