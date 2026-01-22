import SwiftUI
import CoreImage.CIFilterBuiltins

struct SecureQRView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var documentsService: DocumentsService
    @ObservedObject var secureQRService: SecureQRService
    @ObservedObject var authService: AuthService
    let userId: String
    @State private var hasAppeared = false
    @State private var showAddQRSheet = false
    @State private var showDownloadSheet = false
    @State private var showDeleteConfirmation = false
    @State private var showEditSheet = false
    @State private var selectedQR: SecureQR?
    @State private var selectedQRForDownload: SecureQR?
    
    var body: some View {
        ZStack {
            // Background - Modern light gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.98, green: 0.98, blue: 0.99),
                    Color(red: 0.96, green: 0.97, blue: 0.98)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
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
                
                // Content - QR List or Empty State
                if secureQRService.secureQRs.isEmpty {
                    // Empty State
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
                } else {
                    // QR List
                    List {
                        ForEach(secureQRService.secureQRs) { qr in
                            QRCodeCard(qr: qr, userName: authService.user?.name ?? "User", profileImageUrl: authService.user?.profileImageUrl)
                                .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))
                                .listRowBackground(Color.clear)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    // Delete
                                    Button(role: .destructive) {
                                        deleteQR(qr)
                                    } label: {
                                        Label {
                                            Text("Delete")
                                                .foregroundColor(.black)
                                        } icon: {
                                            Image(systemName: "trash")
                                                .foregroundColor(.black)
                                        }
                                    }
                                    .tint(.red)
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    // Download
                                    Button {
                                        downloadQR(qr)
                                    } label: {
                                        Label {
                                            Text("Download")
                                                .foregroundColor(.black)
                                        } icon: {
                                            Image(systemName: "arrow.down.circle")
                                                .foregroundColor(.black)
                                        }
                                    }
                                    .tint(.blue)
                                    
                                    // Edit
                                    Button {
                                        editQR(qr)
                                    } label: {
                                        Label {
                                            Text("Edit")
                                                .foregroundColor(.black)
                                        } icon: {
                                            Image(systemName: "pencil")
                                                .foregroundColor(.black)
                                        }
                                    }
                                    .tint(.orange)
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
                

            }
            .onAppear {
                hasAppeared = true
                secureQRService.startListening(userId: userId)
            }
            .onDisappear {
                secureQRService.stopListening()
            }
            .blur(radius: showAddQRSheet ? 3 : 0)
            
            // Floating Add Button (Center Aligned)
            if !secureQRService.secureQRs.isEmpty && !showAddQRSheet && !showDownloadSheet && !showDeleteConfirmation && !showEditSheet {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showAddQRSheet = true
                            }
                        }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.orange, Color.orange.opacity(0.8)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                                .shadow(color: Color.orange.opacity(0.4), radius: 10, x: 0, y: 5)
                        }
                        .padding(.bottom, 24)
                        Spacer()
                    }
                }
            }
            
            // Add QR Sheet Overlay
            if showAddQRSheet {
                AddQRSheet(
                    isPresented: $showAddQRSheet,
                    documentsService: documentsService,
                    secureQRService: secureQRService,
                    userId: userId
                )
                .zIndex(100)
            }
        }
        .navigationBarHidden(true)
        .swipeToDismiss()
        .sheet(isPresented: $showDownloadSheet) {
            if let qr = selectedQRForDownload {
                QRDownloadSheet(isPresented: $showDownloadSheet, qr: qr)
            }
        }
        .sheet(isPresented: $showDeleteConfirmation) {
            if let qr = selectedQR {
                QRDeleteConfirmationSheet(
                    isPresented: $showDeleteConfirmation,
                    qr: qr,
                    onConfirm: confirmDelete
                )
            }
        }
        .sheet(isPresented: $showEditSheet) {
            if let qr = selectedQR {
                EditQRSheet(
                    isPresented: $showEditSheet,
                    qr: qr,
                    secureQRService: secureQRService,
                    documentsService: documentsService,
                    userId: userId
                )
            }
        }
    }
    
    // MARK: - Actions
    
    private func deleteQR(_ qr: SecureQR) {
        print("DEBUG: Delete QR clicked for \(qr.label)")
        selectedQR = qr
        showDeleteConfirmation = true
    }
    
    private func editQR(_ qr: SecureQR) {
        print("DEBUG: Edit QR clicked for \(qr.label)")
        selectedQR = qr
        showEditSheet = true
    }
    
    private func downloadQR(_ qr: SecureQR) {
        print("DEBUG: Download QR clicked for \(qr.label)")
        selectedQRForDownload = qr
        showDownloadSheet = true
    }
    
    private func confirmDelete() {
        guard let qr = selectedQR else { return }
        secureQRService.deleteQR(userId: userId, qrId: qr.id) { success, error in
            if !success {
                print("Failed to delete QR: \(error ?? "Unknown error")")
            }
        }
        showDeleteConfirmation = false
        selectedQR = nil
    }
}

