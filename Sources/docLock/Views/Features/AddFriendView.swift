import SwiftUI

struct AddFriendView: View {
    @Binding var isPresented: Bool
    @ObservedObject var authService: AuthService
    @ObservedObject var friendsService: FriendsService
    
    @State private var searchText: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var isTextFieldFocused: Bool
    @State private var sheetOffset: CGFloat = 800
    @State private var confirmationOffset: CGFloat = 800
    
    // Confirmation State
    @State private var searchedUser: User?
    @State private var showConfirmation = false
    
    var body: some View {
        ZStack {
            // LAYER 1: SEARCH VIEW (Always behind, or conditionally visible)
            // We keep it always visible behind, or switch. Switching is cleaner for accessibility, 
            // but for "popup" feel, ZStack is fine. Let's use if-else for main content vs overlay to keep it simple?
            // User asked for "popup should come... no back button". 
            // So: Search View is the BASE. Confirmation is the OVERLAY.
            
            VStack(spacing: 0) {
                // Decorative Background Pops
                 GeometryReader { geometry in
                     Circle()
                         .fill(Color(hex: "BF092F").opacity(0.15))
                         .frame(width: 150, height: 150)
                         .position(x: 50, y: 100)
                         .blur(radius: 20)
                     
                     Circle()
                         .fill(Color(hex: "BF092F").opacity(0.1))
                         .frame(width: 200, height: 200)
                         .position(x: geometry.size.width - 20, y: 50)
                         .blur(radius: 30)
                         
                     Circle()
                         .fill(Color(hex: "BF092F").opacity(0.05))
                         .frame(width: 100, height: 100)
                         .position(x: geometry.size.width / 2, y: geometry.size.height - 100)
                         .blur(radius: 15)
                 }
                 .frame(height: 0) // Don't affect layout
                 .zIndex(0)
                 
                // Drag Handle
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 4)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                
                // Header
                HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }) {
                    ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .frame(width: 56, height: 56)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                                )
                            
                            Image(systemName: "arrow.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.black)
                        }
                    }
                    
                    Spacer()
                    Text("Add Friend")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                    Spacer()
                     // Balance spacer with hidden button size
                     Color.clear.frame(width: 56, height: 56)
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
                
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color(hex: "BF092F"))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
                .padding(.bottom, 20)
                
                // Title
                Text("Connect with People")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                    .padding(.bottom, 10)
                
                Text("Paste a User ID below to add them\nto your secure circle.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 30)
                
                // Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Profile Link or ID")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                    
                    TextField("Paste Unique ID to connect...", text: $searchText)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .focused($isTextFieldFocused)
                        .onChange(of: searchText) { newValue in
                            // Filter only alphanumeric characters
                            let filtered = newValue.filter { $0.isLetter || $0.isNumber }
                            if filtered != newValue {
                                searchText = filtered
                            }
                        }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
                .onAppear {
                    // Autofocus the text field when view appears
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isTextFieldFocused = true
                    }
                }
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.bottom, 10)
                }
                
                // Button
                Button(action: searchUser) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Find User")
                                .fontWeight(.bold)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "BF092F"))
                    .cornerRadius(15)
                }
                .padding(.horizontal, 30)
                .disabled(isLoading || searchText.count < 6)
                .padding(.bottom, 20)
            }
            .background(
                ZStack {
                    Color(red: 0.98, green: 0.98, blue: 0.96) // Base Color
                    
                    // Decorative Pops
                    GeometryReader { proxy in
                        Circle()
                            .fill(Color(hex: "BF092F").opacity(0.15))
                            .frame(width: 150, height: 150)
                            .position(x: 50, y: 100)
                            .blur(radius: 20)
                        
                        Circle()
                            .fill(Color(hex: "BF092F").opacity(0.1))
                            .frame(width: 200, height: 200)
                            .position(x: proxy.size.width - 20, y: 50)
                            .blur(radius: 30)
                            
                        Circle()
                             .fill(Color(hex: "BF092F").opacity(0.05))
                             .frame(width: 120, height: 120)
                             .position(x: proxy.size.width * 0.8, y: proxy.size.height * 0.6)
                             .blur(radius: 40)
                    }
                }
                .cornerRadius(30, corners: [.topLeft, .topRight])
                .edgesIgnoringSafeArea(.bottom)
            )
            .offset(y: sheetOffset)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    sheetOffset = 0
                }
                // Autofocus the text field when view appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isTextFieldFocused = true
                }
            }
            
            // LAYER 2: CONFIRMATION OVERLAY
            if showConfirmation, let user = searchedUser {
                // Dimmed background
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showConfirmation = false
                        }
                    }
                    .zIndex(10)
                
                // Modal Card
                VStack(spacing: 20) {
                    // Drag Handle
                    Capsule()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 4)
                        .padding(.top, 10)
                    
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
                        
                        VStack(spacing: 5) {
                            Text(user.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                            
                            Text("Secure Connection Found")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.top, 10)
                    
                    Text("Are you sure you want to add this person to your secure circle?")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 30)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Buttons
                    VStack(spacing: 15) {
                        Button(action: addFriend) {
                             if isLoading {
                                 ProgressView()
                                     .progressViewStyle(CircularProgressViewStyle(tint: .white))
                             } else {
                                 Text("Yes, Add Friend")
                                     .fontWeight(.bold)
                                     .frame(maxWidth: .infinity)
                             }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "BF092F"))
                        .cornerRadius(15)
                        .padding(.horizontal, 30)
                        .disabled(isLoading)
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showConfirmation = false
                            }
                        }) {
                            Text("Cancel")
                                .fontWeight(.semibold)
                                .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                        }
                        .padding(.bottom, 50)
                    }
                }
                .background(
                    Color.white
                        .edgesIgnoringSafeArea(.bottom)
                )
                .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight]))
                .offset(y: confirmationOffset)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .edgesIgnoringSafeArea(.bottom)
                .transition(.move(edge: .bottom))
                .zIndex(11)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        confirmationOffset = 0
                    }
                }
            }
            // LAYER 3: ALERT MODAL
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
                         withAnimation {
                             showAlert = false
                             isPresented = false
                         }
                     },
                     onCancel: {
                         withAnimation {
                             showAlert = false
                             isPresented = false
                         }
                     }
                 )
                 .zIndex(20)
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
