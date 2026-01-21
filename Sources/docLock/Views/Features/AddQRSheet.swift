import SwiftUI

struct AddQRSheet: View {
    @Binding var isPresented: Bool
    @ObservedObject var documentsService: DocumentsService
    @ObservedObject var secureQRService: SecureQRService
    let userId: String
    
    @State private var qrLabel: String = ""
    @State private var selectedDocuments: Set<String> = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var isTextFieldFocused: Bool
    // Start offscreen
    @State private var sheetOffset: CGFloat = 800
    @State private var keyboardHeight: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 0) {
                dragHandle
                
                ScrollView {
                    VStack(spacing: 24) {
                        header
                        inputSection
                        documentSelection
                        
                        // Error Message
                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal, 30)
                        }
                        
                        actionButton
                    }
                    .padding(.bottom, 20)
                }
                .scrollIndicators(.hidden)
                .frame(maxHeight: UIScreen.main.bounds.height * 0.65) // Limit to 65% of screen
            }
            .padding(.bottom, keyboardHeight) // Push up for keyboard
            .background(
                ZStack {
                    Color(red: 0.98, green: 0.98, blue: 0.96)
                    decorativeCircles
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: -5)
            .offset(y: sheetOffset)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    sheetOffset = 0
                }
                // Fetch documents
                documentsService.fetchDocumentsInFolder(userId: userId, folderId: nil)
                
                // Auto-focus after a slight delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTextFieldFocused = true
                }
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { output in
            if let keyboardFrame = output.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    self.keyboardHeight = keyboardFrame.height
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                self.keyboardHeight = 0
            }
        }
    }
    
    private func dismissSheet() {
        // Animate out
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            sheetOffset = 800
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
    
    var isFormValid: Bool {
        return !qrLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !selectedDocuments.isEmpty
    }
    
    func generateQR() {
        guard isFormValid else { return }
        isLoading = true
        errorMessage = nil
        
        // Call the service to generate QR
        secureQRService.generateQR(
            userId: userId,
            label: qrLabel.trimmingCharacters(in: .whitespacesAndNewlines),
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

// MARK: - Subviews
private extension AddQRSheet {
    
    var decorativeCircles: some View {
        GeometryReader { proxy in
            Circle()
                .fill(Color.orange.opacity(0.15))
                .frame(width: 150, height: 150)
                .position(x: 50, y: 100)
                .blur(radius: 20)
            
            Circle()
                .fill(Color.yellow.opacity(0.2))
                .frame(width: 200, height: 200)
                .position(x: proxy.size.width - 20, y: 50)
                .blur(radius: 30)
            
            Circle()
                .fill(Color.orange.opacity(0.1))
                .frame(width: 120, height: 120)
                .position(x: proxy.size.width * 0.8, y: proxy.size.height * 0.6)
                .blur(radius: 40)
        }
    }
    
    var dragHandle: some View {
        Capsule()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 40, height: 4)
            .padding(.vertical, 12)
    }
    
    var header: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.orange)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "qrcode")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                Text("Create Secure QR")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                
                Text("Enter a label and select documents\nto generate a secure QR code.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
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
            
            TextField("e.g. Travel Docs", text: $qrLabel)
                .foregroundColor(.black)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .focused($isTextFieldFocused)
                .submitLabel(.done)
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
    
    var documentSelection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Select Documents")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                Spacer()
                Text("\(selectedDocuments.count) selected")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            .padding(.horizontal, 30)
            
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
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(documentsService.currentFolderDocuments) { document in
                            DocumentSelectionCard(document: document, isSelected: selectedDocuments.contains(document.id)) {
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
    }
    
    var actionButton: some View {
        Button(action: generateQR) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Generate QR")
                        .fontWeight(.bold)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isFormValid ? Color.orange : Color.gray.opacity(0.5))
            .cornerRadius(15)
        }
        .padding(.horizontal, 30)
        .disabled(!isFormValid || isLoading)
    }
}

// Helper View for Selection
struct DocumentSelectionCard: View {
    let document: DocumentFile
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(document.type == "image" ? Color.blue.opacity(0.1) : Color.red.opacity(0.1))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: document.type == "image" ? "photo.fill" : "doc.fill")
                            .font(.system(size: 16))
                            .foregroundColor(document.type == "image" ? .blue : .red)
                    }
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.orange)
                    } else {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                            .frame(width: 20, height: 20)
                    }
                }
                
                Text(document.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(12)
            .frame(width: 140, height: 110)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.orange.opacity(0.05) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.orange.opacity(0.3) : Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
