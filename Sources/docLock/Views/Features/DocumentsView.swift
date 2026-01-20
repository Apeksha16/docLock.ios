import SwiftUI
import UniformTypeIdentifiers
import FirebaseFirestore
import PDFKit
import CoreGraphics

struct DocFolder: Identifiable {
    let id: String
    let name: String
    let itemCount: Int
    let icon: String
    let parentFolderId: String? // nil for root level folders
    let depth: Int // nesting depth (0 for root)
}

struct DocumentFile: Identifiable {
    let id: String
    let name: String
    let type: String // "document" or "image"
    let url: String
    let size: Int
    let createdAt: Date?
    let isShared: Bool
    let sharedBy: String?
    let sharedByName: String?
}

struct DocumentsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var documentsService: DocumentsService
    @ObservedObject var friendsService: FriendsService
    @ObservedObject var notificationService: NotificationService
    let userId: String
    
    @State private var searchText: String = ""
    @State private var showFabMenu = false
    
    // Breadcrumb state
    @State private var currentPath: [String] = ["HOME"]
    @State private var selectedFolderId: String? = nil
    @State private var selectedFolderName: String? = nil
    @State private var selectedFolderDepth: Int = 0 // Track the actual depth of the current folder
    @State private var pathFolderIds: [String?] = [nil] // Track folder IDs for each path segment (nil for HOME)
    @State private var showCreateFolderSheet = false
    @State private var showUploadDocumentSheet = false
    @State private var showUploadImageSheet = false
    @State private var showEditFolderSheet = false
    @State private var folderToEdit: DocFolder?
    @State private var showDeleteConfirmation = false
    @State private var folderToDelete: DocFolder?
    @State private var isDeletingFolder = false
    @State private var showEditDocumentSheet = false
    @State private var documentToEdit: DocumentFile?
    @State private var showDeleteDocumentConfirmation = false
    @State private var documentToDelete: DocumentFile?
    @State private var isDeletingDocument = false
    @State private var showDocumentPreview = false
    @State private var documentToPreview: DocumentFile?
    @State private var showingFriendSelection = false
    @State private var documentToShare: DocumentFile?
    
    // Toast messages
    @State private var toastMessage: String?
    @State private var toastType: ToastType = .success
    
    // Current location for uploads/creates
    var currentLocationFolderId: String? {
        selectedFolderId
    }
    
    // Get the actual depth of the current folder
    var currentFolderDepth: Int {
        if selectedFolderId != nil {
            // Use the stored depth of the selected folder
            return selectedFolderDepth
        }
        // Root level
        return 0
    }
    
    // Check if we can create a folder at the current location
    var canCreateFolderAtCurrentLocation: Bool {
        let maxDepth = documentsService.appConfigService?.maxFolderDepth ?? 3
        let currentDepth = currentFolderDepth
        
        // Can create if current depth + 1 < maxDepth
        // e.g., if maxDepth is 3: can create at depth 0 or 1, but not at depth 2 or higher
        // At depth 2: 2 + 1 = 3, which equals maxDepth, so cannot create
        // At depth 3: 3 + 1 = 4, which exceeds maxDepth, so cannot create
        // At depth 4: 4 + 1 = 5, which exceeds maxDepth (if maxDepth is 3 or 4), so cannot create
        let canCreate = currentDepth + 1 < maxDepth
        
        // Debug logging
        print("🔍 canCreateFolderAtCurrentLocation: currentDepth=\(currentDepth), maxDepth=\(maxDepth), newDepthWouldBe=\(currentDepth + 1), canCreate=\(canCreate)")
        
        return canCreate
    }
    
    // Computed property to inject "Shared" folder if needed
    var displayedFolders: [DocFolder] {
        var folders = documentsService.folders
        if selectedFolderId == nil && documentsService.sharedDocsCount > 0 {
             let sharedFolder = DocFolder(id: "SHARED_ROOT", name: "Shared", itemCount: documentsService.sharedDocsCount, icon: "person.2.fill", parentFolderId: nil, depth: 0)
             folders.insert(sharedFolder, at: 0)
        }
        return folders
    }
    
    // Check if we have any folders to display (including Shared)
    var hasFoldersToDisplay: Bool {
        return !displayedFolders.isEmpty
    }
    
    // Track folder hierarchy for navigation
    @State private var folderHierarchy: [String] = [] // Array of folder IDs from root to current
    
    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.97, blue: 0.99) // Very light blue/gray background
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        // Always go back to dashboard
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
                    Text("My Documents")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding()
                
                // Search Bar (Only show if documents exist)
                if !documentsService.folders.isEmpty {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search docs...", text: $searchText)
                            .onChange(of: searchText) { newValue in
                                let filtered = newValue.filter { "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 _-".contains($0) }
                                if filtered != newValue {
                                    searchText = filtered
                                }
                            }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
                    .padding(.horizontal)
                    .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                }
                
                // Breadcrumbs (Show if we have folders or are in a folder)
                if !documentsService.folders.isEmpty || selectedFolderId != nil {
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 5) {
                                ForEach(0..<currentPath.count, id: \.self) { index in
                                    HStack {
                                        if index == 0 {
                                            Image(systemName: "house")
                                                .font(.caption)
                                        }
                                        Text(currentPath[index])
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .textCase(.uppercase)
                                        
                                        if index < currentPath.count - 1 {
                                            Image(systemName: "chevron.right")
                                                .font(.caption2)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .foregroundColor(index == currentPath.count - 1 ? .blue : .gray)
                                    .id(index)
                                    .onTapGesture {
                                        navigateToBreadcrumb(index: index)
                                    }
                                }
                                // Add spacer to ensure trailing padding is visible when scrolled
                                Spacer()
                                    .frame(width: 1)
                                    .id("trailing-spacer")
                            }
                            .padding(.leading, 16)
                            .padding(.trailing, 16)
                            .padding(.top, 20)
                        }
                        .onChange(of: currentPath.count) { count in
                            // Auto-scroll to show the last breadcrumb item with proper trailing padding
                            if currentPath.count > 0 {
                                // Increased delay to ensure layout is ready
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        // Scroll to the trailing spacer to ensure full visibility of last item
                                        proxy.scrollTo("trailing-spacer", anchor: .trailing)
                                    }
                                }
                            }
                        }
                        .onAppear {
                            // Scroll to last item on appear
                            if currentPath.count > 0 {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        proxy.scrollTo("trailing-spacer", anchor: .trailing)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Content
                if !hasFoldersToDisplay {
                    DocumentsEmptyState(
                        showCreateFolderSheet: $showCreateFolderSheet,
                        showUploadDocumentSheet: $showUploadDocumentSheet,
                        showUploadImageSheet: $showUploadImageSheet
                    )
                } else if let folderId = selectedFolderId {
                    // Show folder contents
                    FolderContentsView(
                        documentsService: documentsService,
                        userId: userId,
                        folderId: folderId,
                        folderName: selectedFolderName ?? "Folder",
                        appConfigService: documentsService.appConfigService!,
                        onFolderTap: { folder in
                            // Stop current folder listeners before navigating
                            documentsService.stopListeningToFolder()
                            
                            selectedFolderId = folder.id
                            selectedFolderName = folder.name
                            selectedFolderDepth = folder.depth // Store the actual depth from Firestore
                            if folderHierarchy.isEmpty {
                                folderHierarchy = [folder.id]
                                pathFolderIds = [nil, folder.id]
                            } else {
                                folderHierarchy.append(folder.id)
                                pathFolderIds.append(folder.id)
                            }
                            withAnimation {
                                currentPath.append(folder.name)
                            }
                            // Fetch with real-time listeners
                            documentsService.fetchDocumentsInFolder(userId: userId, folderId: folder.id)
                            documentsService.fetchFoldersInFolder(userId: userId, parentFolderId: folder.id)
                        },
                        onBack: {
                            // Stop current folder listeners
                            documentsService.stopListeningToFolder()
                            
                            // Navigate to parent folder
                            if folderHierarchy.count > 1 {
                                // Go to parent folder
                                folderHierarchy.removeLast()
                                pathFolderIds.removeLast()
                                let parentId = folderHierarchy.last
                                
                                if let parentId = parentId {
                                    selectedFolderId = parentId
                                    if currentPath.count > 1 {
                                        selectedFolderName = currentPath[currentPath.count - 2]
                                    }
                                    // Update depth: parent folder's depth is current depth - 1
                                    selectedFolderDepth = max(0, selectedFolderDepth - 1)
                                    // Fetch with real-time listeners
                                    documentsService.fetchDocumentsInFolder(userId: userId, folderId: parentId)
                                    documentsService.fetchFoldersInFolder(userId: userId, parentFolderId: parentId)
                                } else {
                                    // Go back to root
                                    selectedFolderId = nil
                                    selectedFolderName = nil
                                    selectedFolderDepth = 0
                                    folderHierarchy = []
                                    pathFolderIds = [nil]
                                    documentsService.startListening(userId: userId, parentFolderId: nil)
                                }
                                } else {
                                    // Go back to root
                                    selectedFolderId = nil
                                    selectedFolderName = nil
                                    selectedFolderDepth = 0
                                    folderHierarchy = []
                                    pathFolderIds = [nil]
                                    documentsService.startListening(userId: userId, parentFolderId: nil)
                                }
                            withAnimation {
                                if currentPath.count > 1 {
                                    currentPath.removeLast()
                                }
                            }
                        },
                        onCreateFolder: {
                            showCreateFolderSheet = true
                        },
                        onUploadDocument: {
                            showUploadDocumentSheet = true
                        },
                        onUploadImage: {
                            showUploadImageSheet = true
                        },
                        onEditFolder: { folder in
                            folderToEdit = folder
                            showEditFolderSheet = true
                        },
                        onDeleteFolder: { folder in
                            folderToDelete = folder
                            showDeleteConfirmation = true
                        },
                        onEditDocument: { document in
                            documentToEdit = document
                            showEditDocumentSheet = true
                        },
                        onDeleteDocument: { document in
                            documentToDelete = document
                            showDeleteDocumentConfirmation = true
                        },
                        onShareDocument: { document in
                            documentToShare = document
                            showingFriendSelection = true
                        },
                        onPreviewDocument: { document in
                            documentToPreview = document
                            showDocumentPreview = true
                        }
                    )
                } else {
                    // Show folders in list view with swipe actions
                    List {
                        ForEach(displayedFolders) { folder in
                            FolderListRow(folder: folder) {
                                // Stop current folder listeners before navigating (if in a folder)
                                if selectedFolderId != nil {
                                    documentsService.stopListeningToFolder()
                                }
                                
                                selectedFolderId = folder.id
                                selectedFolderName = folder.name
                                selectedFolderDepth = folder.depth // Store the actual depth from Firestore
                                if folderHierarchy.isEmpty {
                                    folderHierarchy = [folder.id]
                                    pathFolderIds = [nil, folder.id]
                                } else {
                                    folderHierarchy.append(folder.id)
                                    pathFolderIds.append(folder.id)
                                }
                                withAnimation {
                                    currentPath.append(folder.name)
                                }
                                // Fetch with real-time listeners
                                documentsService.fetchDocumentsInFolder(userId: userId, folderId: folder.id)
                                documentsService.fetchFoldersInFolder(userId: userId, parentFolderId: folder.id)
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                // Delete action
                                Button(role: .destructive) {
                                    deleteFolder(folderId: folder.id, folderName: folder.name)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .tint(.red)
                                .disabled(folder.id == "SHARED_ROOT") // Cannot delete Shared folder
                                
                                // Edit action
                                Button {
                                    editFolder(folder: folder)
                                } label: {
                                    Image(systemName: "pencil")
                                }
                                .tint(.blue)
                                .disabled(folder.id == "SHARED_ROOT") // Cannot edit Shared folder
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollIndicators(.hidden)
                }
            }
            .blur(radius: (showFabMenu || showCreateFolderSheet || showUploadDocumentSheet || showUploadImageSheet) ? 2 : 0) // Blur background when modal is open
            .allowsHitTesting(!(showUploadDocumentSheet || showUploadImageSheet || showCreateFolderSheet)) // Block interactions when sheets are open
            
            // Create Folder Sheet
            if showCreateFolderSheet {
                CreateFolderSheet(
                    documentsService: documentsService,
                    userId: userId,
                    parentFolderId: currentLocationFolderId,
                    parentDepth: currentFolderDepth,
                    isPresented: $showCreateFolderSheet,
                    toastMessage: $toastMessage,
                    toastType: $toastType
                )
            }
            
            // Upload Document Sheet
            if showUploadDocumentSheet {
                UploadDocumentSheet(
                    documentsService: documentsService,
                    userId: userId,
                    folderId: currentLocationFolderId,
                    isPresented: $showUploadDocumentSheet,
                    toastMessage: $toastMessage,
                    toastType: $toastType
                )
            }
            
            // Upload Image Sheet
            if showUploadImageSheet {
                UploadImageSheet(
                    documentsService: documentsService,
                    userId: userId,
                    folderId: currentLocationFolderId,
                    isPresented: $showUploadImageSheet,
                    toastMessage: $toastMessage,
                    toastType: $toastType
                )
            }
            
            // FAB Overlay
            if showFabMenu && !documentsService.folders.isEmpty {
                Color.white.opacity(0.8)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                         withAnimation {
                             showFabMenu = false
                         }
                    }
                
                VStack(spacing: 20) {
                     Spacer()
                    
                    // Only show "Create Folder" if we can create at current depth
                    if canCreateFolderAtCurrentLocation {
                        Button(action: {
                            withAnimation {
                                showFabMenu = false
                                showCreateFolderSheet = true
                            }
                        }) {
                        FabMenuRow(title: "Create Folder", icon: "folder.badge.plus", colors: [Color(red: 0.2, green: 0.2, blue: 0.3), Color(red: 0.3, green: 0.3, blue: 0.45)])
                        }
                    }
                    
                    Button(action: {
                        withAnimation {
                            showFabMenu = false
                            showUploadImageSheet = true
                        }
                    }) {
                        FabMenuRow(title: "Upload Img", icon: "photo", colors: [Color.cyan, Color.cyan.opacity(0.7)])
                    }
                    
                    Button(action: {
                        withAnimation {
                            showFabMenu = false
                            showUploadDocumentSheet = true
                        }
                    }) {
                        FabMenuRow(title: "Upload Doc", icon: "doc.text", colors: [Color.blue, Color(red: 0.2, green: 0.5, blue: 0.9)])
                    }
                    
                    Spacer().frame(height: 80) // Space for close button
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // FAB Button (Center Bottom)
            // Show FAB if we have folders or are in a folder (even at max depth, we can still upload)
            if !documentsService.folders.isEmpty || selectedFolderId != nil {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation(.spring()) {
                                showFabMenu.toggle()
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(showFabMenu ? Color.blue.opacity(0.8) : Color.blue)
                                    .frame(width: 60, height: 60)
                                    .shadow(color: Color.blue.opacity(0.4), radius: 10, x: 0, y: 5)
                                
                                Image(systemName: "plus")
                                    .font(.system(size: 30, weight: .medium))
                                    .foregroundColor(.white)
                                    .rotationEffect(.degrees(showFabMenu ? 135 : 0))
                            }
                        }
                        Spacer()
                    }
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarHidden(true)
        .swipeToDismiss()
        .toast(message: $toastMessage, type: toastType)
        .overlay(
            Group {
                // Friend Selection Sheet
                if showingFriendSelection {
                    FriendSelectionSheet(
                        friends: friendsService.friends,
                        onShare: { friend in
                            if let document = documentToShare {
                                documentsService.shareDocument(userId: userId, document: document, friendId: friend.id, notificationService: notificationService) { success, error in
                                    DispatchQueue.main.async {
                                        if success {
                                            toastMessage = "Shared '\(document.name)' with \(friend.name)"
                                            toastType = .success
                                        } else {
                                            toastMessage = error ?? "Failed to share document"
                                            toastType = .error
                                        }
                                    }
                                }
                            }
                        },
                        isPresented: $showingFriendSelection,
                        sharingTitle: documentToShare?.type == "image" ? "Image" : "Document"
                    )
                }
                
                // Document Preview
                if showDocumentPreview, let document = documentToPreview {
                    DocumentPreviewView(
                        document: document,
                        documentsService: documentsService,
                        friendsService: friendsService,
                        notificationService: notificationService,
                        userId: userId,
                        folderId: selectedFolderId,
                        isPresented: $showDocumentPreview,
                        onDelete: {
                            documentToDelete = document
                            showDeleteDocumentConfirmation = true
                            showDocumentPreview = false
                        },
                        onShare: {
                            documentToShare = document
                            showingFriendSelection = true
                            showDocumentPreview = false
                        },
                        toastMessage: $toastMessage,
                        toastType: $toastType
                    )
                }
            }
        )
        .onAppear {
            documentsService.startListening(userId: userId, parentFolderId: nil)
            // Calculate storage size in background
            DispatchQueue.global(qos: .utility).async {
                documentsService.updateStorageSize(userId: userId, fileSize: 0, isAdd: false)
            }
        }
        .sheet(isPresented: $showEditFolderSheet) {
            if let folder = folderToEdit {
                CreateFolderSheet(
                    documentsService: documentsService,
                    userId: userId,
                    parentFolderId: currentLocationFolderId, // Not used for edit
                    parentDepth: currentFolderDepth,   // Not used for edit
                    isPresented: $showEditFolderSheet,
                    toastMessage: $toastMessage,
                    toastType: $toastType,
                    folderToEdit: folder
                )
            }
        }
        .sheet(isPresented: $showEditDocumentSheet) {
            if let document = documentToEdit {
                EditDocumentSheet(
                    documentsService: documentsService,
                    userId: userId,
                    document: document,
                    folderId: selectedFolderId,
                    isPresented: $showEditDocumentSheet,
                    toastMessage: $toastMessage,
                    toastType: $toastType
                )
            }
        }
        .overlay(
            Group {
                if showDeleteConfirmation, let folder = folderToDelete {
                    CustomActionModal(
                        icon: "trash.fill",
                        iconBgColor: .red,
                        title: "Delete Folder?",
                        subtitle: nil,
                        message: "Are you sure you want to delete '\(folder.name)'? This action cannot be undone.",
                        primaryButtonText: "Delete",
                        primaryButtonColor: .red,
                        onPrimaryAction: {
                            isDeletingFolder = true
                            documentsService.deleteFolder(userId: userId, folderId: folder.id) { success, error in
                                DispatchQueue.main.async {
                                    isDeletingFolder = false
                                    showDeleteConfirmation = false
                                    folderToDelete = nil
                                    if success {
                                        toastMessage = "Folder '\(folder.name)' deleted successfully"
                                        toastType = .success
                                    } else {
                                        toastMessage = error ?? "Failed to delete folder"
                                        toastType = .error
                                    }
                                }
                            }
                        },
                        onCancel: {
                            if !isDeletingFolder {
                                showDeleteConfirmation = false
                                folderToDelete = nil
                            }
                        },
                        isLoading: isDeletingFolder
                    )
                    .zIndex(300)
                }
                
                if showDeleteDocumentConfirmation, let document = documentToDelete {
                    CustomActionModal(
                        icon: "trash.fill",
                        iconBgColor: .red,
                        title: "Delete \(document.type == "image" ? "Image" : "Document")?",
                        subtitle: nil,
                        message: "Are you sure you want to delete '\(document.name)'? This action cannot be undone.",
                        primaryButtonText: "Delete",
                        primaryButtonColor: .red,
                        onPrimaryAction: {
                            isDeletingDocument = true
                            documentsService.deleteDocument(userId: userId, documentId: document.id, folderId: selectedFolderId) { success, error in
                                DispatchQueue.main.async {
                                    isDeletingDocument = false
                                    showDeleteDocumentConfirmation = false
                                    documentToDelete = nil
                                    if success {
                                        toastMessage = "\(document.type == "image" ? "Image" : "Document") '\(document.name)' deleted successfully"
                                        toastType = .success
                                    } else {
                                        toastMessage = error ?? "Failed to delete \(document.type == "image" ? "image" : "document")"
                                        toastType = .error
                                    }
                                }
                            }
                        },
                        onCancel: {
                            if !isDeletingDocument {
                                showDeleteDocumentConfirmation = false
                                documentToDelete = nil
                            }
                        },
                        isLoading: isDeletingDocument
                    )
                    .zIndex(300)
                }
            }
        )
    }
    
    // MARK: - Helper Functions
    func editFolder(folder: DocFolder) {
        folderToEdit = folder
        showEditFolderSheet = true
    }
    
    func deleteFolder(folderId: String, folderName: String) {
        if let folder = documentsService.folders.first(where: { $0.id == folderId }) {
            folderToDelete = folder
            showDeleteConfirmation = true
        }
    }
    
    func navigateToBreadcrumb(index: Int) {
        // If clicking on HOME (index 0), go to root
        if index == 0 {
            selectedFolderId = nil
            selectedFolderName = nil
            selectedFolderDepth = 0
            folderHierarchy = []
            pathFolderIds = [nil]
            documentsService.stopListeningToFolder()
            documentsService.startListening(userId: userId, parentFolderId: nil)
            withAnimation {
                currentPath = ["HOME"]
            }
            return
        }
        
        // If clicking on current location, do nothing
        if index == currentPath.count - 1 {
            return
        }
        
        // Navigate to the clicked breadcrumb location
        let targetFolderId = pathFolderIds[index]
        
        guard let folderId = targetFolderId else {
            // This shouldn't happen for non-HOME items, but handle it
            selectedFolderId = nil
            selectedFolderName = nil
            folderHierarchy = []
            pathFolderIds = [nil]
            documentsService.stopListeningToFolder()
            documentsService.startListening(userId: userId, parentFolderId: nil)
            withAnimation {
                currentPath = ["HOME"]
            }
            return
        }
        
        // Stop current folder listeners before navigating
        documentsService.stopListeningToFolder()
        
        // Navigate to this folder
        selectedFolderId = folderId
        selectedFolderName = currentPath[index]
        
        // Fetch the actual folder depth from Firestore instead of calculating from index
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("folders").document(folderId).getDocument { snapshot, error in
            DispatchQueue.main.async {
                if let data = snapshot?.data() {
                    let actualDepth = data["depth"] as? Int ?? (index - 1)
                    selectedFolderDepth = actualDepth
                    print("📂 navigateToBreadcrumb: Fetched actual depth \(actualDepth) for folder \(folderId) at breadcrumb index \(index)")
                } else {
                    // Fallback to index-based calculation if fetch fails
                    selectedFolderDepth = index - 1
                    print("⚠️ navigateToBreadcrumb: Could not fetch depth, using index-based: \(index - 1)")
                }
            }
        }
        
        // Update hierarchy and path to match the clicked breadcrumb
        folderHierarchy = Array(pathFolderIds[1...index].compactMap { $0 })
        withAnimation {
            currentPath = Array(currentPath[0...index])
        }
        pathFolderIds = Array(pathFolderIds[0...index])
        
        // Fetch data for this folder with real-time listeners
        documentsService.fetchDocumentsInFolder(userId: userId, folderId: folderId)
        documentsService.fetchFoldersInFolder(userId: userId, parentFolderId: folderId)
    }
}

// MARK: - Subviews
struct DocumentsEmptyState: View {
    @Binding var showCreateFolderSheet: Bool
    @Binding var showUploadDocumentSheet: Bool
    @Binding var showUploadImageSheet: Bool
    @State private var hasAppeared = false
    
    var body: some View {
        VStack {
            Spacer().frame(height: 50)
            
            ZStack {
                // Animated Background Glow
                RoundedRectangle(cornerRadius: 50)
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.85, green: 0.9, blue: 1.0).opacity(hasAppeared ? 1 : 0.5), // Light Blue
                                Color(red: 0.9, green: 0.95, blue: 1.0).opacity(hasAppeared ? 0.8 : 0.3)
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
                Image(systemName: "doc.fill")
                    .font(.system(size: 90, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue,
                                Color.blue.opacity(0.7)
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
                                Color.blue.opacity(0.4),
                                Color.cyan.opacity(0.2)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .offset(x: -90, y: -90)
                    .scaleEffect(hasAppeared ? 1 : 0.5)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: hasAppeared)
                
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 30, height: 30)
                    .offset(x: 100, y: 70)
                    .scaleEffect(hasAppeared ? 1 : 0.5)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5), value: hasAppeared)
            }
            .animation(.spring(response: 0.8, dampingFraction: 0.7), value: hasAppeared)
            
            Spacer().frame(height: 40)
            
            // Content Text
            VStack(spacing: 18) {
                Text("Safekeep Your Life")
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
                
                Text("Securely store and organize your important\ndocuments and access them anywhere.")
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
            
            // Action Buttons
            VStack(spacing: 15) {
                // Upload Document
                EmptyStateActionButton(title: "Upload Document", icon: "doc.text.fill", color: .blue) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showUploadDocumentSheet = true
                    }
                }
                
                // Upload Image
                EmptyStateActionButton(title: "Upload Image", icon: "photo.fill", color: .cyan) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showUploadImageSheet = true
                    }
                }
                
                // Create Folder
                EmptyStateActionButton(title: "Create Folder", icon: "folder.badge.plus", color: Color(red: 0.3, green: 0.35, blue: 0.4)) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showCreateFolderSheet = true
                    }
                }
            }
            .padding(.horizontal, 30)
            .padding(.top, 30)
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 30)
            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.4), value: hasAppeared)
            
            Spacer()
        }
        .onAppear {
            withAnimation {
                hasAppeared = true
            }
        }
    }
}

