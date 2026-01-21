import SwiftUI

struct AddFriendView: View {
    @Binding var isPresented: Bool
    @ObservedObject var authService: AuthService
    @ObservedObject var friendsService: FriendsService
    
    @State private var searchText: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var isTextFieldFocused: Bool

    
    // Confirmation State
    @State private var searchedUser: User?
    @State private var showConfirmation = false
    
    var body: some View {
        ZStack {
            // Dimmed background (Full Screen)
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }
            
            // Popup Content
            VStack(spacing: 0) {
                if showConfirmation, let user = searchedUser {
                    // CONFIRMATION STATE
                    VStack(spacing: 20) {
                        // Avatar & Info
                        VStack(spacing: 15) {
                             AsyncImage(url: URL(string: user.profileImageUrl ?? "")) { phase in
                                 if let image = phase.image {
                                     image.resizable().aspectRatio(contentMode: .fill)
                                 } else {
                                     Image(systemName: "person.crop.circle.fill")
                                         .resizable()
                                         .foregroundColor(.gray.opacity(0.3))
                                 }
                             }
                             .frame(width: 80, height: 80)
                             .clipShape(Circle())
                             .overlay(Circle().stroke(Color.white, lineWidth: 3))
                             .shadow(radius: 5)
                            
                            VStack(spacing: 5) {
                                Text(user.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                                
                                Text("Secure Connection Found")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.top, 20)
                        
                        Text("Add this person to your secure circle?")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Buttons
                        VStack(spacing: 12) {
                            Button(action: addFriend) {
                                 if isLoading {
                                     ProgressView()
                                         .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                 } else {
                                     Text("Yes, Add Friend")
                                         .fontWeight(.bold)
                                 }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "BF092F"))
                            .cornerRadius(15)
                            .disabled(isLoading)
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    showConfirmation = false
                                    searchedUser = nil
                                }
                            }) {
                                Text("Cancel")
                                    .fontWeight(.medium)
                                    .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                                    .padding(.vertical, 5)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                    
                } else {
                    // SEARCH STATE
                    VStack(spacing: 0) {
                        // Header
                        HStack {
                            Spacer()
                            ZStack {
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color(hex: "BF092F").opacity(0.1))
                                    .frame(width: 60, height: 60)
                                
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 28))
                                    .foregroundColor(Color(hex: "BF092F"))
                            }
                            Spacer()
                        }
                        .padding(.top, 25)
                        .padding(.bottom, 15)
                        
                        // Title & Subtitle
                        VStack(spacing: 8) {
                            Text("Add Friend")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                            
                            Text("Paste a User ID to connect securely")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.bottom, 25)
                        
                        // Input
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Paste Unique ID...", text: $searchText)
                                .font(.headline)
                                .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                                .padding()
                                .background(Color(red: 0.96, green: 0.96, blue: 0.98))
                                .cornerRadius(15)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(isTextFieldFocused ? Color(hex: "BF092F") : Color.gray.opacity(0.2), lineWidth: isTextFieldFocused ? 2 : 1)
                                )
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .focused($isTextFieldFocused)
                                .onChange(of: searchText) { newValue in
                                    let filtered = newValue.filter { $0.isLetter || $0.isNumber }
                                    if filtered != newValue {
                                        searchText = filtered
                                    }
                                }
                            
                            if let error = errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.leading, 5)
                            }
                        }
                        .padding(.horizontal, 25)
                        .padding(.bottom, 20)
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            Button(action: searchUser) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .padding(.trailing, 5)
                                    }
                                    Text("Find User")
                                        .fontWeight(.bold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "BF092F"))
                                .cornerRadius(15)
                            }
                            .disabled(isLoading || searchText.count < 6)
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    isPresented = false
                                }
                            }) {
                                Text("Close")
                                    .fontWeight(.medium)
                                    .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                                    .padding(.vertical, 5)
                            }
                        }
                        .padding(.horizontal, 25)
                        .padding(.bottom, 25)
                    }
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                }
            }
            .background(Color.white)
            .cornerRadius(25)
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 40)
            .padding(.bottom, 12) // Fixed padding above keyboard
            .ignoresSafeArea(.keyboard, edges: .bottom) // Native keyboard handling
            .zIndex(1)
            
            // ALERT MODAL (Layer 3)
            if showAlert {
                 CustomActionModal(
                     icon: "exclamationmark.triangle.fill",
                     iconBgColor: Color(hex: "BF092F"),
                     title: "Notice",
                     subtitle: nil,
                     message: alertMessage,
                     primaryButtonText: "Okay",
                     primaryButtonColor: Color(hex: "BF092F"),
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
        .onAppear {
            // Autofocus with slight delay for animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isTextFieldFocused = true
            }
        }
    }
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // ... body ...
    
    func searchUser() {
        guard !searchText.isEmpty else { return }
        
        // 1. Check Self-Add (Local Check)
        if let currentUser = authService.user, 
           (searchText == currentUser.mobile || searchText == currentUser.uid) {
            alertMessage = "You can't add yourself! (But we know you're awesome)"
            showAlert = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        friendsService.searchUser(query: searchText) { user, error in
            isLoading = false
            if let user = user {
                // 2. Check Self-Add (Remote User Object Check)
                if user.uid == authService.user?.uid {
                    alertMessage = "You can't add yourself! (But we know you're awesome)"
                    showAlert = true
                    return
                }
                
                // 3. Check Duplicate (Already in List)
                if friendsService.friends.contains(where: { $0.uid == user.uid }) {
                    alertMessage = "Deja Vu! This person is already in your circle."
                    showAlert = true
                    // "Go back" implicitly means we don't show confirmation
                    return
                }
                
                self.searchedUser = user
                withAnimation {
                    showConfirmation = true
                }
            } else {
                errorMessage = error ?? "User not found"
            }
        }
    }
    
    // ... addFriend ...
    
    func addFriend() {
        guard let friend = searchedUser, let currentUser = authService.user else { return }
        isLoading = true
        
        friendsService.addFriend(currentUser: currentUser, friend: friend) { success, error in
            isLoading = false
            if success {
                withAnimation {
                    showConfirmation = false
                    isPresented = false
                }
            } else {
                errorMessage = error ?? "Failed to add friend"
                withAnimation { showConfirmation = false }
            }
        }
    }
}
