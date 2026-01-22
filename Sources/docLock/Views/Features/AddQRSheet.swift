import SwiftUI

struct AddQRSheet: View {
    @Binding var isPresented: Bool
    @ObservedObject var documentsService: DocumentsService
    @ObservedObject var secureQRService: SecureQRService
    let userId: String
    var qrToEdit: SecureQR? = nil // Optional QR for edit mode
    
    @State private var qrLabel: String = ""
    @State private var selectedDocuments: Set<String> = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var isTextFieldFocused: Bool
    // Start offscreen
    @State private var sheetOffset: CGFloat = 800
    @State private var iconScale: CGFloat = 0.5
    @State private var iconRotation: Double = -180
    @State private var keyboardHeight: CGFloat = 0
    
    // Theme Color
    let themeColor = Color.orange
    
    private var isEditMode: Bool {
        qrToEdit != nil
    }
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }
            
            // Modal Content
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 0) {
                    // Drag Handle
                    Capsule()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 5)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                    
                    VStack(spacing: 0) {
                        // Scrollable Content
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 24) {
                                header
                                inputSection
                                documentSelectionList
                                
                                // Error Message
                                if let error = errorMessage {
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .padding(.horizontal, 30)
                                }
                                
                                // Bottom padding for scroll view to ensure content doesn't get hidden behind sticky button if content is long
                                Spacer().frame(height: 20)
                            }
                            .padding(.top, 10)
                        }
                        
                        // Sticky Action Button
                        VStack(spacing: 0) {
                            actionButton
                                .padding(.top, 16)
                                .padding(.bottom, 20)
                        }
                        .background(Color.white) // Ensure opaque background behind sticky button
                    }
                }
                .padding(.bottom, keyboardHeight) // Push content up
                .background(
                    ZStack {
                        LinearGradient(gradient: Gradient(colors: [.white, Color(red: 0.99, green: 0.99, blue: 0.99)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                        
                        // Theme Blush Effects
                        GeometryReader { proxy in
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            themeColor.opacity(0.15),
                                            Color.clear
                                        ]),
                                        center: .center,
                                        startRadius: 20,
                                        endRadius: 200
                                    )
                                )
                                .frame(width: 400, height: 400)
                                .position(x: 0, y: 50)
                                .blur(radius: 60)
                            
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            themeColor.opacity(0.12),
                                            Color.clear
                                        ]),
                                        center: .center,
                                        startRadius: 20,
                                        endRadius: 180
                                    )
                                )
                                .frame(width: 350, height: 350)
                                .position(x: proxy.size.width, y: 80)
                                .blur(radius: 50)
                        }
                    }
                )
                .clipShape(RoundedCorner(radius: 20, corners: [.topLeft, .topRight]))
                .clipShape(RoundedCorner(radius: 20, corners: [.topLeft, .topRight]))
                .offset(y: sheetOffset)
                // Limit height to allow tapping background
                .frame(maxHeight: UIScreen.main.bounds.height * 0.85)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { output in
            if let keyboardFrame = output.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeOut(duration: 0.25)) {
                    self.keyboardHeight = keyboardFrame.height
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                self.keyboardHeight = 0
            }
        }
        .onAppear {
            // Pre-fill data if editing
            if let qr = qrToEdit {
                qrLabel = qr.label
                selectedDocuments = Set(qr.documentIds)
            }
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                sheetOffset = 0
            }
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                iconScale = 1.0
                iconRotation = 0
            }
            // Fetch documents
            documentsService.fetchDocumentsInFolder(userId: userId, folderId: nil)
        }
        .zIndex(200)
    }
    
    private func dismissSheet() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            sheetOffset = 800
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
    
    var isFormValid: Bool {
        return !qrLabel.trimmingCharacters(in: CharacterSet(charactersIn: " \n")).isEmpty && !selectedDocuments.isEmpty
    }
    
    func generateQR() {
        guard isFormValid else { return }
        isLoading = true
        errorMessage = nil
        isTextFieldFocused = false // Close keyboard
        
        if let qr = qrToEdit {
            // Update existing QR
            secureQRService.updateQR(
                userId: userId,
                qrId: qr.id,
                label: qrLabel.trimmingCharacters(in: CharacterSet(charactersIn: " \n")),
                documentIds: Array(selectedDocuments),
                oldDocumentIds: qr.documentIds
            ) { success, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    if success {
                        self.dismissSheet()
                    } else {
                        self.errorMessage = error ?? "Failed to update QR code"
                    }
                }
            }
        } else {
            // Create new QR
            secureQRService.generateQR(
                userId: userId,
                label: qrLabel.trimmingCharacters(in: CharacterSet(charactersIn: " \n")),
                documentIds: Array(selectedDocuments)
            ) { success, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    if success {
                        self.dismissSheet()
                    } else {
                        self.errorMessage = error ?? "Failed to generate QR code"
                    }
                }
            }
        }
    }
}

