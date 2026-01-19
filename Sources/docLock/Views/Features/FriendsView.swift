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
                                    Color.orange.opacity(hasAppeared ? 0.15 : 0.05),
                                    Color.orange.opacity(hasAppeared ? 0.08 : 0.03),
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
                                                Color.white,
                                                Color(red: 0.99, green: 0.98, blue: 0.98)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color.orange.opacity(0.4),
                                                        Color.orange.opacity(0.2)
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 2
                                            )
                                    )
                                
                                Image(systemName: "plus")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.orange,
                                                Color.orange.opacity(0.8)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
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
                        count: 0,
                        color: .blue,
                        index: 0,
                        hasAppeared: hasAppeared
                    )
                    StatCard(
                        icon: "creditcard.fill",
                        title: "Shared Card",
                        count: 0,
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
                                        Color(red: 1.0, green: 0.95, blue: 0.75).opacity(hasAppeared ? 1 : 0.5),
                                        Color(red: 1.0, green: 0.96, blue: 0.8).opacity(hasAppeared ? 0.8 : 0.3)
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
                                        Color.orange,
                                        Color.orange.opacity(0.7)
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
                                        Color.yellow.opacity(0.4),
                                        Color.orange.opacity(0.2)
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
                            .fill(Color.orange.opacity(0.2))
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
                                Button(role: .destructive) {
                                    friendToDelete = friend
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        showDeleteConfirmation = true
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash.fill")
                                }
                                .tint(.red)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .scrollIndicators(.hidden)
                }
            }
            .blur(radius: (showAddFriend || showDeleteConfirmation || showRequestSheet) ? 5 : 0)
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
                    .fill(Color.orange.opacity(0.15))
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
                            .foregroundColor(Color.orange)
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

// MARK: - Components
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
                // Premium Drag Handle
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
                                                Color.orange,
                                                Color.orange.opacity(0.8)
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
                        .padding(.bottom, 30) // Extra safe area padding
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
                            // Auto-close after 2.5 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    isPresented = false
                                }
                            }
                        }
                    } else if isLoading {
                        // Loading State
                        VStack(spacing: 20) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .green))
                                .scaleEffect(1.5)
                                .padding(.top, 40)
                            
                            Text("Sending Request...")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.gray.opacity(0.8))
                        }
                        .frame(minHeight: 200)
                        .padding(.bottom, 40)
                    } else {
                        // Premium Input Area
                        VStack(alignment: .leading, spacing: 10) {
                            Text("PERSONAL NOTE (OPTIONAL)")
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
                                .onChange(of: message) { newValue in
                                    // Only allow text, numbers, spaces, hyphens, and underscores
                                    let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: " -_"))
                                    let filtered = newValue.unicodeScalars.filter { allowedCharacters.contains($0) }
                                    let filteredString = String(String.UnicodeScalarView(filtered))
                                    if filteredString != newValue {
                                        message = filteredString
                                    }
                                }
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
                                isDisabled: message.count > 0 && message.count < 3,
                                action: { sendRequest(type: "card") }
                            )
                            
                            // Request Doc Button
                            PremiumActionButton(
                                icon: "doc.text.fill",
                                title: "Ask for Doc",
                                color: .blue,
                                isLoading: isLoading,
                                isDisabled: message.count > 0 && message.count < 3,
                                action: { sendRequest(type: "document") }
                            )
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 30)
                    }
                }
                .padding(.top, sentSuccess ? 0 : 4)
                .padding(.bottom, sentSuccess ? 0 : 30)
            }
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
            .offset(y: sheetOffset)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .edgesIgnoringSafeArea(.bottom)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    sheetOffset = 0
                }
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                    iconScale = 1.0
                    iconRotation = 0
                }
                // Autofocus the text field
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTextFieldFocused = true
                }
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .transition(.move(edge: .bottom))
        }
        .zIndex(150)
    }
    
    func sendRequest(type: String) {
        // Disable if input exists and is less than 3 characters (but allow empty)
        guard message.isEmpty || message.count >= 3 else {
            return
        }
        
        isLoading = true
        let msg = message.isEmpty ? "Requested \(type == "card" ? "a card" : "a document")" : message
        
        friendsService.sendRequest(fromUser: currentUser, toFriend: friend, requestType: type, message: msg) { success in
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
