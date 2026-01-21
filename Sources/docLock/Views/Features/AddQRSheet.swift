import SwiftUI

struct AddQRSheet: View {
    @Binding var isPresented: Bool
    @ObservedObject var documentsService: DocumentsService
    let userId: String
    
    @State private var qrLabel: String = ""
    @State private var selectedDocuments: Set<String> = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var isTextFieldFocused: Bool
    @State private var sheetOffset: CGFloat = 800
    
    var body: some View {
        ZStack {
            ScrollViewReader { proxy in // START ScrollViewReader
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // ID for scrolling
                    Color.clear.frame(height: 1).id("Top")
                // Decorative Background Pops
                GeometryReader { geometry in
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 150, height: 150)
                        .position(x: 50, y: 100)
                        .blur(radius: 20)
                    
                    Circle()
                        .fill(Color.yellow.opacity(0.2))
                        .frame(width: 200, height: 200)
                        .position(x: geometry.size.width - 20, y: 50)
                        .blur(radius: 30)
                    
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 100, height: 100)
                        .position(x: geometry.size.width / 2, y: geometry.size.height - 100)
                        .blur(radius: 15)
                }
                .frame(height: 0) // Don't affect layout
                .zIndex(0)
                
                // Drag Handle
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 4)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                
                // Header
                HStack {
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isPresented = false
                        }
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
                    }
                    
                    Spacer()
                    Text("Add QR")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                    Spacer()
                    // Balance spacer with hidden button size
                    Color.clear.frame(width: 56, height: 56)
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
                
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color.orange)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "qrcode")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
                .padding(.bottom, 20)
                
                // Title
                Text("Create Secure QR")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                    .padding(.bottom, 10)
                
                Text("Enter a label and select documents\nto generate a secure QR code.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 30)
                
                // Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("QR Label")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                    
                    TextField("e.g. Travel Docs, Medical Records", text: $qrLabel)
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
                        .onChange(of: qrLabel) { newValue in
                            // Filter only alphanumeric, space, underscore, dash
                            let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: " _-"))
                            let filtered = newValue.unicodeScalars.filter { allowedCharacters.contains($0) }
                            let filteredString = String(String.UnicodeScalarView(filtered))
                            if filteredString != newValue {
                                qrLabel = filteredString
                            }
                        }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 20)
                .onAppear {
                    // Autofocus the text field when view appears
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isTextFieldFocused = true
                    }
                }
                
                // Documents List
                VStack(alignment: .leading, spacing: 8) {
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
                    
                    ScrollView {
                        VStack(spacing: 12) {
                            if documentsService.currentFolderDocuments.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "doc.text")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray.opacity(0.5))
                                    Text("No documents available")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                .frame(height: 100)
                                .frame(maxWidth: .infinity)
                            } else {
                                ForEach(documentsService.currentFolderDocuments) { document in
                                    Button(action: {
                                        if selectedDocuments.contains(document.id) {
                                            selectedDocuments.remove(document.id)
                                        } else {
                                            selectedDocuments.insert(document.id)
                                        }
                                    }) {
                                        HStack(spacing: 16) {
                                            // Document Icon
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 14)
                                                    .fill(
                                                        document.type == "image" ?
                                                        Color.blue.opacity(0.1) :
                                                        Color.red.opacity(0.1)
                                                    )
                                                    .frame(width: 48, height: 48)
                                                
                                                Image(systemName: document.type == "image" ? "photo.fill" : "doc.fill")
                                                    .font(.system(size: 20))
                                                    .foregroundColor(
                                                        document.type == "image" ? .blue : .red
                                                    )
                                            }
                                            
                                            // Document Name
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(document.name)
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                                                    .lineLimit(1)
                                                Text(document.type == "image" ? "Image" : "Document")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                            
                                            Spacer()
                                            
                                            // Selection Indicator
                                            if selectedDocuments.contains(document.id) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 24))
                                                    .foregroundColor(.orange)
                                            } else {
                                                Circle()
                                                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                                    .frame(width: 24, height: 24)
                                            }
                                        }
                                        .padding(12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 18)
                                                .fill(selectedDocuments.contains(document.id) ? Color.orange.opacity(0.05) : Color.white)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 18)
                                                .stroke(
                                                    selectedDocuments.contains(document.id) ? Color.orange.opacity(0.3) : Color.gray.opacity(0.1),
                                                    lineWidth: 1
                                                )
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding(.horizontal, 30)
                    }
                    .frame(maxHeight: 200)
                }
                .padding(.bottom, 20)
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.bottom, 10)
                        .padding(.horizontal, 30)
                }
                
                // Button
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
                .padding(.bottom, isTextFieldFocused ? 320 : 20)
            }
            } // End ScrollView
            .onChange(of: isTextFieldFocused) { focused in
                if !focused { withAnimation { proxy.scrollTo("Top", anchor: .top) } }
            }
            .background(
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isTextFieldFocused = false
                    }
            )
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isTextFieldFocused = false
                    }
                }
            }
            } // End ScrollViewReader
            .background(
                ZStack {
                    Color(red: 0.98, green: 0.98, blue: 0.96) // Base Color
                    
                    // Decorative Pops
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
                .cornerRadius(30, corners: [.topLeft, .topRight])
                .edgesIgnoringSafeArea(.bottom)
            )
            .offset(y: sheetOffset)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    sheetOffset = 0
                }
                // Fetch documents from root
                documentsService.fetchDocumentsInFolder(userId: userId, folderId: nil)
                // Autofocus the text field when view appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isTextFieldFocused = true
                }
            }
        }
    }
    
    var isFormValid: Bool {
        return !qrLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !selectedDocuments.isEmpty
    }
    
    func generateQR() {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = nil
        
        // TODO: Implement QR generation logic
        // For now, just close the sheet
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isPresented = false
            }
        }
    }
}