// MARK: - Subviews
private extension AddQRSheet {
    
    var header: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 35)
                    .fill(themeColor) // Solid orange as per design
                    .frame(width: 90, height: 90)
                    .shadow(color: themeColor.opacity(0.3), radius: 10, x: 0, y: 5)
                
                Image(systemName: "qrcode")
                    .font(.system(size: 38))
                    .foregroundColor(.white)
            }
            .scaleEffect(iconScale)
            .rotationEffect(.degrees(iconRotation))
            .padding(.top, 8)
            
            VStack(spacing: 8) {
                Text(isEditMode ? "Edit Secure QR" : "Create Secure QR")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                
                Text(isEditMode ? "Update the label and documents\nfor your secure QR code." : "Enter a label and select documents\nto generate a secure QR code.")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 30)
            }
        }
    }
    
    var inputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("QR Label")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.gray)
                .padding(.leading, 4)
            
            TextField("e.g. Travel Docs", text: $qrLabel)
                .font(.headline)
                .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                .padding()
                .background(Color(red: 0.96, green: 0.96, blue: 0.98))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .disabled(isEditMode)
                .opacity(isEditMode ? 0.6 : 1.0)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .focused($isTextFieldFocused)
                .submitLabel(.done)
                .onSubmit {
                    isTextFieldFocused = false // Just close keyboard
                }
                .onChange(of: qrLabel) { newValue in
                     let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: " _-"))
                     let filtered = newValue.unicodeScalars.filter { allowedCharacters.contains($0) }
                     let filteredString = String(String.UnicodeScalarView(filtered))
                     if filteredString != newValue {
                         qrLabel = filteredString
                     }
                }
        }
        .padding(.horizontal, 30)
    }
    
    var documentSelectionList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Select Documents")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                Spacer()
                Text("\(selectedDocuments.count) selected")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
            }
            .padding(.horizontal, 34) // Align with list content
            
            if documentsService.currentFolderDocuments.isEmpty {
                 VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("No documents available")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(documentsService.currentFolderDocuments) { document in
                        DocumentRow(document: document, isSelected: selectedDocuments.contains(document.id)) {
                            if selectedDocuments.contains(document.id) {
                                selectedDocuments.remove(document.id)
                            } else {
                                selectedDocuments.insert(document.id)
                            }
                        }
                    }
                }
                .padding(.horizontal, 30)
            }
        }
    }
    
    var actionButton: some View {
        Button(action: generateQR) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(isEditMode ? "Update QR" : "Generate QR")
                        .fontWeight(.bold)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isFormValid ? themeColor : Color.gray.opacity(0.5))
            .cornerRadius(15)
        }
        .padding(.horizontal, 30)
        .disabled(!isFormValid || isLoading)
    }
}

// Helper View for Selection (List Row Style)
struct DocumentRow: View {
    let document: DocumentFile
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(document.type == "image" ? Color.blue.opacity(0.1) : Color.red.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: document.type == "image" ? "photo.fill" : "doc.fill")
                        .font(.system(size: 20))
                        .foregroundColor(document.type == "image" ? .blue : .red)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                        .lineLimit(1)
                    
                    Text(document.type.uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray.opacity(0.7))
                }
                
                Spacer()
                
                // Checkbox
                ZStack {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.orange)
                            .transition(.scale)
                    } else {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 24, height: 24)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.orange.opacity(0.05) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.orange.opacity(0.5) : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
