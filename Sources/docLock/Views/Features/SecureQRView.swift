import SwiftUI
import CoreImage.CIFilterBuiltins

struct DocumentItem: Identifiable, Codable {
    var id = UUID() // Changed to var for Codable conformance if needed later, kept simple
    let name: String
    let type: String // e.g., "jpg", "pdf"
    var isSelected: Bool = false
}

struct SecureQRModel: Identifiable {
    let id = UUID()
    var label: String
    var documents: [DocumentItem]
    var dateCreated: Date
}

struct SecureQRView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showNewQRSheet = false
    @State private var showDeleteSheet = false
    @State private var showDownloadSheet = false
    @State private var hasAppeared = false
    @State private var generatedQRs: [SecureQRModel] = []
    
    // Selected QR for actions
    @State private var selectedQR: SecureQRModel?
    
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
                            .cornerRadius(20)
                            .shadow(color: Color.orange.opacity(0.4), radius: 10, y: 5)
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
        }
        .navigationBarHidden(true)
        .swipeToDismiss()
        .sheet(isPresented: $showNewQRSheet) {
            NewQRSheet(isPresented: $showNewQRSheet, generatedQRs: $generatedQRs, qrToEdit: selectedQR)
                .presentationDetents([.fraction(0.85)])
        }
        .sheet(isPresented: $showDeleteSheet) {
            if let qr = selectedQR {
                DeleteConfirmationSheet(isPresented: $showDeleteSheet, qrModel: qr) {
                    if let index = generatedQRs.firstIndex(where: { $0.id == qr.id }) {
                        withAnimation {
                            generatedQRs.remove(at: index)
                        }
                    }
                }
                .presentationDetents([.fraction(0.35)])
            }
        }
        .sheet(isPresented: $showDownloadSheet) {
            if let qr = selectedQR {
                DownloadQRSheet(isPresented: $showDownloadSheet, qrModel: qr)
                    .presentationDetents([.fraction(0.6)])
            }
        }
    }
}

// MARK: - SecureQRCard
struct SecureQRCard: View {
    let qrModel: SecureQRModel
    var onEdit: () -> Void
    var onDownload: () -> Void
    
    // Generate QR Code Image helper
    func generateQRCode(from string: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)

        if let outputImage = filter.outputImage {
            // Scale up for sharpness
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // QR Code Image
            Image(uiImage: generateQRCode(from: qrModel.label)) // Using label as placeholder data
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: 80, height: 80)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(qrModel.label)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                
                Text("\(qrModel.documents.count) Documents Linked")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                
                Text("Created: \(qrModel.dateCreated.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.7))
            }
            
            Spacer()
            
            // Chevron to indicate interaction
            Image(systemName: "chevron.right")
                .foregroundColor(.gray.opacity(0.4))
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct NewQRSheet: View {
    @Binding var isPresented: Bool
    @Binding var generatedQRs: [SecureQRModel] // Binding to parent list
    var qrToEdit: SecureQRModel? // Optional QR to edit
    
    @State private var label: String = ""
    @State private var documents: [DocumentItem] = [
        DocumentItem(name: "IMG_0111.jpg", type: "jpg"),
        DocumentItem(name: "IMG_0005.jpg", type: "jpg"),
        DocumentItem(name: "Contract_Final.pdf", type: "pdf")
    ]
    
    // Initialize state if editing
    init(isPresented: Binding<Bool>, generatedQRs: Binding<[SecureQRModel]>, qrToEdit: SecureQRModel? = nil) {
        self._isPresented = isPresented
        self._generatedQRs = generatedQRs
        self.qrToEdit = qrToEdit
    }

    var isFormValid: Bool {
        return !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && documents.contains { $0.isSelected }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Drag Handle
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 12)
            
            // Premium Header
            Text(qrToEdit == nil ? "New Secure QR" : "Edit Secure QR")
                .font(.system(size: 24, weight: .bold))
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
            
            // Generate/Save Button
            Button(action: {
                generateQR()
            }) {
                Text(qrToEdit == nil ? "Generate Secure QR" : "Save Changes")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        isFormValid ?
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.orange,
                                Color(red: 1.0, green: 0.6, blue: 0.2)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [Color.gray.opacity(0.5)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(24)
                    .shadow(color: isFormValid ? Color.orange.opacity(0.4) : Color.clear, radius: 10, x: 0, y: 5)
            }
            .disabled(!isFormValid)
            .padding(.horizontal, 24)
            .padding(.bottom, 34)
        }
        .background(Color.white)
        .onAppear {
            if let qr = qrToEdit {
                label = qr.label
                // Mark selected documents from the QR model
                // Note: In a real app, you'd match by ID. Here matching by name for simplicity
                for doc in qr.documents {
                     if let index = documents.firstIndex(where: { $0.name == doc.name }) {
                         documents[index].isSelected = true
                     }
                }
            }
        }
    }
    
