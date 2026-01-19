import SwiftUI

struct DocumentItem: Identifiable {
    let id = UUID()
    let name: String
    let type: String // e.g., "jpg", "pdf"
    var isSelected: Bool = false
}

struct SecureQRView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showNewQRSheet = false
    @State private var hasAppeared = false
    
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
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding()
                
                Spacer()
                
                // Animated Empty State
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
                        .cornerRadius(20)
                        .shadow(color: Color.orange.opacity(0.4), radius: 10, y: 5)
                    }
                    .padding(.bottom, 50)
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 30)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.4), value: hasAppeared)
                }
                .onAppear {
                    withAnimation {
                        hasAppeared = true
                    }
                }
            }
            
            // New QR Sheet Overlay
        }
        .navigationBarHidden(true)
        .swipeToDismiss()
        .sheet(isPresented: $showNewQRSheet) {
            NewQRSheet(isPresented: $showNewQRSheet)
                .presentationDetents([.fraction(0.85)]) // Optional: Custom height if iOS 16+
        }
    }
}

struct NewQRSheet: View {
    @Binding var isPresented: Bool
    @State private var label: String = ""
    @State private var documents: [DocumentItem] = [
        DocumentItem(name: "IMG_0111.jpg", type: "jpg"),
        DocumentItem(name: "IMG_0005.jpg", type: "jpg"),
        DocumentItem(name: "Contract_Final.pdf", type: "pdf")
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            // Drag Handle
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 12)
            
            // Premium Header
            Text("New Secure QR")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                .padding(.bottom, 10)
            
            // Scrollable Form Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Label Input
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Label")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.gray)
                        
                        TextField("e.g. Travel Docs, Medical Records", text: $label)
                            .padding()
                            .background(Color(red: 0.98, green: 0.98, blue: 0.99))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                            )
                    }
                    
                    // Select Documents
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Select Documents")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.gray)
                            Spacer()
                            Text("\(documents.filter { $0.isSelected }.count) selected")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        
                        VStack(spacing: 12) {
                            ForEach($documents) { $doc in
                                Toggle(isOn: $doc.isSelected) {
                                    HStack(spacing: 16) {
                                        // Premium File Icon
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 14)
                                                .fill(
                                                    doc.type == "pdf" ?
                                                    Color.red.opacity(0.1) :
                                                    Color.blue.opacity(0.1)
                                                )
                                                .frame(width: 48, height: 48)
                                            
                                            Image(systemName: doc.type == "pdf" ? "doc.fill" : "photo.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(
                                                    doc.type == "pdf" ? .red : .blue
                                                )
                                        }
                                        
                                        Text(doc.name)
                                            .font(.system(size: 16, weight: .medium, design: .rounded))
                                            .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                                        
                                        Spacer()
                                    }
                                }
                                .toggleStyle(CheckboxToggleStyle())
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(doc.isSelected ? Color.orange.opacity(0.05) : Color.white)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(
                                            doc.isSelected ? Color.orange.opacity(0.3) : Color.gray.opacity(0.1),
                                            lineWidth: 1
                                        )
                                )
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: doc.isSelected)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            
            // Generate Button
            Button(action: {
                withAnimation {
                    isPresented = false
                }
            }) {
                Text("Generate Secure QR")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.orange,
                                Color(red: 1.0, green: 0.6, blue: 0.2)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(24)
                    .shadow(color: Color.orange.opacity(0.4), radius: 10, x: 0, y: 5)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 34)
        }
        .background(Color.white)
        // Native sheet handles corner radius and safe area
    }
}

// Custom Checkbox Toggle Style
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundColor(configuration.isOn ? .orange : .gray.opacity(0.3))
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}
