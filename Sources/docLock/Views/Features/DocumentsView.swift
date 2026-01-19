import SwiftUI
import UniformTypeIdentifiers

struct DocFolder: Identifiable {
    let id: String
    let name: String
    let itemCount: Int
    let icon: String
}

struct DocumentFile: Identifiable {
    let id: String
    let name: String
    let type: String // "document" or "image"
    let url: String
    let size: Int
    let createdAt: Date?
}

struct DocumentsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var documentsService: DocumentsService
    let userId: String
    
    @State private var searchText: String = ""
    @State private var showFabMenu = false
    
    // Breadcrumb state
    @State private var currentPath: [String] = ["HOME"]
    @State private var selectedFolderId: String? = nil
    @State private var selectedFolderName: String? = nil
    @State private var showCreateFolderSheet = false
    @State private var showUploadDocumentSheet = false
    @State private var showUploadImageSheet = false
    
    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.97, blue: 0.99) // Very light blue/gray background
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        if currentPath.count > 1 {
                             currentPath.removeLast()
                        } else {
                            presentationMode.wrappedValue.dismiss()
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
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    Spacer()
                    Text("My Documents")
                        .font(.title3)
                        .fontWeight(.bold)
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
                
                // Breadcrumbs (Only show if documents exist)
                if !documentsService.folders.isEmpty {
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
                                .onTapGesture {
                                    // Navigate back logic could go here
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                    }
                }
                
                // Content
                if documentsService.folders.isEmpty {
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
                        onBack: {
                            selectedFolderId = nil
                            selectedFolderName = nil
                            documentsService.stopListeningToFolder()
                            withAnimation {
                                if currentPath.count > 1 {
                                    currentPath.removeLast()
                                }
                            }
                        }
                    )
                } else {
                    // Show folders in 2D grid
                    ScrollView {
                        let columns = [
                            GridItem(.flexible(), spacing: 15),
                            GridItem(.flexible(), spacing: 15)
                        ]
                        
                        LazyVGrid(columns: columns, spacing: 15) {
                            ForEach(documentsService.folders) { folder in
                                Button(action: {
                                    selectedFolderId = folder.id
                                    selectedFolderName = folder.name
                                    withAnimation {
                                        currentPath.append(folder.name)
                                    }
                                    documentsService.fetchDocumentsInFolder(userId: userId, folderId: folder.id)
                                }) {
                                    VStack(spacing: 12) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.blue.opacity(0.1))
                                                .frame(width: 70, height: 70)
                                            Image(systemName: folder.icon)
                                                .font(.system(size: 32, weight: .medium))
                                                .foregroundColor(.blue)
                                        }
                                        
                                        VStack(spacing: 4) {
                                            Text(folder.name)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                                                .lineLimit(1)
                                            
                                            Text("\(folder.itemCount) items")
                                                .font(.system(size: 11))
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                                    .background(Color.white)
                                    .cornerRadius(18)
                                    .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .blur(radius: (showFabMenu || showCreateFolderSheet || showUploadDocumentSheet || showUploadImageSheet) ? 2 : 0) // Blur background when modal is open
            
            // Create Folder Sheet
            if showCreateFolderSheet {
                CreateFolderSheet(
                    documentsService: documentsService,
                    userId: userId,
                    isPresented: $showCreateFolderSheet
                )
            }
            
            // Upload Document Sheet
            if showUploadDocumentSheet {
                UploadDocumentSheet(
                    documentsService: documentsService,
                    userId: userId,
                    isPresented: $showUploadDocumentSheet
                )
            }
            
            // Upload Image Sheet
            if showUploadImageSheet {
                UploadImageSheet(
                    documentsService: documentsService,
                    userId: userId,
                    isPresented: $showUploadImageSheet
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
                    
                    Button(action: {
                        withAnimation {
                            showFabMenu = false
                            showCreateFolderSheet = true
                        }
                    }) {
                        FabMenuRow(title: "Create Folder", icon: "folder.badge.plus", color: Color(red: 0.3, green: 0.35, blue: 0.4))
                    }
                    
                    Button(action: {
                        withAnimation {
                            showFabMenu = false
                            showUploadImageSheet = true
                        }
                    }) {
                        FabMenuRow(title: "Upload Img", icon: "photo", color: .cyan)
                    }
                    
                    Button(action: {
                        withAnimation {
                            showFabMenu = false
                            showUploadDocumentSheet = true
                        }
                    }) {
                        FabMenuRow(title: "Upload Doc", icon: "doc.text", color: .blue)
                    }
                    
                    Spacer().frame(height: 80) // Space for close button
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // FAB Button (Only show if documents exist)
            if !documentsService.folders.isEmpty {
                VStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.spring()) {
                            showFabMenu.toggle()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(showFabMenu ? Color.blue.opacity(0.8) : Color.blue) // Darker when open? Or keep same
                                .frame(width: 60, height: 60)
                                .shadow(color: Color.blue.opacity(0.4), radius: 10, x: 0, y: 5)
                                
                            Image(systemName: "plus")
                                .font(.system(size: 30, weight: .medium))
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(showFabMenu ? 135 : 0))
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarHidden(true)
        .swipeToDismiss()
        .onAppear {
            documentsService.retry(userId: userId)
        }
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
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.headline)
            Text(title)
                .fontWeight(.semibold)
        }
        .foregroundColor(.white)
        .frame(width: 200, height: 50)
        .background(color)
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

struct CreateFolderSheet: View {
    @ObservedObject var documentsService: DocumentsService
    let userId: String
    @Binding var isPresented: Bool
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
                    
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.blue)
                }
                .scaleEffect(iconScale)
                .rotationEffect(.degrees(iconRotation))
                .padding(.top, 5)
                
                // Title & Subtitle
                VStack(spacing: 8) {
                    Text("New Folder")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                    
                    Text("Organize your documents with ease.\nGive your new folder a name.")
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
                
                // Action Buttons
                VStack(spacing: 15) {
                    Button(action: {
                        // Create folder in background (no loader)
                        documentsService.createFolder(userId: userId, folderName: folderName) { success, error in
                            DispatchQueue.main.async {
                                if success {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        isPresented = false
                                    }
                                } else {
                                    // Optionally show error, but close anyway
                                    print("Error creating folder: \(error ?? "Unknown error")")
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        isPresented = false
                                    }
                                }
                            }
                        }
                    }) {
                        Text("Create Folder")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(folderName.isEmpty ? Color.gray.opacity(0.5) : Color.blue)
                            .cornerRadius(15)
                    }
                    .disabled(folderName.isEmpty)
                    
                    Button(action: {
                        withAnimation { isPresented = false }
                    }) {
                        Text("Cancel")
                            .font(.headline)
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
    @Binding var isPresented: Bool
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
                // Premium Drag Handle
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 5)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                
                VStack(spacing: 24) {
                    // Premium Animated Header
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
                            Text("Upload Document")
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
                            
                            Text("Select a file to securely upload\nto your documents.")
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
                                .padding(.top, 40)
                            
                            Text("Uploading Document...")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.gray.opacity(0.8))
                        }
                        .frame(minHeight: 200)
                        .padding(.bottom, 40)
                    } else if let error = errorMessage {
                        // Error State
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.red.opacity(0.7))
                                .padding(.top, 40)
                            
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
                        .padding(.bottom, 40)
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
                        .padding(.bottom, 30)
                        
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
                        .padding(.bottom, 30)
                    }
                }
                .padding(.top, 4)
            }
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 32)
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
                }
            )
            .clipShape(RoundedCorner(radius: 32, corners: [.topLeft, .topRight]))
            .offset(y: sheetOffset)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .edgesIgnoringSafeArea(.bottom)
            .onAppear {
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
            allowedContentTypes: [.item],
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
        
        // Start security-scoped resource access
        guard url.startAccessingSecurityScopedResource() else {
            isUploading = false
            errorMessage = "Failed to access file. Please try again."
            print("Failed to access security-scoped resource")
            return
        }
        
        // Upload document using DocumentsService
        documentsService.uploadDocument(userId: userId, fileURL: url, fileName: fileName) { success, error in
            url.stopAccessingSecurityScopedResource()
            
            DispatchQueue.main.async {
                isUploading = false
                if success {
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
    @Binding var isPresented: Bool
    @State private var isUploading = false
    @State private var errorMessage: String?
    @State private var sheetOffset: CGFloat = 800
    @State private var iconScale: CGFloat = 0.5
    @State private var iconRotation: Double = -180
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    
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
                // Premium Drag Handle
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 5)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                
                VStack(spacing: 24) {
                    // Premium Animated Header
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
                            
                            Image(systemName: "photo.fill")
                                .font(.system(size: 38, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .scaleEffect(iconScale)
                        .rotationEffect(.degrees(iconRotation))
                        .padding(.top, 8)
                        
                        VStack(spacing: 8) {
                            Text("Upload Image")
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
                            
                            Text("Select an image from your gallery\nto upload securely.")
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
                                .padding(.top, 40)
                            
                            Text("Uploading Image...")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.gray.opacity(0.8))
                        }
                        .frame(minHeight: 200)
                        .padding(.bottom, 40)
                    } else if let error = errorMessage {
                        // Error State
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.red.opacity(0.7))
                                .padding(.top, 40)
                            
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
                        .padding(.bottom, 40)
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
                        .padding(.bottom, 30)
                        
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
                        .padding(.bottom, 30)
                    }
                }
                .padding(.top, 4)
            }
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 32)
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
                }
            )
            .clipShape(RoundedCorner(radius: 32, corners: [.topLeft, .topRight]))
            .offset(y: sheetOffset)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .edgesIgnoringSafeArea(.bottom)
            .onAppear {
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
        
        // Generate file name with timestamp
        let fileName = "image_\(Int(Date().timeIntervalSince1970)).jpg"
        
        // Upload image using DocumentsService
        documentsService.uploadImage(userId: userId, image: image, fileName: fileName) { success, error in
            DispatchQueue.main.async {
                isUploading = false
                if success {
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
    let onBack: () -> Void
    
    var body: some View {
        Group {
            if documentsService.currentFolderDocuments.isEmpty {
                // Empty folder state
                VStack(spacing: 30) {
                    Spacer().frame(height: 100)
                    
                    Image(systemName: "folder.fill")
                        .font(.system(size: 80, weight: .light))
                        .foregroundColor(.gray.opacity(0.3))
                    
                    Text("This folder is empty")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                    
                    Text("Upload documents or images to get started")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Spacer()
                }
            } else {
                // Documents grid
                ScrollView {
                    let columns = [
                        GridItem(.flexible(), spacing: 15),
                        GridItem(.flexible(), spacing: 15)
                    ]
                    
                    LazyVGrid(columns: columns, spacing: 15) {
                        ForEach(documentsService.currentFolderDocuments) { document in
                            DocumentGridItem(document: document)
                        }
                    }
                    .padding()
                }
            }
        }
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
                .font(.system(size: 12, weight: .medium))
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
