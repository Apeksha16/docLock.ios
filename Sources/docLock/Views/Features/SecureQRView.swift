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
                
                // Empty State
                VStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color.orange.opacity(0.1))
                            .frame(width: 100, height: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(Color.orange, lineWidth: 1)
                            )
                        
                        Image(systemName: "plus")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                    }
                    
                    VStack(spacing: 10) {
                        Text("No QR Codes")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                        
                        Text("Create a secure access point\nfor your documents.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Floating Action Button
                Button(action: {
                    withAnimation {
                        showNewQRSheet = true
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.orange)
                        .clipShape(Circle())
                        .shadow(color: Color.orange.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .padding(.bottom, 30)
            }
            
            // New QR Sheet Overlay
            if showNewQRSheet {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation {
                            showNewQRSheet = false
                        }
                    }
                
                NewQRSheet(isPresented: $showNewQRSheet)
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
            }
        }
        .navigationBarHidden(true)
        .swipeToDismiss()
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
        VStack(spacing: 20) {
            // Drag Handle
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 10)
            
            // Icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 60, height: 60)
                Image(systemName: "qrcode")
                    .font(.title2)
                    .foregroundColor(.orange)
            }
            
            Text("New Secure QR")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
            
            // Form Content
            VStack(alignment: .leading, spacing: 20) {
                // Label Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("LABEL")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                    
                    TextField("e.g. Travel, Health", text: $label)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange, lineWidth: 1)
                        )
                }
                
                // Select Documents
                VStack(alignment: .leading, spacing: 10) {
                    Text("SELECT DOCUMENTS")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                    
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach($documents) { $doc in
                                Toggle(isOn: $doc.isSelected) {
                                    HStack(spacing: 15) {
                                        // File Icon
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.pink)
                                                .frame(width: 40, height: 40)
                                            Text(doc.type.prefix(1).uppercased())
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                        }
                                        
                                        Text(doc.name)
                                            .fontWeight(.medium)
                                            .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                                    }
                                }
                                .toggleStyle(CheckboxToggleStyle())
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(doc.isSelected ? Color.orange : Color.gray.opacity(0.1), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Generate Button
            Button(action: {
                // Generate Action
                withAnimation {
                    isPresented = false
                }
            }) {
                Text("Generate Secure QR")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(30)
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .background(Color(red: 0.98, green: 0.98, blue: 0.98))
        .cornerRadius(30, corners: [.topLeft, .topRight])
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.top, 100) // Don't cover fully top
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
