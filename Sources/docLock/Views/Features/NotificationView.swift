import SwiftUI

struct NotificationItem: Identifiable {
    let id: String
    let type: NotificationType
    let title: String
    let message: String
    let date: String
    var isRead: Bool = false
    var requestType: String? = nil
    var senderId: String? = nil
    var isFulfilled: Bool = false
}

enum NotificationType {
    case security
    case alert
    
    var icon: String {
        switch self {
        case .security: return "shield.checkered"
        case .alert: return "bell.badge.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .security: return .blue
        case .alert: return Color(red: 0.4, green: 0.4, blue: 1.0)
        }
    }
}

struct NotificationView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var notificationService: NotificationService
    @ObservedObject var cardsService: CardsService
    @ObservedObject var documentsService: DocumentsService
    @ObservedObject var friendsService: FriendsService
    let userId: String
    
    @State private var showContentSelection = false
    @State private var selectedNotification: NotificationItem? = nil
    @State private var toastMessage: String? = nil
    @State private var showToast = false
    @State private var toastType: ToastType = .success
    
    var body: some View {
        ZStack {
            // Background
            Color(red: 0.96, green: 0.97, blue: 0.99)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                if notificationService.notifications.isEmpty {
                    emptyStateView
                } else {
                    notificationList
                }
            }
        }
        .navigationBarHidden(true)
        .swipeToDismiss()
        .toast(message: $toastMessage, type: toastType)
        .overlay(
            Group {
                if showContentSelection, let notification = selectedNotification {
                    if notification.requestType == "card" {
                        CardSelectionSheet(
                            cards: cardsService.cards,
                            onShare: { card in
                                if let senderId = notification.senderId {
                                    cardsService.shareCard(userId: userId, card: card, friendId: senderId, notificationService: notificationService) { success, error in
                                        DispatchQueue.main.async {
                                            if success {
                                                toastMessage = "Card shared successfully"
                                                toastType = .success
                                                notificationService.markAsFulfilled(id: notification.id, userId: userId)
                                            } else {
                                                toastMessage = error ?? "Failed to share card"
                                                toastType = .error
                                            }
                                            showContentSelection = false
                                        }
                                    }
                                }
                            },
                            isPresented: $showContentSelection
                        )
                    } else if notification.requestType == "document" {
                        DocumentSelectionSheet(
                            documents: documentsService.currentFolderDocuments,
                            onShare: { document in
                                if let senderId = notification.senderId {
                                    documentsService.shareDocument(userId: userId, document: document, friendId: senderId, notificationService: notificationService) { success, error in
                                        DispatchQueue.main.async {
                                            if success {
                                                toastMessage = "Document shared successfully"
                                                toastType = .success
                                                notificationService.markAsFulfilled(id: notification.id, userId: userId)
                                            } else {
                                                toastMessage = error ?? "Failed to share document"
                                                toastType = .error
                                            }
                                            showContentSelection = false
                                        }
                                    }
                                }
                            },
                            isPresented: $showContentSelection
                        )
                    }
                }
            }
        )
        .onAppear {
            notificationService.retry(userId: userId)
            documentsService.startListening(userId: userId, parentFolderId: nil)
            cardsService.retry(userId: userId)
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .frame(width: 56, height: 56)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(red: 0.3, green: 0.2, blue: 0.9).opacity(0.3), lineWidth: 1)
                        )
                    
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.black)
                }
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            
            Spacer()
            
            Text("Notifications")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
            
            Spacer()
            
            // Removed trash icon as requested
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 15)
    }
    
    private var notificationList: some View {
        List {
            ForEach(notificationService.notifications) { notification in
                NotificationCell(
                    notification: notification,
                    onShare: (notification.requestType != nil && notification.senderId != nil) ? {
                        selectedNotification = notification
                        showContentSelection = true
                    } : nil
                )
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        withAnimation {
                            notificationService.delete(id: notification.id, userId: userId)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash.fill")
                    }
                    .tint(.red)
                }
                .swipeActions(edge: .leading) {
                    if !notification.isRead {
                        Button {
                            notificationService.markAsRead(id: notification.id, userId: userId)
                        } label: {
                            Label("Read", systemImage: "checkmark.circle.fill")
                        }
                        .tint(.blue)
                    }
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            notificationService.retry(userId: userId)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 120, height: 120)
                    .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 10)
                
                Image(systemName: "bell.slash")
                    .font(.system(size: 50))
                    .foregroundColor(Color(red: 0.4, green: 0.4, blue: 1.0).opacity(0.3))
            }
            
            VStack(spacing: 8) {
                Text("No Notifications")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                
                Text("We'll notify you when something\nimportant happens.")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 40)
            
            Spacer()
            Spacer()
        }
    }
}

struct NotificationCell: View {
    let notification: NotificationItem
    let onShare: (() -> Void)?
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            iconView
            
            VStack(alignment: .leading, spacing: 6) {
                Text(notification.title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                    .lineLimit(1)
                
                Text(notification.message)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack {
                    Text(notification.date)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.gray.opacity(0.6))
                    
                    Spacer()
                }
                .padding(.top, 2)
                
                if notification.requestType != nil, notification.senderId != nil, !notification.isFulfilled, let onShare = onShare {
                    shareButton(onShare: onShare)
                }
            }
            
            // Unread Indicator
            if !notification.isRead {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(notification.isRead ? Color.clear : Color.blue.opacity(0.1), lineWidth: 1)
        )
        .opacity(notification.isRead ? 0.85 : 1.0)
    }
    
    private var iconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            iconColor.opacity(0.15),
                            iconColor.opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 52, height: 52)
            
            Image(systemName: iconName)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(iconColor)
        }
    }
    
    private func shareButton(onShare: @escaping () -> Void) -> some View {
        Button(action: onShare) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.right.square.fill")
                    .font(.system(size: 14))
                Text("Fulfill Request")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: Color.blue.opacity(0.2), radius: 5, x: 0, y: 3)
        }
        .padding(.top, 8)
    }
    
    private var iconName: String {
        if let requestType = notification.requestType {
            return requestType == "card" ? "creditcard.fill" : "doc.text.fill"
        }
        
        let title = notification.title.lowercased()
        if title.contains("card") { return "creditcard.fill" }
        if title.contains("request") { return "person.badge.shield.checkmark.fill" }
        if title.contains("document") { return "doc.text.fill" }
        if title.contains("security") { return "shield.fill" }
        
        return notification.type.icon
    }
    
    private var iconColor: Color {
        if notification.title.lowercased().contains("security") { return .blue }
        return notification.type.color
    }
}