// MARK: - Download Sheet
struct QRDownloadSheet: View {
    @Binding var isPresented: Bool
    let qr: SecureQR
    @State private var qrImage: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Text("Download QR Code")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title2)
                }
            }
            .padding()
            
            // QR Code Display
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(width: 250, height: 250)
            } else if let image = qrImage {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 10)
            }
            
            Text(qr.label)
                .font(.headline)
            
            Text("\(qr.documentIds.count) document(s)")
                .font(.caption)
                .foregroundColor(.gray)
            
            // Share Button
            if let image = qrImage {
                Button(action: {
                    shareQR(image: image)
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share QR Code")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(15)
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.98, green: 0.98, blue: 0.96))
        .edgesIgnoringSafeArea(.all)
        .presentationDetents([.medium, .large])
        .onAppear {
            loadQRImage()
        }
    }
    
    private func loadQRImage() {
        guard let url = URL(string: qr.qrCodeUrl) else {
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            DispatchQueue.main.async {
                if let data = data, let image = UIImage(data: data) {
                    self.qrImage = image
                }
                self.isLoading = false
            }
        }.resume()
    }
    
    private func shareQR(image: UIImage) {
        let activityVC = UIActivityViewController(
            activityItems: [image, "QR Code: \(qr.label)"],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            activityVC.popoverPresentationController?.sourceView = rootVC.view
            activityVC.popoverPresentationController?.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
            activityVC.popoverPresentationController?.permittedArrowDirections = []
            rootVC.present(activityVC, animated: true)
        }
    }
}

// Button Style Support

// MARK: - QR Code Card (New Modern Design)
struct QRCodeCard: View {
    let qr: SecureQR
    let userName: String
    let profileImageUrl: String?
    
    @State private var qrImage: UIImage?
    @State private var profileImage: UIImage?
    @State private var isLoadingQR = true
    @State private var isLoadingProfile = true
    
    // Theme colors - vibrant gradient
    private let gradientColors: [Color] = [
        Color(red: 1.0, green: 0.6, blue: 0.2),  // Vibrant orange
        Color(red: 1.0, green: 0.5, blue: 0.1)   // Deep orange
    ]
    
    var body: some View {
        ZStack {
            // Card Background with Gradient
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: gradientColors),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    // Subtle pattern overlay
                    GeometryReader { geometry in
                        ZStack {
                            // Decorative circles
                            Circle()
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 120, height: 120)
                                .position(x: geometry.size.width * 0.15, y: geometry.size.height * 0.2)
                                .blur(radius: 20)
                            
                            Circle()
                                .fill(Color.white.opacity(0.06))
                                .frame(width: 100, height: 100)
                                .position(x: geometry.size.width * 0.85, y: geometry.size.height * 0.7)
                                .blur(radius: 25)
                            
                            // Abstract shapes
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Color.white.opacity(0.05))
                                .frame(width: 80, height: 80)
                                .rotationEffect(.degrees(45))
                                .position(x: geometry.size.width * 0.8, y: geometry.size.height * 0.25)
                                .blur(radius: 15)
                        }
                    }
                )
            
            // Content
            HStack(spacing: 16) {
                // Left Section: Profile & Info
                VStack(alignment: .leading, spacing: 12) {
                    // Profile Image
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.25))
                            .frame(width: 56, height: 56)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            )
                        
                        if let profileImage = profileImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 52, height: 52)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    
                    // Name
                    Text(userName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    // Document Count Badge
                    HStack(spacing: 6) {
                        Image(systemName: "doc.fill")
                            .font(.system(size: 12))
                        Text("\(qr.documentIds.count) \(qr.documentIds.count == 1 ? "File" : "Files")")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.25))
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
                            )
                    )
                    
                    // Date
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11))
                        Text(qr.createdAt, style: .date)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.85))
                }
                
                Spacer()
                
                // Right Section: QR Code
                VStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .frame(width: 110, height: 110)
                            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                        
                        if isLoadingQR {
                            ProgressView()
                                .tint(.orange)
                        } else if let qrImage = qrImage {
                            Image(uiImage: qrImage)
                                .resizable()
                                .interpolation(.none)
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .cornerRadius(12)
                        } else {
                            Image(systemName: "qrcode")
                                .font(.system(size: 40))
                                .foregroundColor(.orange.opacity(0.6))
                        }
                    }
                    
                    // QR Label
                    Text(qr.label)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.95))
                        .lineLimit(1)
                        .padding(.top, 6)
                }
            }
            .padding(20)
        }
        .frame(height: 180)
        .shadow(color: Color.orange.opacity(0.3), radius: 12, x: 0, y: 6)
        .onAppear {
            loadQRImage()
            loadProfileImage()
        }
    }
    
    private func loadQRImage() {
        guard let url = URL(string: qr.qrCodeUrl) else {
            isLoadingQR = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            DispatchQueue.main.async {
                if let data = data, let image = UIImage(data: data) {
                    self.qrImage = image
                }
                self.isLoadingQR = false
            }
        }.resume()
    }
    
    private func loadProfileImage() {
        guard let urlString = profileImageUrl, let url = URL(string: urlString) else {
            isLoadingProfile = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            DispatchQueue.main.async {
                if let data = data, let image = UIImage(data: data) {
                    self.profileImage = image
                }
                self.isLoadingProfile = false
            }
        }.resume()
    }
}

