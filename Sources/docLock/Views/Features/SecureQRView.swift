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
                    
                    // Add Button in Header when list is not empty
                    if !generatedQRs.isEmpty {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                selectedQR = nil // Clear selection for new creation
                                showNewQRSheet = true
                            }
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.orange.opacity(0.1))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.orange)
                            }
                        }
                    } else {
                        Color.clear.frame(width: 44, height: 44)
                    }
                }
                .padding()
                
                if generatedQRs.isEmpty {
                    // Animated Empty State
                    Spacer()
                    VStack {
                        Spacer().frame(height: 50)
                        
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
                                .rotationEffect(.degrees(hasAppeared ? 0 : 10))
                            
                            // Main Icon
                            Image(systemName: "qrcode")
                                .font(.system(size: 90, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.orange,
                                            Color.yellow
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
                                            Color.orange.opacity(0.4),
                                            Color.yellow.opacity(0.2)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)
                                .offset(x: -90, y: -80)
                                .scaleEffect(hasAppeared ? 1 : 0.5)
                                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: hasAppeared)
                            
                            Circle()
                                .fill(Color.orange.opacity(0.2))
                                .frame(width: 30, height: 30)
                                .offset(x: .random(in: 60...100), y: .random(in: 60...80))
                                .scaleEffect(hasAppeared ? 1 : 0.5)
                                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5), value: hasAppeared)
                        }
                        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: hasAppeared)
                        
                        Spacer().frame(height: 40)
                        
                        // Content Text
                        VStack(spacing: 18) {
                            Text("No QR Codes")
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
                            
                            Text("Create a secure access point\nfor your documents.")
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
                        
                        // Action Button
                        Button(action: {
                            withAnimation {
                                selectedQR = nil // Clear selection for new creation
                                showNewQRSheet = true
                            }
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                Text("Generate Secure QR")
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .frame(width: 240, height: 56)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.orange,
                                        Color.yellow.opacity(0.8)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(y: hasAppeared ? 0 : 20)
                        
                        Text("Create a secure access point\nfor your documents.")
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
                    
                    // Action Button
                    Button(action: {
                        withAnimation {
                            showAddQRSheet = true
                        }
                        .padding(.bottom, 50)
                        .opacity(hasAppeared ? 1 : 0)
                        .offset(y: hasAppeared ? 0 : 30)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.4), value: hasAppeared)
                    }
                    .transition(.opacity)
                } else {
                    // List of QRs
                    List {
                        ForEach(generatedQRs) { qr in
                            SecureQRCard(
                                qrModel: qr,
                                onEdit: {
                                    // Trigger Edit
                                },
                                onDownload: {
                                    // Trigger Download
                                }
                            )
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    selectedQR = qr
                                    showDeleteSheet = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    selectedQR = qr
                                    showDownloadSheet = true
                                } label: {
                                    Label("Download", systemImage: "square.and.arrow.down")
                                }
                                .tint(.blue)
                                
                                Button {
                                    selectedQR = qr
                                    showNewQRSheet = true
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.orange)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                }
            }
            .onAppear {
                withAnimation {
                    hasAppeared = true
                }
            }
            
            // Add QR Sheet Overlay
            if showAddQRSheet {
                AddQRSheet(
                    isPresented: $showAddQRSheet,
                    documentsService: documentsService,
                    userId: userId
                )
                .zIndex(100)
            }
        }
        .navigationBarHidden(true)
        .swipeToDismiss()
    }
}

// Button Style Support