    private func generateQR() {
        let selectedDocs = documents.filter { $0.isSelected }
        
        if let editingQR = qrToEdit, let index = generatedQRs.firstIndex(where: { $0.id == editingQR.id }) {
            // Update existing
            generatedQRs[index].label = label
            generatedQRs[index].documents = selectedDocs
            // Keep original dateCreated
        } else {
            // Create new
            let newQR = SecureQRModel(label: label, documents: selectedDocs, dateCreated: Date())
            generatedQRs.append(newQR)
        }
        
        // Dismiss
        withAnimation {
            isPresented = false
        }
    }
}

struct DeleteConfirmationSheet: View {
    @Binding var isPresented: Bool
    let qrModel: SecureQRModel
    var onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
             Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 12)
            
            VStack(spacing: 16) {
                Image(systemName: "trash.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.red)
                
                Text("Delete Secure QR?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                
                Text("Are you sure you want to delete '\(qrModel.label)'? This action cannot be undone.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 12) {
                Button(action: {
                    onDelete()
                    isPresented = false
                }) {
                    Text("Delete")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(16)
                }
                
                Button(action: {
                    isPresented = false
                }) {
                    Text("Cancel")
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(16)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .background(Color.white)
        .presentationDetents([.height(350)]) // Fixed height to ensure enough space
    }
}

struct DownloadQRSheet: View {
    @Binding var isPresented: Bool
    let qrModel: SecureQRModel
    @State private var isSaved = false
    
    // Helper to generate image for saving
    func generateQRCode(from string: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)

        if let outputImage = filter.outputImage {
            // Scale up high quality
            let transform = CGAffineTransform(scaleX: 20, y: 20)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        return UIImage()
    }
    
    var body: some View {
        VStack(spacing: 30) {
             Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 12)
            
            Text("Download QR")
                .font(.system(size: 24, weight: .bold)) // Slightly bigger title
                .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
            
            // Big QR Code Display with better padding and shadow
            ZStack {
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 8)
                
                VStack(spacing: 20) {
                    Image(uiImage: generateQRCode(from: qrModel.label)) // Using label as content for now per existing code
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 220, height: 220) // Bigger QR
                    
                    Text(qrModel.label)
                        .font(.system(size: 20, weight: .semibold, design: .rounded)) // Bigger label
                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                }
                .padding(40)
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            Button(action: {
                // Simulate save
                let image = generateQRCode(from: qrModel.label)
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                withAnimation {
                    isSaved = true
                }
                
                // Auto dismiss after nice feedback
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    isPresented = false
                }
            }) {
                HStack {
                    if isSaved {
                        Image(systemName: "checkmark")
                        Text("Saved to Photos")
                    } else {
                        Image(systemName: "square.and.arrow.down")
                        Text("Save to Gallery")
                    }
                }
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(isSaved ? Color.green : Color.blue)
                .cornerRadius(20)
                .shadow(color: (isSaved ? Color.green : Color.blue).opacity(0.3), radius: 10, y: 5)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 20)
            .disabled(isSaved)
        }
        .background(Color.white)
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

// Button Style Support

