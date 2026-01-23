import SwiftUI

struct FriendsView: View {
    @ObservedObject var authService: AuthService
    @ObservedObject var friendsService: FriendsService
    @ObservedObject var notificationService: NotificationService
    let userId: String
    @Binding var showAddFriend: Bool
    @Binding var showDeleteConfirmation: Bool
    @Binding var friendToDelete: User?
    @Binding var showRequestSheet: Bool
    @Binding var selectedFriendForRequest: User?
    @State private var hasAppeared = false
    @State private var headerOffset: CGFloat = -50
    @State private var statsOpacity: Double = 0
    @State private var addButtonScale: CGFloat = 0.8
    @State private var showToast = false
    @State private var toastMessage = ""

    var body: some View {
        ZStack {
            // Premium Animated Background Theme
            ZStack {
                // Base Background with gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.99, green: 0.99, blue: 0.99),
                        Color(red: 0.98, green: 0.98, blue: 0.99)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
                
                // Animated Ambient Gradients
                GeometryReader { proxy in
                    // Top Right - Animated Warm Glow
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "BF092F").opacity(hasAppeared ? 0.15 : 0.05),
                                    Color(hex: "BF092F").opacity(hasAppeared ? 0.08 : 0.03),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 10,
                                endRadius: hasAppeared ? 180 : 150
                            )
                        )
                        .frame(width: 450, height: 450)
                        .position(x: proxy.size.width * 0.9, y: hasAppeared ? -50 : -100)
                        .blur(radius: 50)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: hasAppeared)
                    
