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
}

enum NotificationType {
    case security
    case alert
    
    var icon: String {
        switch self {
        case .security: return "lock"
        case .alert: return "bell"
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
    
    var body: some View {
        ZStack {
            // Background - Light Lavender
            Color(red: 0.96, green: 0.93, blue: 0.98) // Light Lavender #F5EEFA approx
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
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
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                    
                    Spacer()
                    
                    // Balance the layout
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding()
                .padding(.bottom, 10)
                
                // Notification List
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
                                    notificationService.delete(id: notification.id, userId: userId)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(.red)
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    notificationService.markAsRead(id: notification.id, userId: userId)
                                } label: {
                                    Image(systemName: "checkmark.circle.fill")
                                }
                                .tint(Color(red: 0.2, green: 0.8, blue: 0.7)) // Green color
                            }
                    }
                }
                .listStyle(.plain)
                .scrollIndicators(.hidden)
            }
            
            // Content Selection Sheet
            if showContentSelection, let notification = selectedNotification, let requestType = notification.requestType, let senderId = notification.senderId {
                ContentSelectionSheet(
                    cards: requestType == "card" ? cardsService.cards : [],
                    documents: requestType == "document" ? getAllDocuments() : [],
                    requestType: requestType,
                    onShare: { content in
                        handleShare(content: content, senderId: senderId, requestType: requestType)
                    },
                    isPresented: $showContentSelection
                )
                .onAppear {
                    // Fetch documents from root when showing document selection
                    if requestType == "document" {
                        documentsService.fetchDocumentsInFolder(userId: userId, folderId: nil)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .swipeToDismiss()
        .toast(message: $toastMessage, type: .success)
        .onAppear {
            notificationService.retry(userId: userId)
            // Fetch documents if needed
            documentsService.startListening(userId: userId, parentFolderId: nil)
        }
    }
    
    private func getAllDocuments() -> [DocumentFile] {
        // For now, return current folder documents
        // In a full implementation, you might want to fetch all documents across all folders
        return documentsService.currentFolderDocuments
    }
    
    private func handleShare(content: Any, senderId: String, requestType: String) {
        if requestType == "card", let card = content as? CardModel {
            cardsService.shareCard(userId: userId, card: card, friendId: senderId, notificationService: notificationService) { success, error in
                DispatchQueue.main.async {
                    if success {
                        toastMessage = "Card shared successfully"
                        // Mark notification as read
                        if let notification = selectedNotification {
                            notificationService.markAsRead(id: notification.id, userId: userId)
                        }
                    } else {
                        toastMessage = error ?? "Failed to share card"
                    }
                }
            }
        } else if requestType == "document", let document = content as? DocumentFile {
            documentsService.shareDocument(userId: userId, document: document, friendId: senderId, notificationService: notificationService) { success, error in
                DispatchQueue.main.async {
                    if success {
                        toastMessage = "Document shared successfully"
                        // Mark notification as read
                        if let notification = selectedNotification {
                            notificationService.markAsRead(id: notification.id, userId: userId)
                        }
                    } else {
                        toastMessage = error ?? "Failed to share document"
                    }
                }
            }
        }
    }
}

struct NotificationCell: View {
    let notification: NotificationItem
    let onShare: (() -> Void)?
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.9, green: 0.9, blue: 0.98)) // Very light blue/purple
                    .frame(width: 50, height: 50)
                
                Group {
                    if let requestType = notification.requestType, requestType == "card" {
                        Image(systemName: "creditcard.fill")
                    } else if let requestType = notification.requestType, requestType == "document" {
                        Image(systemName: "doc.text.fill")
                    } else if notification.title.localizedCaseInsensitiveContains("Card") {
                        Image(systemName: "creditcard.fill")
                    } else if notification.title.localizedCaseInsensitiveContains("Request") {
                        Image(systemName: "arrow.right.circle.fill")
                    } else if notification.title.localizedCaseInsensitiveContains("Document") {
                        Image(systemName: "doc.text.fill")
                    } else if notification.title.localizedCaseInsensitiveContains("Security") {
                        Image(systemName: "shield.fill")
                    } else {
                        Image(systemName: notification.type.icon)
                    }
                }
                .font(.system(size: 22))
                .foregroundColor(Color(red: 0.4, green: 0.3, blue: 1.0))
            }
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(notification.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                    
                    Spacer()
                    
                    Text(notification.date)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Text(notification.message)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Share button for request notifications
                if let requestType = notification.requestType, notification.senderId != nil, let onShare = onShare {
                    Button(action: onShare) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .font(.caption)
                            Text("Share")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.05), lineWidth: 1)
        )
        // Visual indicator for unread state if needed, though not explicitly in design
        .opacity(notification.isRead ? 0.6 : 1.0)
    }
}
