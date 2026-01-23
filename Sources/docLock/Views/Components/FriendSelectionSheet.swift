import SwiftUI

struct FriendSelectionSheet: View {
    let friends: [User]
    let onShare: (User) -> Void
    @Binding var isPresented: Bool
    var sharingTitle: String = "Card" // Default for backward compatibility
    
    @State private var searchText = ""
    @State private var selectedFriendId: String? = nil
    
    @State private var sheetOffset: CGFloat = 600
    @FocusState private var isFocused: Bool
    @State private var keyboardHeight: CGFloat = 0
    
    var filteredFriends: [User] {
        if searchText.isEmpty {
            return friends
        }
        return friends.filter { friend in
            let nameMatch = friend.name.localizedCaseInsensitiveContains(searchText)
            let mobileMatch = friend.mobile?.localizedCaseInsensitiveContains(searchText) ?? false
            return nameMatch || mobileMatch
        }
    }
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        sheetOffset = 600
                        isPresented = false
                    }
                }
            
            // Bottom Sheet - Sticked to bottom
            VStack {
                Spacer()
                VStack(spacing: 0) {
                 // Drag Handle
                 Capsule()
                     .fill(Color.gray.opacity(0.3))
                     .frame(width: 40, height: 4)
                     .padding(.top, 16)
                     .padding(.bottom, 20)
                
                // Header
                Text("Share \(sharingTitle) with")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                    .padding(.bottom, 20)
                
                if friends.count > 6 {
                    TextField("Search friends...", text: $searchText)
                        .focused($isFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            isFocused = false
                        }
                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                        .colorScheme(.light)
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                }
                
                if friends.isEmpty {
                    VStack(spacing: 15) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("No friends to share with yet.")
                            .foregroundColor(.gray)
                    }
                    .frame(height: 150)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredFriends) { friend in
                                Button(action: {
                                    if selectedFriendId == friend.id {
                                        selectedFriendId = nil
                                    } else {
                                        selectedFriendId = friend.id
                                    }
                                }) {
                                    HStack(spacing: 15) {
                                        // Avatar
                                        ZStack {
                                            Circle()
                                                .fill(Color.blue.opacity(0.1))
                                                .frame(width: 44, height: 44)
                                            Text(friend.name.prefix(1).uppercased())
                                                .font(.headline)
                                                .foregroundColor(.blue)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(friend.name)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                                            if let mobile = friend.mobile {
                                                Text(mobile)
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        if selectedFriendId == friend.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.blue)
                                                .font(.system(size: 22))
                                        } else {
                                            Circle()
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                                .frame(width: 22, height: 22)
                                        }
                                    }
                                    .padding()
                                    .background(selectedFriendId == friend.id ? Color.blue.opacity(0.05) : Color.white)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(selectedFriendId == friend.id ? Color.blue : Color.gray.opacity(0.1), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(maxHeight: 350)
                }
                
                Spacer().frame(height: 20)
                
                Button(action: {
                    if let friendId = selectedFriendId, let friend = friends.first(where: { $0.id == friendId }) {
                        onShare(friend)
                        withAnimation { isPresented = false }
                    }
                }) {
                    Text("Share \(sharingTitle)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedFriendId == nil ? Color.gray : Color.blue)
                        .cornerRadius(15)
                }
                .disabled(selectedFriendId == nil)
                .padding(.horizontal)
                .padding(.bottom, 40 + keyboardHeight) // Bottom safe area + keyboard
                }
                .animation(.easeOut(duration: 0.25), value: keyboardHeight)
                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                    if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                        self.keyboardHeight = keyboardFrame.height - (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                   self.keyboardHeight = 0
                }
                .background(
                    ZStack {
                        Color(red: 0.98, green: 0.98, blue: 0.96)
                        
                        // Decorative Pops
                        GeometryReader { proxy in
                            Circle()
                                .fill(Color.blue.opacity(0.05))
                                .frame(width: 150, height: 150)
                                .position(x: 50, y: 100)
                                .blur(radius: 20)
                            
                            Circle()
                                .fill(Color.purple.opacity(0.05))
                                .frame(width: 200, height: 200)
                                .position(x: proxy.size.width - 20, y: 50)
                                .blur(radius: 30)
                        }
                    }
                    .cornerRadius(30, corners: [.topLeft, .topRight])
                    .edgesIgnoringSafeArea(.bottom)
                )
                .offset(y: sheetOffset)
                .transition(.move(edge: .bottom))
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        sheetOffset = 0
                    }
                }
            }
        }
        .zIndex(100)
        .ignoresSafeArea(edges: .bottom)
    }
}
