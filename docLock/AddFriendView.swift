import SwiftUI

struct AddFriendView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var userId: String = ""
    
    var body: some View {
        ZStack {
            // Background
            Color(red: 0.98, green: 0.98, blue: 0.96) // Warm off-white
                .edgesIgnoringSafeArea(.all)
            
            // Decorative Circles
            GeometryReader { geometry in
                Circle()
                    .fill(Color.yellow.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .position(x: 100, y: 150)
                
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .position(x: geometry.size.width - 50, y: 100)
                
                 Circle()
                    .fill(Color.yellow.opacity(0.15))
                    .frame(width: 80, height: 80)
                    .position(x: 80, y: 300)
            }
            
            VStack(spacing: 0) {
                // Header (Manual implementation because fullScreenCover typically lacks Nav Bar unless wrapped)
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
                    Text("Add Friend")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                    Spacer()
                    Color.clear.frame(width: 44, height: 44) // Balance spacer
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Icon Section
                        ZStack {
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Color.orange)
                                .frame(width: 100, height: 100)
                                .shadow(color: Color.orange.opacity(0.3), radius: 10, x: 0, y: 5)
                            
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 40)
                        
                        // Text Content
                        VStack(spacing: 15) {
                            Text("Connect with People")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                            
                            Text("Paste a User ID or profile link below to add\nthem to your secure circle.")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 30)
                        }
                        
                        // Input Section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Profile Link or ID")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                            
                            TextField("e.g. gV5l3sJf...", text: $userId)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 30)
                        .padding(.top, 10)
                        
                        // Action Button
                        Button(action: {
                            // Perform add friend logic
                        }) {
                            Text("Add Friend")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .cornerRadius(15)
                                .shadow(color: Color.orange.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .padding(.horizontal, 30)
                        .padding(.top, 10)
                        
                        Spacer()
                    }
                    .padding(.top, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .swipeToDismiss()
    }
}
