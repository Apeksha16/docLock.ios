import SwiftUI

struct AddFriendView: View {
    @Binding var isPresented: Bool
    @ObservedObject var authService: AuthService
    @ObservedObject var friendsService: FriendsService
    
    @State private var searchText: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var isFocused: Bool
    
    @State private var sheetOffset: CGFloat = 800
    @State private var iconScale: CGFloat = 0.5
    @State private var iconRotation: Double = -180
    @State private var keyboardHeight: CGFloat = 0
    
    // Confirmation State
    @State private var searchedUser: User?
    @State private var showConfirmation = false
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // Theme Color
    let themeColor = Color(hex: "BF092F")
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 0) {
                dragHandle
                
                // Content changes based on state (Search vs Confirmation)
                if showConfirmation, let user = searchedUser {
                    confirmationContent(user: user)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                } else {
                    searchContent
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                }
            }
            .padding(.bottom, 20)
            .padding(.bottom, keyboardHeight) // Pad content internally so background extends
            .background(
                ZStack {
                    LinearGradient(gradient: Gradient(colors: [.white, Color(red: 0.99, green: 0.99, blue: 0.99)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    
                    // Blush Effects
                    GeometryReader { proxy in
                        // Left Blush
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        themeColor.opacity(0.15),
                                        Color.clear
                                    ]),
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 200
                                )
                            )
                            .frame(width: 400, height: 400)
                            .position(x: 0, y: 50)
                            .blur(radius: 60)
                        
                        // Right Blush
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        themeColor.opacity(0.12),
                                        Color.clear
                                    ]),
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 180
                                )
                            )
                            .frame(width: 350, height: 350)
                            .position(x: proxy.size.width, y: 80)
                            .blur(radius: 50)
                    }
                }
            )
            .clipShape(RoundedCorner(radius: 20, corners: [.topLeft, .topRight]))
             .overlay(
                RoundedCorner(radius: 20, corners: [.topLeft, .topRight])
                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
            )
            .offset(y: sheetOffset)
            // Removed external padding(.bottom, keyboardHeight) to avoid gaps
        }
        .edgesIgnoringSafeArea(.all)
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
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { sheetOffset = 0 }
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                iconScale = 1.0
                iconRotation = 0
            }
            DispatchQueue.main.async { isFocused = true }
        }
        // Alert Modal Layer
        .overlay(
            Group {
                if showAlert {
                     CustomActionModal(
                         icon: "exclamationmark.triangle.fill",
                         iconBgColor: themeColor,
                         title: "Notice",
                         subtitle: nil,
                         message: alertMessage,
                         primaryButtonText: "Okay",
                         primaryButtonColor: themeColor,
                         onPrimaryAction: {
                             withAnimation { showAlert = false }
                         },
                         onCancel: {
                             withAnimation { showAlert = false }
                         }
                     )
                     .zIndex(20)
                }
            }
        )
    }
}

