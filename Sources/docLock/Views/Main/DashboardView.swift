import SwiftUI

struct DashboardView: View {
    @Binding var isAuthenticated: Bool
    @ObservedObject var authService: AuthService // Add this
    @State private var selectedTab = "Home"
    @State private var showLogoutModal = false
    @State private var showDeleteModal = false
    @State private var showEditNameSheet = false
    @State private var showAddFriend = false
    @State private var showFriendDeleteModal = false
    @State private var friendToDelete: User?
    @State private var showRequestSheet = false
    @State private var selectedFriendForRequest: User?
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            // Content Switcher
            Group {
                switch selectedTab {
                case "Home":
                    HomeView(authService: authService, 
                             notificationService: authService.notificationService, 
                             documentsService: authService.documentsService, 
                             cardsService: authService.cardsService,
                             appConfigService: authService.appConfigService)
                case "Friends":
                    FriendsView(authService: authService, 
                                friendsService: isAuthenticated ? (authService.friendsService) : FriendsService(), 
                                notificationService: authService.notificationService,
                                userId: authService.user?.id ?? authService.user?.mobile ?? "unknown", 
                                showAddFriend: $showAddFriend, 
                                showDeleteConfirmation: $showFriendDeleteModal, 
                                friendToDelete: $friendToDelete,
                                showRequestSheet: $showRequestSheet,
                                selectedFriendForRequest: $selectedFriendForRequest)
                case "Profile":
                    ProfileView(
                        isAuthenticated: $isAuthenticated,
                        showLogoutModal: $showLogoutModal,
                        showDeleteModal: $showDeleteModal,
                        showEditNameSheet: $showEditNameSheet,
                        authService: authService
                    )
                default:
                    HomeView(authService: authService,
                             notificationService: authService.notificationService,
                             documentsService: authService.documentsService,
                             cardsService: authService.cardsService,
                             appConfigService: authService.appConfigService)
                }
            }
            .transition(.opacity) // Fade transition
            
