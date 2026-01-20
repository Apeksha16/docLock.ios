import SwiftUI
import CoreImage.CIFilterBuiltins

struct SecureQRView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var documentsService: DocumentsService
    let userId: String
    @State private var hasAppeared = false
    @State private var showAddQRSheet = false
    
    var body: some View {
        ZStack {
            // Background
            Color(red: 0.98, green: 0.96, blue: 0.94) // Warm beige background
                .edgesIgnoringSafeArea(.all)
            
            VStack {
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
                    Text("Secure QR")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                    Spacer()
                    
                    // Fixed width spacer to keep title centered
                    Color.clear.frame(width: 56, height: 56)
                }
                .padding()
                
                // Animated Empty State (Full display)
                Spacer()
                VStack {
                    ZStack {
                        // Animated Background Glow
                        RoundedRectangle(cornerRadius: 50)
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.orange.opacity(hasAppeared ? 0.2 : 0.1),
                                        Color.orange.opacity(hasAppeared ? 0.1 : 0.05)
                                    ]),
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 100
                                )
                            )
                            .frame(width: 200, height: 200)
                            .scaleEffect(hasAppeared ? 1 : 0.8)
                        
                        // Main Icon
                        Image(systemName: "qrcode")
                            .font(.system(size: 80, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.orange, Color.yellow]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(hasAppeared ? 1 : 0.6)
                        
                        // Floating circles
                        Circle()
                            .fill(Color.orange.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .offset(x: -80, y: -70)
                            .scaleEffect(hasAppeared ? 1 : 0.5)
                        
                        Circle()
                            .fill(Color.yellow.opacity(0.2))
                            .frame(width: 30, height: 30)
                            .offset(x: 80, y: 60)
                            .scaleEffect(hasAppeared ? 1 : 0.5)
                    }
                    .animation(.spring(response: 0.8, dampingFraction: 0.7), value: hasAppeared)
                    
                    Spacer().frame(height: 40)
                    
                    VStack(spacing: 12) {
                        Text("No QR Codes Yet")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                        
                        Text("Create a secure access point\nfor your documents.")
                            .font(.system(size: 16, weight: .medium))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 40)
                    }
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 20)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2), value: hasAppeared)
                    
                    Spacer().frame(height: 60)
                    
                    // Generate Button
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showAddQRSheet = true
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                            Text("Generate Secure QR")
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(width: 260, height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.orange, Color.orange.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                        .shadow(color: Color.orange.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .scaleEffect(hasAppeared ? 1 : 0.9)
                    .opacity(hasAppeared ? 1 : 0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.4), value: hasAppeared)
                }
                Spacer()
            }
            .onAppear {
                hasAppeared = true
            }
            .blur(radius: showAddQRSheet ? 3 : 0)
            
            // Add QR Sheet Overlay
            if showAddQRSheet {
                Color.black.opacity(0.2)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation { showAddQRSheet = false }
                    }
                
                AddQRSheet(
                    isPresented: $showAddQRSheet,
                    documentsService: documentsService,
                    userId: userId
                )
                .transition(.move(edge: .bottom))
                .zIndex(100)
            }
        }
        .navigationBarHidden(true)
        .swipeToDismiss()
    }
}

// Button Style Support