struct EmptyStateActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                LinearGradient(gradient: Gradient(colors: [color, color.opacity(0.8)]), startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(18)
            .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
}

// Renamed from FabMenuButton to avoid conflict if any, but kept simple
struct FabMenuRow: View {
    let title: String
    let icon: String
    let colors: [Color]
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.headline)
            Text(title)
                .fontWeight(.semibold)
        }
        .foregroundColor(.white)
        .frame(width: 200, height: 50)
        .background(
            LinearGradient(
                gradient: Gradient(colors: colors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(15)
        .shadow(color: colors.first?.opacity(0.4) ?? .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

struct CreateFolderSheet: View {
    @ObservedObject var documentsService: DocumentsService
    let userId: String
    let parentFolderId: String?
    let parentDepth: Int
    @Binding var isPresented: Bool
    @Binding var toastMessage: String?
    @Binding var toastType: ToastType
    var folderToEdit: DocFolder? = nil // Optional folder to edit
    
    @State private var folderName: String = ""
    @State private var sheetOffset: CGFloat = 800
    @State private var iconScale: CGFloat = 0.5
    @State private var iconRotation: Double = -180
    @FocusState private var isFocused: Bool
    
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
            
            // Modal Content (Centered)
            VStack(spacing: 20) {
                // Drag Handle
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 4)
                    .padding(.top, 10)
                
                // Premium Animated Header Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.15),
                                    Color.blue.opacity(0.08)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: folderToEdit != nil ? "pencil" : "folder.badge.plus")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.blue)
                }
                .scaleEffect(iconScale)
                .rotationEffect(.degrees(iconRotation))
                .padding(.top, 5)
                
                // Title & Subtitle
                VStack(spacing: 8) {
                    Text(folderToEdit != nil ? "Edit Folder" : "New Folder")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                    
                    Text(folderToEdit != nil ? "Update your folder name." : "Organize your documents with ease.\nGive your new folder a name.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal)
                }
                
                // Input Field
                TextField("Folder Name", text: $folderName)
                    .font(.headline)
                    .padding()
                    .background(Color(red: 0.96, green: 0.96, blue: 0.98))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .focused($isFocused)
                    .padding(.horizontal, 25)
                    .submitLabel(.done)
                    .onChange(of: folderName) { newValue in
                        // Only allow alphanumeric, space, hyphen, and underscore
                        var filtered = newValue.filter { char in
                            char.isLetter || char.isNumber || char == " " || char == "-" || char == "_"
                        }
                        // Limit to 30 characters
                        if filtered.count > 30 {
                            filtered = String(filtered.prefix(30))
                        }
                        if folderName != filtered {
                            folderName = filtered
                        }
                    }
                
                // Action Buttons
                VStack(spacing: 15) {
                    Button(action: {
                        if let folder = folderToEdit {
                            // Update existing folder
                            documentsService.updateFolder(userId: userId, folderId: folder.id, newName: folderName) { success, error in
                                DispatchQueue.main.async {
                                    if success {
                                        toastMessage = "Folder renamed to '\(folderName)'"
                                        toastType = .success
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            isPresented = false
                                        }
                                    } else {
                                        toastMessage = error ?? "Failed to update folder"
                                        toastType = .error
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            isPresented = false
                                        }
                                    }
                                }
                            }
                        } else {
                            // Create folder in background (no loader)
                            let maxDepth = documentsService.appConfigService?.maxFolderDepth ?? 5
                            documentsService.createFolder(userId: userId, folderName: folderName, parentFolderId: parentFolderId, parentDepth: parentDepth, maxDepth: maxDepth) { success, error in
                                DispatchQueue.main.async {
                                    if success {
                                        toastMessage = "Folder '\(folderName)' created successfully"
                                        toastType = .success
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            isPresented = false
                                        }
                                    } else {
                                        toastMessage = error ?? "Failed to create folder"
                                        toastType = .error
                                        print("Error creating folder: \(error ?? "Unknown error")")
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            isPresented = false
                                        }
                                    }
                                }
                            }
                        }
                    }) {
                        Text(folderToEdit != nil ? "Update Folder" : "Create Folder")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(folderName.isEmpty || (folderToEdit != nil && folderName == folderToEdit?.name) ? Color.gray.opacity(0.5) : Color.blue)
                            .cornerRadius(15)
                    }
                    .disabled(folderName.isEmpty || (folderToEdit != nil && folderName == folderToEdit?.name))
                    
                    Button(action: {
                        withAnimation { isPresented = false }
                    }) {
                        Text("Cancel")
                        .fontWeight(.medium)
                            .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                    }
                }
                .padding(.horizontal, 25)
                .padding(.bottom, 20)
                
            }
            .padding(.bottom, 20)
            .background(
                Color.white
                    .edgesIgnoringSafeArea(.bottom)
            )
            .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight]))
            .offset(y: sheetOffset)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .transition(.move(edge: .bottom))
            .onAppear {
                if let folder = folderToEdit {
                    folderName = folder.name
                }
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    sheetOffset = 0
                }
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                    iconScale = 1.0
                    iconRotation = 0
                }
                // Auto focus
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isFocused = true
                }
            }
        }
        .zIndex(200) // Ensure it appears on top
        .edgesIgnoringSafeArea(.all)
    }
}

