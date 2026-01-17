import SwiftUI

struct DashboardView: View {
    @Binding var isAuthenticated: Bool
    @State private var selectedTab = "Home"
    @State private var showLogoutModal = false
    @State private var showDeleteModal = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            // Content Switcher
            Group {
                switch selectedTab {
                case "Home":
                    HomeView()
                case "Friends":
                    FriendsView()
                case "Profile":
                    ProfileView(
                        isAuthenticated: $isAuthenticated,
                        showLogoutModal: $showLogoutModal,
                        showDeleteModal: $showDeleteModal
                    )
                default:
                    HomeView()
                }
            }
            .transition(.opacity) // Fade transition
            
            // Floating Tab Bar
            CustomTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 10)
            
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
        }
        .navigationBarHidden(true)
    }
}

struct HomeView: View {
    @State private var selectedCategory = "Storage"
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
                        Text("Pranav")
                            .font(.largeTitle)
                            .fontWeight(.heavy)
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
                            
                            Circle()
                                .fill(Color.red)
                                .frame(width: 10, height: 10)
                                .offset(x: -5, y: -5)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .fullScreenCover(isPresented: $showNotifications) {
                    NotificationView()
                }
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 25) {
                        
                        // Storage Circle
                        StorageCircleView(label: selectedCategory, color: selectedCategory == "Cards" ? .pink : .blue)
                            .animation(.easeInOut, value: selectedCategory)
                            .padding(.top, 20)
                        
                        // Category Chips
                        HStack(spacing: 15) {
                            Button(action: { selectedCategory = "Storage" }) {
                                ChipView(title: "Storage", color: .blue, isSelected: selectedCategory == "Storage")
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
                            VStack(spacing: 15) {
                                HStack {
                                    Text("CARDS DETAILS")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("USED")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.gray)
                                }
                                
                                HStack(alignment: .bottom) {
                                    Text("0")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.pink)
                                    Text(" / 10")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.black)
                                    
                                    Spacer()
                                    
                                    Text("0%")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.pink)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(20)
                            .padding(.horizontal)
                        } else {
                            // Storage Details Card (Default)
                            VStack(spacing: 15) {
                                HStack {
                                    Text("STORAGE DETAILS")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("USED")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.gray)
                                }
                                
                                HStack(alignment: .bottom) {
                                    Text("0.00")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.9))
                                    Text("MB")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    Text(" / 200 MB")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.black)
                                    
                                    Spacer()
                                    
                                    Text("0%")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.9))
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(20)
                            .padding(.horizontal)
                        }
                        
                        // Feature Cards Grid
                        HStack(spacing: 15) {
                            Button(action: { showDocuments = true }) {
                                FeatureCard(icon: "doc.text.fill", title: "Documents", subtitle: "0 Files", iconColor: .blue, iconBgColor: Color.blue.opacity(0.1))
                            }
                            .fullScreenCover(isPresented: $showDocuments) {
                                DocumentsView()
                            }
                            
                            Button(action: { showCards = true }) {
                                FeatureCard(icon: "creditcard.fill", title: "Cards", subtitle: "0 Active", iconColor: .pink, iconBgColor: Color.pink.opacity(0.1))
                            }
                            .fullScreenCover(isPresented: $showCards) {
                                CardsView()
                            }
                            
                            Button(action: { showQRs = true }) {
                                FeatureCard(icon: "qrcode", title: "QRs", subtitle: "Synced", iconColor: .orange, iconBgColor: Color.orange.opacity(0.1))
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
                .foregroundColor(isSelected ? color : .orange) // Wait, design has colored text
                .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.4))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(isSelected ? color.opacity(0.15) : Color.white)
        .overlay(
             RoundedRectangle(cornerRadius: 20)
                .stroke(isSelected ? color : Color.orange.opacity(0.2), lineWidth: 1.5) // Adjust borders
        )
        .cornerRadius(20)
        // Manual override for exact colors based on image
        .foregroundColor(Color.black)
    }
}
