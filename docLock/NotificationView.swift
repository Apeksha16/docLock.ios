import SwiftUI

struct NotificationItem: Identifiable {
    let id = UUID()
    let type: NotificationType
    let title: String
    let message: String
    let date: String
    var isRead: Bool = false
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
    
    @State private var notifications: [NotificationItem] = [
        NotificationItem(type: .security, title: "Profile Update", message: "Your profile picture has been updated successfully.", date: "5d ago"),
        NotificationItem(type: .security, title: "Profile Update", message: "Your profile picture has been updated successfully.", date: "5d ago"),
        NotificationItem(type: .alert, title: "Item Shared", message: "You successfully shared 'Pranav Katiyar' with Apeksha Verma.", date: "1/8/2026"),
        NotificationItem(type: .alert, title: "Connection Severed", message: "You have removed Pranavkwdwdw from your secure circle.", date: "1/8/2026"),
        NotificationItem(type: .alert, title: "Friend Added", message: "You have successfully added Pranavkwdwdw to your secure circle.", date: "1/8/2026"),
        NotificationItem(type: .alert, title: "Request Sent", message: "You requested 'jhkhhkj' (card) from Apeksha Verma.", date: "1/8/2026")
    ]
    
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
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(10)
                            .background(Color.white)
                            .cornerRadius(12)
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
                    ForEach(notifications) { notification in
                        NotificationCell(notification: notification)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                                        withAnimation {
                                            notifications.remove(at: index)
                                        }
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(.red)
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                                        withAnimation {
                                            notifications[index].isRead.toggle()
                                        }
                                    }
                                } label: {
                                    Image(systemName: "checkmark") // Icon from screenshot
                                }
                                .tint(Color(red: 0.4, green: 0.3, blue: 1.0)) // Purple color
                            }
                    }
                }
                .listStyle(.plain)
                .scrollIndicators(.hidden)
            }
        }
        .navigationBarHidden(true)
        .swipeToDismiss()
    }
}

struct NotificationCell: View {
    let notification: NotificationItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.9, green: 0.9, blue: 0.98)) // Very light blue/purple
                    .frame(width: 50, height: 50)
                
                Image(systemName: notification.type.icon)
                    .font(.system(size: 22))
                    .foregroundColor(Color(red: 0.4, green: 0.3, blue: 1.0)) // Purple icon
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