// MARK: - Upload Document Sheet
struct UploadDocumentSheet: View {
    @ObservedObject var documentsService: DocumentsService
    let userId: String
    let folderId: String?
    @Binding var isPresented: Bool
    @Binding var toastMessage: String?
    @Binding var toastType: ToastType
    @State private var isUploading = false
    @State private var errorMessage: String?
    @State private var sheetOffset: CGFloat = 800
    @State private var iconScale: CGFloat = 0.5
    @State private var iconRotation: Double = -180
    @State private var showImagePicker = false
    @State private var showDocumentPicker = false
    @State private var selectedFile: URL?
    
    var body: some View {
        ZStack {
            // Blocking overlay to prevent background interactions
            Color.clear
                .contentShape(Rectangle())
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                     if !isUploading {
                         withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                             isPresented = false
                         }
                     }
                }
            
            // Modal Content
            VStack(spacing: 0) {
                // Premium Drag Handle
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 5)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                
                VStack(spacing: 24) {
                    // Header (Always visible, changes content based on state)
                    VStack(spacing: 18) {
                        // Premium Animated Icon
                        ZStack {
                            RoundedRectangle(cornerRadius: 35)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.blue,
                                            Color.blue.opacity(0.8)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 90, height: 90)
                            
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 38, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .scaleEffect(iconScale)
                        .rotationEffect(.degrees(iconRotation))
                        .padding(.top, 8)
                        
                        VStack(spacing: 8) {
                            Text(isUploading ? "Uploading..." : "Upload Document")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                            
                            Text(isUploading ? "Please wait while we secure your document." : "Select a PDF file to securely upload\nto your documents.")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
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
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.bottom, 8)
                    
                    if isUploading {
                        // Loading State
                        VStack(spacing: 20) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                .scaleEffect(1.5)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 10)
                    } else if let error = errorMessage {
                        // Error State
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.red.opacity(0.7))
                            
                            Text("Upload Failed")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                            
                            Text(error)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                            
                            Button(action: {
                                errorMessage = nil
                            }) {
                                Text("Try Again")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(15)
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 10)
                        }
                        .frame(minHeight: 200)
                    } else {
                        // Upload Options
                        VStack(spacing: 16) {
                            // Select File Button
                            Button(action: {
                                showDocumentPicker = true
                            }) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                        .fill(Color.blue.opacity(0.15))
                                        .frame(width: 56, height: 56)
                                        
                                        Image(systemName: "folder.fill")
                                        .font(.system(size: 26, weight: .semibold))
                                        .foregroundColor(.blue)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Choose File")
                                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                                        
                                        Text("Select from your device")
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundColor(.gray.opacity(0.8))
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.gray.opacity(0.4))
                                }
                                .padding(18)
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 20)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.white,
                                                    Color(red: 0.99, green: 0.99, blue: 0.99)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        
                                        RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.blue.opacity(0.3),
                                                    Color.blue.opacity(0.15)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                    }
                                )
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Cancel Button
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isPresented = false
                            }
                        }) {
                            Text("Cancel")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                        }
                    }
                }
                .padding(.top, 4)
                .padding(.bottom, 34) // Adjusted for Home Indicator
            }
            .padding(.bottom, 20)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white,
                        Color(red: 0.99, green: 0.99, blue: 0.99)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.bottom)
            )
            .clipShape(RoundedCorner(radius: 32, corners: [.topLeft, .topRight]))
            .offset(y: sheetOffset)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .onAppear {
                // Reset states when sheet appears
                isUploading = false
                errorMessage = nil
                selectedFile = nil
                
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    sheetOffset = 0
                }
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                    iconScale = 1.0
                    iconRotation = 0
                }
            }
            .transition(.move(edge: .bottom))
        }
        .zIndex(200)
        .edgesIgnoringSafeArea(.all)
        .fileImporter(
            isPresented: $showDocumentPicker,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    handleDocumentUpload(url: url)
                }
            case .failure(_):
                isPresented = false
            }
        }
    }
    
    func handleDocumentUpload(url: URL) {
        isUploading = true
        errorMessage = nil
        
        // Get file name from URL
        let fileName = url.lastPathComponent
        
        // Validate file type - only PDFs allowed
        let fileExtension = (fileName as NSString).pathExtension.lowercased()
        guard fileExtension == "pdf" else {
            isUploading = false
            errorMessage = "Only PDF files are supported. Please select a PDF file."
            print("Invalid file type: \(fileExtension)")
            return
        }
        
        // Start security-scoped resource access
        guard url.startAccessingSecurityScopedResource() else {
            isUploading = false
            errorMessage = "Failed to access file. Please try again."
            print("Failed to access security-scoped resource")
            return
        }
        
        // Upload document using DocumentsService
        documentsService.uploadDocument(userId: userId, fileURL: url, fileName: fileName, folderId: folderId) { success, error in
            url.stopAccessingSecurityScopedResource()
            
            DispatchQueue.main.async {
                isUploading = false
                if success {
                    toastMessage = "Document '\(fileName)' uploaded successfully"
                    toastType = .success
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                } else {
                    // Show error without closing popup
                    let errorText = error ?? "Unknown error occurred. Please try again."
                    errorMessage = errorText
                    print("Error uploading document: \(errorText)")
                }
            }
        }
    }
}