// MARK: - Subviews
private extension AddFriendView {
    var dragHandle: some View {
        Capsule()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 50, height: 5)
            .padding(.top, 12)
            .padding(.bottom, 8)
    }
    
    // MARK: - Search State Views
    
    var searchContent: some View {
        VStack(spacing: 24) {
            searchHeaderIcon
            searchHeaderTexts
            searchInputField
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.bottom, -10)
            }
            
            searchActionButtons
        }
        .padding(.bottom, 8)
    }
    
    var searchHeaderIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 35)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [themeColor, themeColor.opacity(0.8)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 90, height: 90)
            
            Image(systemName: "person.badge.plus")
                .font(.system(size: 38, weight: .semibold))
                .foregroundColor(.white)
        }
        .scaleEffect(iconScale)
        .rotationEffect(.degrees(iconRotation))
        .padding(.top, 8)
    }
    
    var searchHeaderTexts: some View {
        VStack(spacing: 8) {
            Text("Connect with People")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
            
            Text("Paste a User ID below to add them\nto your secure circle.")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)
        }
    }
    
    var searchInputField: some View {
        TextField("Paste Unique ID...", text: $searchText)
            .font(.headline)
            .foregroundColor(.black)
            .padding()
            .background(Color(red: 0.96, green: 0.96, blue: 0.98))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
            .focused($isFocused)
            .padding(.horizontal, 24)
            .submitLabel(.search)
            .onSubmit {
                searchUser()
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .onChange(of: searchText) { newValue in
                let filtered = newValue.filter { $0.isLetter || $0.isNumber }
                if filtered != newValue { searchText = filtered }
            }
    }
    
    var searchActionButtons: some View {
        VStack(spacing: 16) {
            Button(action: searchUser) {
                ZStack {
                    if isLoading {
                         ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Find User")
                            .fontWeight(.bold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(LinearGradient(gradient: Gradient(colors: [themeColor, themeColor.opacity(0.8)]), startPoint: .leading, endPoint: .trailing))
                .foregroundColor(.white)
                .cornerRadius(15)
            }
            .padding(.horizontal, 24)
            .disabled(isLoading || searchText.count < 3)
            .opacity((isLoading || searchText.count < 3) ? 0.6 : 1.0)
            
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isPresented = false
                }
            }) {
                Text("Wait, I changed my mind")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
            }
        }
    }
    
    // MARK: - Confirmation State Views
    
    func confirmationContent(user: User) -> some View {
        VStack(spacing: 24) {
            confirmationHeaderIcon(user: user)
            confirmationTexts(user: user)
            
             if let error = errorMessage {
                  Text(error)
                      .font(.caption)
                      .foregroundColor(.red)
                      .padding(.bottom, -10)
              }
            
            confirmationActionButtons
        }
        .padding(.bottom, 8)
    }
    
    func confirmationHeaderIcon(user: User) -> some View {
        AsyncImage(url: URL(string: user.profileImageUrl ?? "")) { phase in
            if let image = phase.image {
                image.resizable().aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .foregroundColor(.gray.opacity(0.3))
            }
        }
        .frame(width: 90, height: 90)
        .clipShape(Circle())
        .overlay(Circle().stroke(themeColor, lineWidth: 3))
        .shadow(color: themeColor.opacity(0.3), radius: 10, x: 0, y: 5)
        .padding(.top, 8)
    }
    
    func confirmationTexts(user: User) -> some View {
        VStack(spacing: 8) {
            Text(user.name)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
            
            Text("Secure Connection Found")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.green)
                .padding(.bottom, 4)
            
            Text("Are you sure you want to add this person to your secure circle?")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)
        }
    }
    
    var confirmationActionButtons: some View {
        VStack(spacing: 16) {
            Button(action: addFriend) {
                ZStack {
                    if isLoading {
                         ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Yes, Add Friend")
                            .fontWeight(.bold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(LinearGradient(gradient: Gradient(colors: [themeColor, themeColor.opacity(0.8)]), startPoint: .leading, endPoint: .trailing))
                .foregroundColor(.white)
                .cornerRadius(15)
            }
            .padding(.horizontal, 24)
            .disabled(isLoading)
            
            Button(action: {
                withAnimation {
                    showConfirmation = false
                    errorMessage = nil
                    isFocused = true // Refocus input if going back
                }
            }) {
                Text("Cancel")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
            }
        }
    }
    
    // MARK: - Actions
    
    func searchUser() {
        guard !searchText.isEmpty else { return }
        
        // 1. Check Self-Add (Local Check)
        if let currentUser = authService.user, 
           (searchText == currentUser.mobile || searchText == currentUser.uid) {
            alertMessage = "You can't add yourself!"
            showAlert = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        isFocused = false // Dismiss keyboard for loading
        
        friendsService.searchUser(query: searchText) { user, error in
            isLoading = false
            if let user = user {
                // 2. Check Self-Add
                if user.uid == authService.user?.uid {
                    alertMessage = "You can't add yourself!"
                    showAlert = true
                    return
                }
                
                // 3. Check Duplicate
                if friendsService.friends.contains(where: { $0.uid == user.uid }) {
                    alertMessage = "This person is already in your circle."
                    showAlert = true
                    return
                }
                
                self.searchedUser = user
                withAnimation {
                    showConfirmation = true
                }
            } else {
                errorMessage = error ?? "User not found"
                isLoading = false
                isFocused = true // Refocus on error
            }
        }
    }
    
    func addFriend() {
        guard let friend = searchedUser, let currentUser = authService.user else { return }
        isLoading = true
        errorMessage = nil
        
        friendsService.addFriend(currentUser: currentUser, friend: friend) { success, error in
            isLoading = false
            if success {
                withAnimation {
                    isPresented = false
                }
            } else {
                errorMessage = error ?? "Failed to add friend"
            }
        }
    }
}