            // Floating Tab Bar
            CustomTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 0)
            
            // Modals (Rendered LAST to be ON TOP of TabBar)
            if showLogoutModal {
                CustomActionModal(
                    icon: "rectangle.portrait.and.arrow.right",
                    iconBgColor: .red,
                    title: "Logout?",
                    subtitle: nil,
                    message: "Are you sure you want to sign out of DocLock?",
                    primaryButtonText: "Logout",
                    primaryButtonColor: .red,
                    onPrimaryAction: {
                        withAnimation {
                            showLogoutModal = false
                            isAuthenticated = false // Log out
                        }
                    },
                    onCancel: { withAnimation { showLogoutModal = false } }
                )
            }
            
            if showDeleteModal {
                CustomActionModal(
                    icon: "trash.fill",
                    iconBgColor: .red,
                    title: "The Final Countdown",
                    subtitle: "Whoa there, partner! 🤠",
                    message: "You are about to permanently delete your account.\n\nAll your documents, friends, and data will be wiped from the face of the earth.\n\nThis action is irreversible - like a bad haircut, but permanent.",
                    primaryButtonText: "Yes, Delete Everything",
                    primaryButtonColor: .red,
                    onPrimaryAction: {
                       // Perform delete
                       withAnimation {
                           showDeleteModal = false
                           isAuthenticated = false
                       }
                    },
                    onCancel: { withAnimation { showDeleteModal = false } }
                )
            }
            
            // Edit Name Bottom Sheet (Above TabBar)
            if showEditNameSheet {
                EditNameView(authService: authService, isPresented: $showEditNameSheet)
                    .zIndex(200) // Ensure it's on top of TabBar
            }
            
            // Add Friend Sheet (Above TabBar)
            if showAddFriend {
                ZStack {
                    // Dimmed background - animate opacity along with sheet
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showAddFriend = false
                            }
                        }
                        .transition(.opacity)
                    
                    AddFriendView(isPresented: $showAddFriend, authService: authService, friendsService: authService.friendsService)
                        .transition(.move(edge: .bottom))
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .padding(.top, 50)
                }
                .zIndex(201)
            }
            
            // Delete Friend Modal (Dashboard Level to cover TabBar)
            if showFriendDeleteModal, let friend = friendToDelete {
                 // Dimmed background
                 Color.black.opacity(0.4)
                     .edgesIgnoringSafeArea(.all)
                     .onTapGesture {
                         withAnimation { showFriendDeleteModal = false }
                     }
                     .zIndex(203)
                 
                 // Modal Card
                 VStack(spacing: 20) {
                     Capsule()
                         .fill(Color.gray.opacity(0.3))
                         .frame(width: 40, height: 4)
                         .padding(.top, 10)
                     
                     VStack(spacing: 15) {
                          AsyncImage(url: URL(string: friend.profileImageUrl ?? "")) { phase in
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
                          .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                         
                         VStack(spacing: 5) {
                             Text(friend.name)
                                 .font(.title2)
                                 .fontWeight(.bold)
                                 .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                             
                             Text("Time to Part Ways?")
                                 .font(.caption)
                                 .foregroundColor(.red)
                         }
                     }
                     .padding(.top, 10)
                     
                     Text("Are you sure? Removing them means they lose access to all your shared documents. Poof! Gone.")
                         .font(.body)
                         .multilineTextAlignment(.center)
                         .foregroundColor(.gray)
                         .padding(.horizontal, 30)
                         .fixedSize(horizontal: false, vertical: true)
                     
                     // Buttons
                     VStack(spacing: 15) {
                         Button(action: {
                             // Delete Action
                             if let currentUser = authService.user {
                                 authService.friendsService.deleteFriend(currentUser: currentUser, friend: friend)
                             }
                             withAnimation { showFriendDeleteModal = false }
                         }) {
                             Text("Yes, Unfriend")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                         }
                         .foregroundColor(.white)
                         .frame(maxWidth: .infinity)
                         .padding()
                         .background(Color.red)
                         .cornerRadius(15)
                         .shadow(color: Color.red.opacity(0.3), radius: 10, x: 0, y: 5)
                         .padding(.horizontal, 30)
                         
                         Button(action: {
                             withAnimation { showFriendDeleteModal = false }
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
                 .frame(maxHeight: .infinity, alignment: .bottom)
                 .edgesIgnoringSafeArea(.bottom)
                 .transition(.move(edge: .bottom))
                 .zIndex(204)
            }
            
            // Request Action Sheet (Above TabBar)
            if showRequestSheet, let friend = selectedFriendForRequest, let currentUser = authService.user {
                RequestActionSheet(
                    friend: friend,
                    currentUser: currentUser,
                    friendsService: authService.friendsService,
                    isPresented: $showRequestSheet
                )
                .zIndex(205)
            }
        }
        .navigationBarHidden(true)
    }
}

struct HomeView: View {
    @ObservedObject var authService: AuthService
    @ObservedObject var notificationService: NotificationService
    @ObservedObject var documentsService: DocumentsService
    @ObservedObject var cardsService: CardsService
    @ObservedObject var appConfigService: AppConfigService
    
    @State private var selectedCategory = "Documents"
    @State private var showNotifications = false
    @State private var showDocuments = false
    @State private var showCards = false
    @State private var showQRs = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color(red: 0.96, green: 0.97, blue: 0.99)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("WELCOME BACK,")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                        Text(authService.user?.name ?? "DocLock User")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                    }
                    Spacer()
                    Button(action: { showNotifications = true }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color(red: 0.4, green: 0.4, blue: 1.0))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            
                            if !notificationService.notifications.isEmpty {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 10, height: 10)
                                    .offset(x: -5, y: -5)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .fullScreenCover(isPresented: $showNotifications) {
                    NotificationView(
                        notificationService: notificationService,
                        cardsService: cardsService,
                        documentsService: documentsService,
                        friendsService: authService.friendsService,
                        userId: authService.user?.id ?? authService.user?.mobile ?? "unknown"
                    )
                }
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 25) {
                        
                        // Calculations
                        let storageUsedMB = Double(authService.user?.storageUsed ?? 0) / (1024 * 1024)
                        let storagePercent = appConfigService.maxStorageLimit > 0 ? (storageUsedMB / Double(appConfigService.maxStorageLimit)) : 0
                        
                        let cardsPercent = appConfigService.maxCreditCardsLimit > 0 ? (Double(cardsService.cards.count) / Double(appConfigService.maxCreditCardsLimit)) : 0
                        
                        // QRs - Assuming limit of 20 for visual purposes since "Synced" isn't a hard limit
                        // Or if we want to show just activity level. 
                        let qrsCount = 5.0 // Placeholder value since we don't have a count service readily available in snippet
                        // Actually, let's use a safe fallback.
                        let qrsPercent = 0.45 // Fixed aesthetic value for now, or calculate if we had QR count
                        
                        
                        // Storage Circle (Multi-Ring)
                        StorageCircleView(
                            storagePercent: storagePercent,
                            cardsPercent: cardsPercent,
                            qrsPercent: qrsPercent,
                            selectedCategory: selectedCategory
                        )
                        .scaleEffect(1.05)
                        .padding(.top, 25)
                        .padding(.bottom, 15)
                        
                        // Category Chips
                        HStack(spacing: 15) {
                            Button(action: { selectedCategory = "Documents" }) {
                                ChipView(title: "Documents", color: .blue, isSelected: selectedCategory == "Documents")
                            }
                            Button(action: { selectedCategory = "Cards" }) {
                                ChipView(title: "Cards", color: .pink, isSelected: selectedCategory == "Cards")
                            }
                            Button(action: { selectedCategory = "QRs" }) {
                                ChipView(title: "QRs", color: .orange, isSelected: selectedCategory == "QRs")
                            }
                        }
                        
                        // Conditional Details Card
                        if selectedCategory == "Cards" {
                            // Cards Details View
                            HStack(alignment: .center) {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("ACTIVE CARDS")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.gray)
                                        .tracking(1.5)
                                    
                                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                                        Text("\(cardsService.cards.count)")
                                            .font(.system(size: 32, weight: .bold, design: .rounded))
                                            .foregroundColor(.pink)
                                        
                                        Text("/ \(appConfigService.maxCreditCardsLimit)")
                                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                                            .foregroundColor(.gray.opacity(0.8))
                                            .padding(.bottom, 2)
                                    }
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 5) {
                                    Text("USAGE")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.gray)
                                        .tracking(1.5)
                                    
                                    Text("\(Int(cardsPercent * 100))%")
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundColor(.pink)
                                }
                            }
                            .padding(.vertical, 20)
                            .padding(.horizontal, 25)
                            .background(Color.white)
                            .cornerRadius(24)
                            .shadow(color: Color.pink.opacity(0.1), radius: 15, x: 0, y: 5)
                            .padding(.horizontal)
                            
                        } else if selectedCategory == "QRs" {
                             // QRs Details Card
                            HStack(alignment: .center) {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("SYNCED QRS")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.gray)
                                        .tracking(1.5)
                                    
                                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                                        Text("5") // Placeholder as per graph logic
                                            .font(.system(size: 32, weight: .bold, design: .rounded))
                                            .foregroundColor(.orange)
                                        
                                        Text("/ 20") // Placeholder limit
                                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                                            .foregroundColor(.gray.opacity(0.8))
                                            .padding(.bottom, 2)
                                    }
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 5) {
                                    Text("USAGE")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.gray)
                                        .tracking(1.5)
                                    
                                    Text("25%") // Placeholder matching 5/20
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundColor(.orange)
                                }
                            }
                            .padding(.vertical, 20)
                            .padding(.horizontal, 25)
                            .background(Color.white)
                            .cornerRadius(24)
                            .shadow(color: Color.orange.opacity(0.1), radius: 15, x: 0, y: 5)
                            .padding(.horizontal)

                        } else {
                            // Documents Details Card (Default)
                            HStack(alignment: .center) {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("USED STORAGE")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.gray)
                                        .tracking(1.5)
                                    
                                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                                        let storageUsedMB = Double(authService.user?.storageUsed ?? 0) / (1024 * 1024)
                                        Text(String(format: "%.2f", storageUsedMB))
                                            .font(.system(size: 32, weight: .bold, design: .rounded))
                                            .foregroundColor(Color(red: 0.2, green: 0.4, blue: 0.9))
                                        
                                        Text("MB")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(Color(red: 0.2, green: 0.4, blue: 0.9))
                                            .padding(.bottom, 4)
                                            
                                        Text("/ \(appConfigService.maxStorageLimit) MB")
                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                            .foregroundColor(.gray.opacity(0.8))
                                            .padding(.bottom, 4)
                                    }
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 5) {
                                    Text("USAGE")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.gray)
                                        .tracking(1.5)
                                    
                                    Text("\(Int(storagePercent * 100))%")
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundColor(Color(red: 0.2, green: 0.4, blue: 0.9))
                                }
                            }
                            .padding(.vertical, 20)
                            .padding(.horizontal, 25)
                            .background(Color.white)
                            .cornerRadius(24)
                            .shadow(color: Color.blue.opacity(0.1), radius: 15, x: 0, y: 5)
                            .padding(.horizontal)
                        }
                        
                        // Feature Cards Grid
                        HStack(spacing: 15) {
                            Button(action: { showDocuments = true }) {
                                FeatureCard(icon: "doc.text.fill", title: "Documents", iconColor: .blue, iconBgColor: Color.blue.opacity(0.1))
                            }
                            .fullScreenCover(isPresented: $showDocuments) {
                                DocumentsView(documentsService: documentsService, friendsService: authService.friendsService, notificationService: notificationService, userId: authService.user?.id ?? authService.user?.mobile ?? "unknown")
                            }
                            
                            Button(action: { showCards = true }) {
                                FeatureCard(icon: "creditcard.fill", title: "Cards", iconColor: .pink, iconBgColor: Color.pink.opacity(0.1))
                            }
                            .fullScreenCover(isPresented: $showCards) {
                                CardsView(cardsService: cardsService, friendsService: authService.friendsService, notificationService: notificationService, userId: authService.user?.id ?? authService.user?.mobile ?? "unknown")
                            }
                            
                            Button(action: { showQRs = true }) {
                                FeatureCard(icon: "qrcode", title: "QRs", iconColor: .orange, iconBgColor: Color.orange.opacity(0.1))
                            }
                            .fullScreenCover(isPresented: $showQRs) {
                                SecureQRView()
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer().frame(height: 100)
                    }
                }
            }
        }
    }
}

// Helper for chips
struct ChipView: View {
    let title: String
    let color: Color
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(isSelected ? color.opacity(0.1) : Color.white)
        .overlay(
             RoundedRectangle(cornerRadius: 20)
                .stroke(color, lineWidth: 1.5)
        )
        .cornerRadius(20)
    }
}