// MARK: - Upload Image Sheet
struct UploadImageSheet: View {
    @ObservedObject var documentsService: DocumentsService
    let userId: String
    let folderId: String?
    @Binding var isPresented: Bool
    @Binding var toastMessage: String?
    @Binding var toastType: ToastType
    @State private var isUploading = false
    @State private var errorMessage: String?
    @State private var sheetOffset: CGFloat = 800
    @State private var iconScale: CGFloat = 0.5
    @State private var iconRotation: Double = -180
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        ZStack {
            // Blocking overlay to prevent background interactions
            Color.clear
                .contentShape(Rectangle())
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    if !isUploading {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isPresented = false
                        }
                    }
                }
            
            // Modal Content
            VStack(spacing: 0) {
                // Premium Drag Handle
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 5)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                
                VStack(spacing: 24) {
                    // Header (Always visible, changes content based on state)
                    VStack(spacing: 18) {
                        // Premium Animated Icon
                        ZStack {
                            RoundedRectangle(cornerRadius: 35)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.cyan,
                                            Color.cyan.opacity(0.8)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 90, height: 90)
                            
                            Image(systemName: "photo.on.rectangle.fill")
                                .font(.system(size: 38, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .scaleEffect(iconScale)
                        .rotationEffect(.degrees(iconRotation))
                        .padding(.top, 8)
                        
                        VStack(spacing: 8) {
                            Text(isUploading ? "Uploading..." : "Upload Image")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                            
                            Text(isUploading ? "Please wait while we secure your image." : "Select an image from your gallery\nto upload securely.")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
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
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.bottom, 8)
                    
                    if isUploading {
                        // Loading State
                        VStack(spacing: 20) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .cyan))
                                .scaleEffect(1.5)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 10)
                    } else if let error = errorMessage {
                        // Error State
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.red.opacity(0.7))
                            
                            Text("Upload Failed")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                            
                            Text(error)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                            
                            Button(action: {
                                errorMessage = nil
                            }) {
                                Text("Try Again")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.cyan)
                                    .cornerRadius(15)
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 10)
                        }
                        .frame(minHeight: 200)
                    } else {
                        // Upload Options
                        VStack(spacing: 16) {
                            // Select Image Button
                            Button(action: {
                                showImagePicker = true
                            }) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.cyan.opacity(0.15))
                                            .frame(width: 56, height: 56)
                                        
                                        Image(systemName: "photo.on.rectangle")
                                            .font(.system(size: 26, weight: .semibold))
                                            .foregroundColor(.cyan)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Choose Image")
                                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                                            .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                                            
                                        Text("Select from your photo library")
                                            .font(.system(size: 13, weight: .medium, design: .rounded))
                                            .foregroundColor(.gray.opacity(0.8))
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.gray.opacity(0.4))
                                }
                                .padding(18)
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color.white,
                                                        Color(red: 0.99, green: 0.99, blue: 0.99)
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                        
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color.cyan.opacity(0.3),
                                                        Color.cyan.opacity(0.15)
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 2
                                            )
                                    }
                                )
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Cancel Button
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isPresented = false
                            }
                        }) {
                            Text("Cancel")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                        }
                    }
                }
                .padding(.top, 4)
                .padding(.bottom, 4)
            }
            .padding(.bottom, 20)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white,
                        Color(red: 0.99, green: 0.99, blue: 0.99)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.bottom)
            )
            .clipShape(RoundedCorner(radius: 32, corners: [.topLeft, .topRight]))
            .offset(y: sheetOffset)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .onAppear {
                // Reset states when sheet appears
                isUploading = false
                errorMessage = nil
                selectedImage = nil
                
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    sheetOffset = 0
                }
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                    iconScale = 1.0
                    iconRotation = 0
                }
            }
            .transition(.move(edge: .bottom))
        }
        .zIndex(200)
        .edgesIgnoringSafeArea(.all)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage, isPresented: $showImagePicker)
        }
        .onChange(of: selectedImage) { newImage in
            if let image = newImage {
                handleImageUpload(image: image)
            }
        }
    }
    
    func handleImageUpload(image: UIImage) {
        isUploading = true
        errorMessage = nil
        
        // Validate image - UIImagePickerController already ensures it's a valid image
        // But we can double-check that we have valid image data
        // Try JPEG first (smaller file size), then PNG
        guard image.jpegData(compressionQuality: 0.8) != nil || image.pngData() != nil else {
            isUploading = false
            errorMessage = "Invalid image format. Please select a valid image (JPG, JPEG, PNG, or other supported format)."
            print("Failed to convert image to data")
            return
        }
        
        // Generate file name with timestamp - use jpg extension (will be converted to JPEG in upload)
        let fileName = "image_\(Int(Date().timeIntervalSince1970)).jpg"
        
        // Upload image using DocumentsService
        documentsService.uploadImage(userId: userId, image: image, fileName: fileName, folderId: folderId) { success, error in
            DispatchQueue.main.async {
                isUploading = false
                if success {
                    toastMessage = "Image '\(fileName)' uploaded successfully"
                    toastType = .success
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                } else {
                    // Show error without closing popup
                    let errorText = error ?? "Unknown error occurred. Please try again."
                    errorMessage = errorText
                    print("Error uploading image: \(errorText)")
                }
            }
        }
    }
}