// MARK: - Delete Confirmation Sheet
struct QRDeleteConfirmationSheet: View {
    @Binding var isPresented: Bool
    let qr: SecureQR
    let onConfirm: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "trash.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.red)
            }
            .padding(.top, 20)
            
            VStack(spacing: 12) {
                Text("Delete QR Code?")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Are you sure you want to delete '\(qr.label)'? This action cannot be undone.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
            
            // Buttons
            VStack(spacing: 12) {
                Button(action: {
                    onConfirm()
                }) {
                    Text("Delete")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(15)
                }
                
                Button(action: {
                    isPresented = false
                }) {
                    Text("Cancel")
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(15)
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.98, green: 0.98, blue: 0.96))
        .edgesIgnoringSafeArea(.all)
        .presentationDetents([.height(400)])
    }
}

// MARK: - Edit QR Sheet
struct EditQRSheet: View {
    @Binding var isPresented: Bool
    let qr: SecureQR
    @ObservedObject var secureQRService: SecureQRService
    @ObservedObject var documentsService: DocumentsService
    let userId: String
    
    @State private var qrLabel: String
    @State private var selectedDocuments: Set<String>
    @State private var isUpdating = false
    
    init(isPresented: Binding<Bool>, qr: SecureQR, secureQRService: SecureQRService, documentsService: DocumentsService, userId: String) {
        self._isPresented = isPresented
        self.qr = qr
        self.secureQRService = secureQRService
        self.documentsService = documentsService
        self.userId = userId
        self._qrLabel = State(initialValue: qr.label)
        self._selectedDocuments = State(initialValue: Set(qr.documentIds))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Edit QR Code")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title2)
                }
            }
            .padding()
            
            ScrollView {
                VStack(spacing: 20) {
                    // QR Label
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
                    }
                    .padding(.horizontal)
                    
                    // Document Selection
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
                        .padding(.horizontal)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(documentsService.currentFolderDocuments) { document in
                                DocumentRow(
                                    document: document,
                                    isSelected: selectedDocuments.contains(document.id),
                                    onTap: {
                                        if selectedDocuments.contains(document.id) {
                                            selectedDocuments.remove(document.id)
                                        } else {
                                            selectedDocuments.insert(document.id)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            
            // Update Button
            Button(action: updateQR) {
                HStack {
                    if isUpdating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Update QR")
                            .fontWeight(.bold)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(!qrLabel.isEmpty && !selectedDocuments.isEmpty ? Color.orange : Color.gray.opacity(0.5))
                .cornerRadius(15)
            }
            .padding(.horizontal, 30)
            .disabled(qrLabel.isEmpty || selectedDocuments.isEmpty || isUpdating)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.98, green: 0.98, blue: 0.96))
        .edgesIgnoringSafeArea(.all)
        .presentationDetents([.medium, .large])
        .onAppear {
            documentsService.fetchDocumentsInFolder(userId: userId, folderId: nil)
        }
    }
    
    private func updateQR() {
        isUpdating = true
        secureQRService.updateQR(
            userId: userId,
            qrId: qr.id,
            label: qrLabel,
            documentIds: Array(selectedDocuments),
            oldDocumentIds: qr.documentIds
        ) { success, _ in
            DispatchQueue.main.async {
                isUpdating = false
                if success {
                    isPresented = false
                }
            }
        }
    }
}
