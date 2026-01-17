import SwiftUI

struct ProfileView: View {
    @Binding var isAuthenticated: Bool
    @Binding var showLogoutModal: Bool
    @Binding var showDeleteModal: Bool
    @State private var showAboutSheet = false

    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.98, blue: 0.98)
                .edgesIgnoringSafeArea(.all)
            
            // ... (Background Decorations - keeping same)
            GeometryReader { geometry in
                Circle()
                    .fill(Color(red: 0.2, green: 0.8, blue: 0.7).opacity(0.1))
                    .frame(width: 300, height: 300)
                    .position(x: geometry.size.width, y: 0)
            }
            
            VStack(spacing: 0) {
                // Header
                ZStack {
                    Text("My Profile")
                        .font(.headline)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    HStack {
                        Spacer()
                        Image(systemName: "square.and.arrow.up")
                            .padding(10)
                            .background(Color(red: 0.2, green: 0.8, blue: 0.7))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 25) {
                        
                        // Profile Card (Keeping same)
                        ZStack(alignment: .top) {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.2, green: 0.8, blue: 0.7),
                                        Color(red: 0.1, green: 0.7, blue: 0.6)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(height: 180)
                                .padding(.top, 50)
                            
                            VStack(spacing: 10) {
                                ZStack(alignment: .bottomTrailing) {
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .foregroundColor(.white)
                                        .background(Color.gray.opacity(0.3))
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                    
                                    Image(systemName: "camera.fill")
                                        .padding(6)
                                        .background(Color.black.opacity(0.7))
                                        .foregroundColor(.white)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                }
                                
                                Text("Apeksha verma")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .overlay(
                                        Image(systemName: "pencil")
                                            .foregroundColor(.white)
                                            .offset(x: 100)
                                    )
                                
                                Text("+919999999999")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        .padding(.horizontal)
                        
                        // Settings Section
                        HStack {
                            Text("SETTINGS")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                        .padding(.horizontal, 25)
                        
                        VStack(spacing: 15) {
                            SettingRow(icon: "lock", iconColor: .blue, title: "Security", subtitle: "Change MPIN & Biometrics")
                            // Using a sheet for AboutView since we are in a ZStack based nav, or we can use fullScreenCover
                            Button(action: { showAboutSheet = true }) {
                                SettingRow(icon: "info.circle", iconColor: .orange, title: "About DocLock", subtitle: "Why we are safe & secure")
                            }
                            
                            Button(action: { withAnimation { showLogoutModal = true } }) {
                                SettingRow(icon: "rectangle.portrait.and.arrow.right", iconColor: .purple, title: "Logout", subtitle: "Sign out of this device")
                            }
                            
                            Button(action: { withAnimation { showDeleteModal = true } }) {
                                SettingRow(icon: "trash", iconColor: .red, title: "Delete Account", subtitle: "Permanently remove your account")
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer().frame(height: 100)
                    }
                }
            }
        }
        .sheet(isPresented: $showAboutSheet) {
            AboutView()
        }
    }
}

struct SettingRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 50, height: 50)
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.black)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}