// MARK: - Folder Contents View
struct FolderContentsView: View {
    @ObservedObject var documentsService: DocumentsService
    let userId: String
    let folderId: String
    let folderName: String
    let appConfigService: AppConfigService
    let onFolderTap: (DocFolder) -> Void
    let onBack: () -> Void
    let onCreateFolder: () -> Void
    let onUploadDocument: () -> Void
    let onUploadImage: () -> Void
    let onEditFolder: (DocFolder) -> Void
    let onDeleteFolder: (DocFolder) -> Void
    let onEditDocument: (DocumentFile) -> Void
    let onDeleteDocument: (DocumentFile) -> Void
    let onShareDocument: (DocumentFile) -> Void
    let onPreviewDocument: (DocumentFile) -> Void
    
    var body: some View {
        Group {
            if documentsService.currentFolderFolders.isEmpty && documentsService.currentFolderDocuments.isEmpty {
                if documentsService.isLoading {
                    VStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                            .scaleEffect(1.5)
                        Spacer()
                    }
                } else {
                // Empty folder state
                VStack(spacing: 30) {
                    Spacer().frame(height: 100)
                    
                    Image(systemName: "folder.fill")
                        .font(.system(size: 80, weight: .light))
                        .foregroundColor(.gray.opacity(0.3))
                    
                    Text("This folder is empty")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                    
                    Text(folderId == "SHARED_ROOT" ? "No shared documents" : "Upload documents or images to get started")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Spacer()
                }
            }
            } else {
                // Show folders and documents together in list
                List {
                    // Folders section
                    if !documentsService.currentFolderFolders.isEmpty {
                        ForEach(documentsService.currentFolderFolders) { folder in
                            FolderListRow(folder: folder) {
                                onFolderTap(folder)
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                // Delete action
                                Button(role: .destructive) {
                                    onDeleteFolder(folder)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .tint(.red)
                                
                                // Edit action
                                Button {
                                    onEditFolder(folder)
                                } label: {
                                    Image(systemName: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                    
                    // Documents section
                    if !documentsService.currentFolderDocuments.isEmpty {
                        ForEach(documentsService.currentFolderDocuments) { document in
                            DocumentListItem(document: document)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                                .onTapGesture {
                                    onPreviewDocument(document)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    // Delete action
                                    Button(role: .destructive) {
                                        onDeleteDocument(document)
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                    .tint(.red)
                                    
                                    // Edit name action
                                    Button {
                                        onEditDocument(document)
                                    } label: {
                                        Image(systemName: "pencil")
                                    }
                                    .tint(.blue)
                                }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollIndicators(.hidden)
            }
        }
        .onAppear {
            documentsService.fetchDocumentsInFolder(userId: userId, folderId: folderId)
            documentsService.fetchFoldersInFolder(userId: userId, parentFolderId: folderId)
        }
    }
}

// MARK: - Document List Item
struct DocumentListItem: View {
    let document: DocumentFile
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(document.type == "image" ? Color.cyan.opacity(0.1) : Color.blue.opacity(0.1))
                    .frame(width: 50, height: 50)
                Image(systemName: document.type == "image" ? "photo.fill" : "doc.fill")
                    .font(.title2)
                    .foregroundColor(document.type == "image" ? .cyan : .blue)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(document.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                
                HStack(spacing: 6) {
                    if document.isShared {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        
                        Text("Shared by \(document.sharedByName ?? "Unknown")")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else {
                        Text(formatFileSize(document.size))
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        if let createdAt = document.createdAt {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text(formatUploadDate(createdAt))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
    }
    
    func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    func formatUploadDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        // If date is today, show time
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        
        // If date is yesterday
        if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }
        
        // If date is within the last week, show day name
        if let days = calendar.dateComponents([.day], from: date, to: now).day, days < 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE" // Day name
            return formatter.string(from: date)
        }
        
        // If date is within the same year, show month and day
        if calendar.component(.year, from: date) == calendar.component(.year, from: now) {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d" // Jan 15
            return formatter.string(from: date)
        }
        
        // Otherwise, show full date
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy" // Jan 15, 2024
        return formatter.string(from: date)
    }
}

// MARK: - Folder List Row
struct FolderListRow: View {
    let folder: DocFolder
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 15) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 50, height: 50)
                    Image(systemName: folder.icon)
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(folder.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                    
                    Text("\(folder.itemCount) items")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Document Grid Item
struct DocumentGridItem: View {
    let document: DocumentFile
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(document.type == "image" ? Color.cyan.opacity(0.1) : Color.blue.opacity(0.1))
                    .frame(width: 70, height: 70)
                
                Image(systemName: document.type == "image" ? "photo.fill" : "doc.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(document.type == "image" ? .cyan : .blue)
            }
            
            Text(document.name)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(height: 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}



// MARK: - Edit Document Sheet
struct EditDocumentSheet: View {
    @ObservedObject var documentsService: DocumentsService
    let userId: String
    let document: DocumentFile
    let folderId: String?
    @Binding var isPresented: Bool
    @Binding var toastMessage: String?
    @Binding var toastType: ToastType
    @State private var documentName: String = ""
    @State private var sheetOffset: CGFloat = 800
    @State private var iconScale: CGFloat = 0.5
    @State private var iconRotation: Double = -180
    @FocusState private var isFocused: Bool
    
    // Determine if this is an image file
    private var isImageFile: Bool {
        let typeLower = document.type.lowercased()
        let nameLower = document.name.lowercased()
        return typeLower == "image" || 
               nameLower.hasSuffix(".jpg") || 
               nameLower.hasSuffix(".jpeg") || 
               nameLower.hasSuffix(".png") || 
               nameLower.hasSuffix(".heic") ||
               nameLower.hasSuffix(".gif") ||
               nameLower.hasSuffix(".webp")
    }
    
    private var fileTypeText: String {
        isImageFile ? "image" : "file"
    }
    
    var body: some View {
        ZStack {
            // No dimmed background - keep background visible
            
            // Modal Content
            VStack(spacing: 20) {
                // Drag Handle
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 4)
                    .padding(.top, 10)
                
                // Premium Animated Header Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    document.type == "image" ? Color.cyan.opacity(0.15) : Color.blue.opacity(0.15),
                                    document.type == "image" ? Color.cyan.opacity(0.08) : Color.blue.opacity(0.08)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: document.type == "image" ? "photo.fill" : "doc.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(document.type == "image" ? .cyan : .blue)
                }
                .scaleEffect(iconScale)
                .rotationEffect(.degrees(iconRotation))
                .padding(.top, 5)
                
                // Title & Subtitle
                VStack(spacing: 8) {
                    Text("Edit Name")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                    
                    Text("Update your \(fileTypeText) name.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal)
                }
                
                // Input Field
                TextField("\(isImageFile ? "Image" : "File") Name", text: $documentName)
                    .font(.headline)
                    .padding()
                    .background(Color(red: 0.96, green: 0.96, blue: 0.98))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .focused($isFocused)
                    .padding(.horizontal, 25)
                    .submitLabel(.done)
                    .onChange(of: documentName) { newValue in
                        // Only allow alphanumeric, space, hyphen, and underscore
                        var filtered = newValue.filter { char in
                            char.isLetter || char.isNumber || char == " " || char == "-" || char == "_"
                        }
                        // Limit to 50 characters
                        if filtered.count > 50 {
                            filtered = String(filtered.prefix(50))
                        }
                        if documentName != filtered {
                            documentName = filtered
                        }
                    }
                
                // Action Buttons
                VStack(spacing: 15) {
                    Button(action: {
                        print("🔄 EditDocumentSheet: Updating document \(document.id) name from '\(document.name)' to '\(documentName)'")
                        documentsService.updateDocumentName(userId: userId, documentId: document.id, newName: documentName.trimmingCharacters(in: .whitespacesAndNewlines)) { success, error in
                            DispatchQueue.main.async {
                                if success {
                                    print("✅ EditDocumentSheet: Update successful")
                                    toastMessage = "\(document.type == "image" ? "Image" : "Document") renamed to '\(documentName)'"
                                    toastType = .success
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        isPresented = false
                                    }
                                } else {
                                    print("❌ EditDocumentSheet: Update failed - \(error ?? "Unknown error")")
                                    toastMessage = error ?? "Failed to update \(document.type == "image" ? "image" : "document") name"
                                    toastType = .error
                                }
                            }
                        }
                    }) {
                        Text("Save Changes")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(documentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || documentName.trimmingCharacters(in: .whitespacesAndNewlines) == document.name ? Color.gray.opacity(0.5) : (document.type == "image" ? Color.cyan : Color.blue))
                            .cornerRadius(15)
                    }
                    .disabled(documentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || documentName.trimmingCharacters(in: .whitespacesAndNewlines) == document.name)
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isPresented = false
                        }
                    }) {
                        Text("Cancel")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                    }
                }
                .padding(.horizontal, 25)
                .padding(.bottom, 30)
            }
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color.white)
                }
            )
            .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight]))
            .offset(y: sheetOffset)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .edgesIgnoringSafeArea(.bottom)
            .onAppear {
                documentName = document.name
                print("📝 EditDocumentSheet: Opened for document \(document.id) with name '\(document.name)'")
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    sheetOffset = 0
                }
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                    iconScale = 1.0
                    iconRotation = 0
                }
                // Auto focus
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isFocused = true
                }
            }
            .onChange(of: documentName) { newValue in
                print("📝 EditDocumentSheet: documentName changed to '\(newValue)'")
            }
            .transition(.move(edge: .bottom))
        }
        .zIndex(200)
        .edgesIgnoringSafeArea(.all)
    }
}

