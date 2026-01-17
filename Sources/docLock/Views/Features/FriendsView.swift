import SwiftUI

struct FriendsView: View {
    @ObservedObject var friendsService: FriendsService
    let userId: String
    @State private var showAddFriend = false

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.98, green: 0.98, blue: 0.96) // Warm off-white
                .edgesIgnoringSafeArea(.all)
            
            // Top Right Decorative Circle (Sun-like)
            GeometryReader { geometry in
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 300, height: 300)
                    .position(x: geometry.size.width + 50, y: 0)
                
                Circle()
                    .fill(Color.yellow.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .position(x: geometry.size.width, y: 50)
            }
            
            VStack(spacing: 30) {
                Spacer().frame(height: 50)
                
                // Header
                VStack(spacing: 5) {
                    Text("Trusted Circle")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                    
                    Text("\(friendsService.friendsCount) secure connections")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer().frame(height: 20)
                
                // Empty State Illustration
                ZStack {
                    RoundedRectangle(cornerRadius: 40)
                        .fill(Color(red: 1.0, green: 0.95, blue: 0.7)) // Light Yellow
                        .frame(width: 180, height: 180)
                        .shadow(color: Color.orange.opacity(0.1), radius: 10, x: 0, y: 5)
                    
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Color.orange)
                    
                    // Decorative small circle
                    Circle()
                        .fill(Color.yellow.opacity(0.3))
                        .frame(width: 40, height: 40)
                        .offset(x: -80, y: 80)
                }
                
                Spacer().frame(height: 30)
                
                // Content Text
                VStack(spacing: 15) {
                    Text("Build Your Circle")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                    
                    Text("Connect with trusted friends and family\nto securely share important documents\nand cards.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 40)
                }
                
                // CTA Button
                Button(action: {
                    showAddFriend = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Your First Friend")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                }
                .padding(.horizontal, 40)
                .shadow(color: Color.orange.opacity(0.3), radius: 10, x: 0, y: 5)
                .fullScreenCover(isPresented: $showAddFriend) {
                    AddFriendView()
                }
                
                Spacer().frame(height: 100) // Space for TabBar
            }
        }
        .onAppear {
            friendsService.retry(userId: userId)
        }
    }
}