                    // Top Left - Animated Blue Haze
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(hasAppeared ? 0.06 : 0.02),
                                    Color.blue.opacity(0.03),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 20,
                                endRadius: 200
                            )
                        )
                        .frame(width: 350, height: 350)
                        .position(x: -50, y: hasAppeared ? 80 : 50)
                        .blur(radius: 60)
                        .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: hasAppeared)
                    
                    // Bottom - Subtle Animated Depth
                    Ellipse()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.gray.opacity(hasAppeared ? 0.04 : 0.01),
                                    Color.clear
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: proxy.size.width * 1.3, height: 400)
                        .position(x: proxy.size.width / 2, y: proxy.size.height * 1.1)
                        .blur(radius: 70)
                        .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: hasAppeared)
                }
            }
            

            VStack(spacing: 0) {
                // Premium Animated Header
                ZStack {
                    Text("Trusted Circle")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.1, green: 0.1, blue: 0.25),
                                    Color(red: 0.15, green: 0.15, blue: 0.3)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(maxWidth: .infinity, alignment: .center)
                        .offset(y: hasAppeared ? 0 : headerOffset)
                        .opacity(hasAppeared ? 1 : 0)
                    
                    HStack {
                        Spacer()
                        // Premium Animated Add Button
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                showAddFriend = true
                            }
                        }) {
                            ZStack {
                                // Main Button
                                RoundedRectangle(cornerRadius: 20)
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
                                    .frame(width: 60, height: 60)
                                    .shadow(color: Color(hex: "BF092F").opacity(0.3), radius: 10, x: 0, y: 5)
                                
                                Image(systemName: "plus")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .scaleEffect(addButtonScale)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                // Premium Animated Stats Section
                HStack(spacing: 12) {
                    StatCard(
                        icon: "doc.fill",
                        title: "Shared Doc",
                        count: authService.user?.sharedDocsCount ?? 0,
                        color: .blue,
                        index: 0,
                        hasAppeared: hasAppeared
                    )
                    StatCard(
                        icon: "creditcard.fill",
                        title: "Shared Card",
                        count: authService.user?.sharedCardsCount ?? 0,
                        color: .pink,
                        index: 1,
                        hasAppeared: hasAppeared
                    )
                    StatCard(
                        icon: "tray.fill",
                        title: "Requests",
                        count: notificationService.notifications.filter({ $0.title == "Request Sent" }).count,
                        color: Color(red: 0.28, green: 0.65, blue: 0.66),
                        index: 2,
                        hasAppeared: hasAppeared
                    )
                }
                .padding(.horizontal)
                .padding(.bottom, 15)
                .opacity(statsOpacity)
                
                Text("\(friendsService.friendsCount) secure connections")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.gray.opacity(0.8),
                            Color.gray.opacity(0.6)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .padding(.bottom, 20)
                .opacity(hasAppeared ? 1 : 0)
                
                if friendsService.friends.isEmpty {
                    // Premium Animated Empty State
                    Spacer().frame(height: 30)
                    ZStack {
                        // Animated Background Glow
                        RoundedRectangle(cornerRadius: 50)
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: "BF092F").opacity(hasAppeared ? 0.2 : 0.1),
                                        Color(hex: "BF092F").opacity(hasAppeared ? 0.1 : 0.05)
                                    ]),
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 100
                                )
                            )
                            .frame(width: 200, height: 200)
                            .scaleEffect(hasAppeared ? 1 : 0.8)
                            .rotationEffect(.degrees(hasAppeared ? 0 : -10))
                        
                        // Main Icon
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 90, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: "BF092F"),
                                        Color(hex: "BF092F").opacity(0.7)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(hasAppeared ? 1 : 0.6)
                        
                        // Animated Decorative Elements
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: "BF092F").opacity(0.35),
                                        Color(hex: "BF092F").opacity(0.15)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                            .offset(x: -90, y: 90)
                            .scaleEffect(hasAppeared ? 1 : 0.5)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: hasAppeared)
                        
                        Circle()
                            .fill(Color(hex: "BF092F").opacity(0.2))
                            .frame(width: 30, height: 30)
                            .offset(x: 100, y: -70)
                            .scaleEffect(hasAppeared ? 1 : 0.5)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5), value: hasAppeared)
                    }
                    .animation(.spring(response: 0.8, dampingFraction: 0.7), value: hasAppeared)
                    
                    Spacer().frame(height: 40)
                    
                    // Premium Animated Content Text
                    VStack(spacing: 18) {
                        Text("Build Your Circle")
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
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(y: hasAppeared ? 0 : 20)
                        
                        Text("Connect with trusted friends and family\nto securely share important documents\nand cards.")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .multilineTextAlignment(.center)
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
                            .padding(.horizontal, 40)
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(y: hasAppeared ? 0 : 20)
                    }
                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2), value: hasAppeared)
                    Spacer()
                } else {
                    // Tip
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("Tip: Click on a friend to request a card or document.")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Spacer()
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.bottom, 5)
                    
                    // Friends List with Swipe Actions
                    List {
                        ForEach(Array(friendsService.friends.enumerated()), id: \.element.id) { index, friend in
                            FriendListRow(
                                friend: friend,
                                index: index,
                                hasAppeared: hasAppeared
                            )
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedFriendForRequest = friend
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showRequestSheet = true
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button {
                                    friendToDelete = friend
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        showDeleteConfirmation = true
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash.fill")
                                        .foregroundColor(.black) 
                                }
                                .tint(.red)
                            }
                        }
                        
                        // Spacer to ensure last item is visible above bottom bar
                        Color.clear
                            .frame(height: 100)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .scrollIndicators(.hidden)
                }
            }
            .blur(radius: (showAddFriend || showDeleteConfirmation || showRequestSheet) ? 5 : 0)
            // Secure Request Sheet
            if showRequestSheet, let selectedFriend = selectedFriendForRequest, let currentUser = authService.user {
                RequestActionSheet(
                    friend: selectedFriend,
                    currentUser: currentUser,
                    friendsService: friendsService,
                    isPresented: $showRequestSheet,
                    onSuccess: {
                        toastMessage = "Request Sent Successfully"
                        withAnimation {
                            showToast = true
                        }
                    }
                )
            }
            
            // Toast Overlay
            if showToast {
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                        Text(toastMessage)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(
                        Capsule()
                            .fill(Color(hex: "00C853"))
                            .shadow(color: Color.black.opacity(0.15), radius: 10, y: 5)
                    )
                    .padding(.bottom, 100)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            showToast = false
                        }
                    }
                }
            }
        }
        .onAppear {
            friendsService.retry(userId: userId)
            
            // Trigger entrance animations
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                hasAppeared = true
                headerOffset = 0
                addButtonScale = 1.0
            }
            
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.2)) {
                statsOpacity = 1.0
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// Premium Animated Stat Card
struct StatCard: View {
    let icon: String // Added icon
    let title: String
    let count: Int
    let color: Color
    let index: Int
    let hasAppeared: Bool
    
    @State private var animatedCount: Int = 0
    
    var body: some View {
        VStack(spacing: 8) {
            // Icon Circle
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }
            .padding(.bottom, 2)
            
            Text("\(animatedCount)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
            
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
        .scaleEffect(hasAppeared ? 1 : 0.7)
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 30)
        .animation(
            .spring(response: 0.6, dampingFraction: 0.7)
            .delay(Double(index) * 0.1),
            value: hasAppeared
        )
        .onChange(of: hasAppeared) { newValue in
            if newValue {
                animateCount()
            }
        }
        .onChange(of: count) { newValue in
            animateCount()
        }
    }
    
    private func animateCount() {
        let steps = min(abs(count - animatedCount), 20)
        guard steps > 0 else { return }
        
        let stepValue = count > animatedCount ? 1 : -1
        var currentStep = 0
        
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            animatedCount += stepValue
            currentStep += 1
            
            if currentStep >= steps || animatedCount == count {
                animatedCount = count
                timer.invalidate()
            }
        }
    }
}

// Friend List Row Component (Notification-style layout)
struct FriendListRow: View {
    let friend: User
    let index: Int
    let hasAppeared: Bool
    
    @State private var avatarScale: CGFloat = 0.8
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            // Avatar Icon (similar to notification icon style)
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "BF092F").opacity(0.15))
                    .frame(width: 50, height: 50)
                
                AsyncImage(url: URL(string: friend.profileImageUrl ?? "")) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(Color(hex: "BF092F"))
                    }
                }
            }
            .scaleEffect(avatarScale)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(index) * 0.08)) {
                    avatarScale = 1.0
                }
            }
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(friend.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                    
                    Spacer()
                    
                    if let addedDate = friend.addedAt {
                        Text(formatShortDate(addedDate))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                if let addedDate = friend.addedAt {
                    Text("Joined \(formatDate(addedDate))")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                } else {
                    Text("Friend")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
        .opacity(hasAppeared ? 1 : 0)
        .offset(x: hasAppeared ? 0 : -30)
        .animation(
            .spring(response: 0.6, dampingFraction: 0.75)
            .delay(Double(index) * 0.06),
            value: hasAppeared
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// Premium Button Styles
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct PremiumRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