// MARK: - Document Preview View
struct DocumentPreviewView: View {
    let document: DocumentFile
    @ObservedObject var documentsService: DocumentsService
    @ObservedObject var friendsService: FriendsService
    @ObservedObject var notificationService: NotificationService
    let userId: String
    let folderId: String?
    @Binding var isPresented: Bool
    let onDelete: () -> Void
    let onShare: () -> Void
    @Binding var toastMessage: String?
    @Binding var toastType: ToastType
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var pdfPages: [UIImage] = []
    @State private var currentPageIndex: Int = 0
    @State private var isLoading: Bool = true
    @State private var loadError: String?
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            // Content
            VStack(spacing: 0) {
                // Top Bar
                HStack {
                    Button(action: {
                        withAnimation {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text(document.name)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Action buttons
                    HStack(spacing: 12) {
                        Button(action: onShare) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                        
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding()
                .background(Color.black.opacity(0.5))
                
                // Preview Content
                ZStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    } else if let error = loadError {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 48))
                                .foregroundColor(.white.opacity(0.7))
                            Text(error)
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    } else {
                        if document.type == "image" {
                            // Image Preview with Zoom
                            AsyncImage(url: URL(string: document.url)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .scaleEffect(scale)
                                        .offset(offset)
                                        .gesture(
                                            SimultaneousGesture(
                                                MagnificationGesture()
                                                    .onChanged { value in
                                                        scale = lastScale * value
                                                    }
                                                    .onEnded { _ in
                                                        lastScale = scale
                                                        if scale < 1.0 {
                                                            withAnimation {
                                                                scale = 1.0
                                                                lastScale = 1.0
                                                                offset = .zero
                                                                lastOffset = .zero
                                                            }
                                                        } else if scale > 5.0 {
                                                            withAnimation {
                                                                scale = 5.0
                                                                lastScale = 5.0
                                                            }
                                                        }
                                                    },
                                                DragGesture()
                                                    .onChanged { value in
                                                        offset = CGSize(
                                                            width: lastOffset.width + value.translation.width,
                                                            height: lastOffset.height + value.translation.height
                                                        )
                                                    }
                                                    .onEnded { _ in
                                                        lastOffset = offset
                                                    }
                                            )
                                        )
                                        .onTapGesture(count: 2) {
                                            withAnimation {
                                                if scale > 1.0 {
                                                    scale = 1.0
                                                    lastScale = 1.0
                                                    offset = .zero
                                                    lastOffset = .zero
                                                } else {
                                                    scale = 2.0
                                                    lastScale = 2.0
                                                }
                                            }
                                        }
                                case .failure:
                                    VStack(spacing: 16) {
                                        Image(systemName: "photo")
                                            .font(.system(size: 48))
                                            .foregroundColor(.white.opacity(0.7))
                                        Text("Failed to load image")
                                            .font(.headline)
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else {
                            // PDF Preview with Page Scrolling
                            if !pdfPages.isEmpty {
                                ScrollViewReader { proxy in
                                    ScrollView(.vertical, showsIndicators: true) {
                                        VStack(spacing: 20) {
                                            ForEach(0..<pdfPages.count, id: \.self) { index in
                                                Image(uiImage: pdfPages[index])
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .scaleEffect(scale)
                                                    .gesture(
                                                        SimultaneousGesture(
                                                            MagnificationGesture()
                                                                .onChanged { value in
                                                                    scale = lastScale * value
                                                                }
                                                                .onEnded { _ in
                                                                    lastScale = scale
                                                                    if scale < 1.0 {
                                                                        withAnimation {
                                                                            scale = 1.0
                                                                            lastScale = 1.0
                                                                        }
                                                                    } else if scale > 5.0 {
                                                                        withAnimation {
                                                                            scale = 5.0
                                                                            lastScale = 5.0
                                                                        }
                                                                    }
                                                                },
                                                            DragGesture()
                                                                .onChanged { value in
                                                                    offset = CGSize(
                                                                        width: lastOffset.width + value.translation.width,
                                                                        height: lastOffset.height + value.translation.height
                                                                    )
                                                                }
                                                                .onEnded { _ in
                                                                    lastOffset = offset
                                                                }
                                                        )
                                                    )
                                                    .onTapGesture(count: 2) {
                                                        withAnimation {
                                                            if scale > 1.0 {
                                                                scale = 1.0
                                                                lastScale = 1.0
                                                                offset = .zero
                                                                lastOffset = .zero
                                                            } else {
                                                                scale = 2.0
                                                                lastScale = 2.0
                                                            }
                                                        }
                                                    }
                                                    .padding(.horizontal)
                                                    .id(index)
                                            }
                                        }
                                        .padding(.vertical)
                                    }
                                    .onChange(of: currentPageIndex) { newIndex in
                                        withAnimation {
                                            proxy.scrollTo(newIndex, anchor: .top)
                                        }
                                    }
                                }
                            } else {
                                VStack(spacing: 16) {
                                    Image(systemName: "doc")
                                        .font(.system(size: 48))
                                        .foregroundColor(.white.opacity(0.7))
                                    Text("No pages to display")
                                        .font(.headline)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Bottom Controls (for PDF page indicator)
                if document.type != "image" && !pdfPages.isEmpty {
                    HStack {
                        Button(action: {
                            if currentPageIndex > 0 {
                                withAnimation {
                                    currentPageIndex -= 1
                                }
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(currentPageIndex > 0 ? .white : .white.opacity(0.3))
                                .frame(width: 44, height: 44)
                        }
                        .disabled(currentPageIndex == 0)
                        
                        Spacer()
                        
                        Text("Page \(currentPageIndex + 1) of \(pdfPages.count)")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            if currentPageIndex < pdfPages.count - 1 {
                                withAnimation {
                                    currentPageIndex += 1
                                }
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(currentPageIndex < pdfPages.count - 1 ? .white : .white.opacity(0.3))
                                .frame(width: 44, height: 44)
                        }
                        .disabled(currentPageIndex == pdfPages.count - 1)
                    }
                    .padding()
                    .background(Color.black.opacity(0.5))
                }
            }
        }
        .zIndex(1000)
        .onAppear {
            loadDocument()
        }
    }
    
    private func loadDocument() {
        isLoading = true
        loadError = nil
        
        guard let url = URL(string: document.url) else {
            loadError = "Invalid document URL"
            isLoading = false
            return
        }
        
        if document.type == "image" {
            // Image loading is handled by AsyncImage
            isLoading = false
        } else {
            // Load PDF
            loadPDF(from: url)
        }
    }
    
    private func loadPDF(from url: URL) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data = try Data(contentsOf: url)
                guard let dataProvider = CGDataProvider(data: data as CFData),
                      let pdfDocument = CGPDFDocument(dataProvider) else {
                    DispatchQueue.main.async {
                        loadError = "Failed to parse PDF"
                        isLoading = false
                    }
                    return
                }
                
                var pages: [UIImage] = []
                let pageCount = pdfDocument.numberOfPages
                
                for pageNum in 1...pageCount {
                    guard let page = pdfDocument.page(at: pageNum) else { continue }
                    
                    let pageRect = page.getBoxRect(.mediaBox)
                    let renderer = UIGraphicsImageRenderer(size: pageRect.size)
                    
                    let image = renderer.image { ctx in
                        ctx.cgContext.translateBy(x: 0, y: pageRect.size.height)
                        ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
                        ctx.cgContext.drawPDFPage(page)
                    }
                    
                    pages.append(image)
                }
                
                DispatchQueue.main.async {
                    pdfPages = pages
                    isLoading = false
                    if pages.isEmpty {
                        loadError = "PDF has no pages"
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    loadError = "Failed to load PDF: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}
