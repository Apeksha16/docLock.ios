import SwiftUI

struct ProfileView: View {
    @Binding var isAuthenticated: Bool
    @Binding var showLogoutModal: Bool
    @Binding var showDeleteModal: Bool
    @Binding var showEditNameSheet: Bool // Changed to binding
    @ObservedObject var authService: AuthService
    @State private var showSecuritySheet = false
    @State private var showAboutSheet = false
    // @State private var showEditNameSheet = false // Removed local state
    @State private var copyToastMessage: String? // For copy feedback

    @State private var showImagePicker = false
    @State private var isUploadingProfileImage = false
    @State private var inputImage: UIImage?
    @State private var profileImageTrigger = UUID() // Force refresh
    @State private var hasAppeared = false
    @State private var headerOffset: CGFloat = -50
    @State private var profileCardScale: CGFloat = 0.8
    @State private var copyButtonScale: CGFloat = 0.8
    @State private var settingsOpacity: Double = 0
    
    // Computed properties for content
    var storageUsedMB: Double {
        let bytes = Double(authService.user?.storageUsed ?? 0)
        return bytes / (1024 * 1024)
    }
    
    var storageLimitMB: Double {
        return Double(authService.appConfigService.maxStorageLimit)
    }
    
    var storageProgress: Double {
        return min(max(storageUsedMB / storageLimitMB, 0), 1)
    }
    
    var body: some View {
        ZStack {
            // Premium Animated Background Theme
            ZStack {
                // Base Background with gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.98, green: 0.98, blue: 0.98),
                        Color(red: 0.97, green: 0.98, blue: 0.98)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
                
                // Animated Ambient Gradients
                GeometryReader { geometry in
                    // Top Right - Animated Teal Glow
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.28, green: 0.65, blue: 0.66).opacity(hasAppeared ? 0.15 : 0.05),
                                    Color(red: 0.28, green: 0.65, blue: 0.66).opacity(hasAppeared ? 0.08 : 0.03),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 10,
                                endRadius: hasAppeared ? 180 : 150
                            )
                        )
                        .frame(width: 400, height: 400)
                        .position(x: geometry.size.width * 0.9, y: hasAppeared ? -50 : -100)
                        .blur(radius: 50)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: hasAppeared)
                    
                    // Bottom - Subtle Animated Depth
                    Ellipse()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.gray.opacity(hasAppeared ? 0.04 : 0.01),
                                    Color.clear
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: geometry.size.width * 1.3, height: 350)
                        .position(x: geometry.size.width / 2, y: geometry.size.height * 1.1)
                        .blur(radius: 70)
                        .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: hasAppeared)
                }
            }
            
            VStack(spacing: 0) {
                // Premium Animated Header
                ZStack {
                    Text("My Profile")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.1, green: 0.1, blue: 0.25),
                                    Color(red: 0.15, green: 0.15, blue: 0.3)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(maxWidth: .infinity, alignment: .center)
                        .offset(y: hasAppeared ? 0 : headerOffset)
                        .opacity(hasAppeared ? 1 : 0)
                    
                    HStack {
                        Spacer()
                        // Copy User ID Button
                        Button(action: {
                            if let userId = authService.user?.id ?? authService.user?.mobile {
                                UIPasteboard.general.string = userId
                                withAnimation {
                                    copyToastMessage = "User ID copied!"
                                }
                            }
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                                    .frame(width: 56, height: 56)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color(red: 0.28, green: 0.65, blue: 0.66).opacity(0.3), lineWidth: 1)
                                    )
                                
                                Image(systemName: "doc.on.doc.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(Color(red: 0.28, green: 0.65, blue: 0.66))
                            }
                        }
                        .scaleEffect(copyButtonScale)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 25) {
                        
                        // Premium Animated Profile Card
                        ZStack(alignment: .top) {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.28, green: 0.65, blue: 0.66),
                                        Color(red: 0.21, green: 0.52, blue: 0.53)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(height: 220) // Increased height for more content
                                .padding(.top, 60)
                                .overlay(
                                    // Background Pattern
                                    GeometryReader { geo in
                                        ZStack {
                                            Circle()
                                                .stroke(Color.white.opacity(0.1), lineWidth: 2)
                                                .frame(width: 150, height: 150)
                                                .offset(x: -80, y: -80)
                                            Circle()
                                                .stroke(Color.white.opacity(0.05), lineWidth: 20)
                                                .frame(width: 250, height: 250)
                                                .offset(x: 100, y: 50)
                                            
                                            // Security Badge
                                            VStack {
                                                HStack {
                                                    Spacer()
                                                    HStack(spacing: 4) {
                                                        Image(systemName: "checkmark.shield.fill")
                                                            .font(.caption2)
                                                        Text("SECURED")
                                                            .font(.caption2)
                                                            .fontWeight(.bold)
                                                    }
                                                    .foregroundColor(.white.opacity(0.8))
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 4)
                                                    .background(Color.white.opacity(0.15))
                                                    .cornerRadius(10)
                                                    .padding(15)
                                                }
                                                Spacer()
                                            }
                                        }
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                )
                            
                            VStack(spacing: 15) {
                                // New Interesting Avatar
                                ZStack(alignment: .bottomTrailing) {
                                    // Avatar Circle
                                    ZStack {
                                        Button(action: { showImagePicker = true }) {
                                            ZStack {
                                                Circle()
                                                    .fill(LinearGradient(
                                                        gradient: Gradient(colors: [Color.white, Color(red: 0.9, green: 0.95, blue: 1.0)]),
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ))
                                                    .frame(width: 120, height: 120)
                                                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                                                
                                                if let inputImage = inputImage {
                                                    // Show Local Preview Immediately
                                                    Image(uiImage: inputImage)
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(width: 120, height: 120)
                                                        .clipShape(Circle())
                                                } else if let imageUrl = authService.user?.profileImageUrl, !imageUrl.isEmpty {
                                                    AsyncImage(url: URL(string: imageUrl)) { phase in
                                                        if let image = phase.image {
                                                            image
                                                                .resizable()
                                                                .aspectRatio(contentMode: .fill)
                                                                .frame(width: 120, height: 120)
                                                                .clipShape(Circle())
                                                        } else if phase.error != nil {
                                                            VStack(spacing: 5) {
                                                                Image(systemName: "camera.fill")
                                                                    .font(.system(size: 30))
                                                                    .foregroundColor(Color(red: 0.28, green: 0.65, blue: 0.66))
                                                                Text("Upload")
                                                                    .font(.caption2)
                                                                    .fontWeight(.bold)
                                                                    .foregroundColor(Color(red: 0.28, green: 0.65, blue: 0.66))
                                                            }
                                                        } else {
                                                            ProgressView()
                                                        }
                                                    }
                                                    .id(profileImageTrigger) // Force refresh
                                                } else {
                                                    // Interesting Placeholder
                                                    VStack(spacing: 5) {
                                                        Image(systemName: "camera.fill")
                                                            .font(.system(size: 30))
                                                            .foregroundColor(Color(red: 0.28, green: 0.65, blue: 0.66))
                                                        Text("Upload")
                                                            .font(.caption2)
                                                            .fontWeight(.bold)
                                                            .foregroundColor(Color(red: 0.28, green: 0.65, blue: 0.66))
                                                    }
                                                }
                                                
                                                // Loading Overlay
                                                if isUploadingProfileImage {
                                                    ZStack {
                                                        Color.black.opacity(0.4)
                                                            .clipShape(Circle())
                                                        ProgressView()
                                                            .tint(.white)
                                                            .scaleEffect(1.2)
                                                    }
                                                    .frame(width: 120, height: 120)
                                                }
                                                
                                                Circle()
                                                    .stroke(Color.white.opacity(0.5), lineWidth: 4)
                                                    .frame(width: 120, height: 120)
                                            }
                                        }
                                    }
                                    
                                    // Edit Icon Button
                                    Button(action: { showEditNameSheet = true }) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 38, height: 38)
                                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                                            
                                            Image(systemName: "wand.and.stars") // Interesting icon
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(Color(red: 0.28, green: 0.65, blue: 0.66))
                                        }
                                    }
                                    .offset(x: 5, y: -5)
                                }
                                
                                // User Info
                                VStack(spacing: 5) {
                                    Text(authService.user?.name ?? "DocLock User")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                                    
                                    Text(authService.user?.mobile ?? "No Mobile")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.9))
                                    
                                    // Storage stats
                                    VStack(spacing: 4) {
                                        HStack {
                                            Text("\(Int(storageUsedMB)) MB used")
                                                .font(.caption2)
                                                .fontWeight(.medium)
                                            Spacer()
                                            Text("\(Int(storageLimitMB)) MB limit")
                                                .font(.caption2)
                                                .fontWeight(.medium)
                                        }
                                        .foregroundColor(.white.opacity(0.8))
                                        
                                        // Progress Bar
                                        GeometryReader { barGeo in
                                            ZStack(alignment: .leading) {
                                                Capsule()
                                                    .fill(Color.black.opacity(0.2))
                                                    .frame(height: 6)
                                                
                                                Capsule()
                                                    .fill(Color.white)
                                                    .frame(width: barGeo.size.width * storageProgress, height: 6)
                                            }
                                        }
                                        .frame(height: 6)
                                    }
                                    .padding(.top, 10)
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                        .scaleEffect(profileCardScale)
                        .opacity(hasAppeared ? 1 : 0)
                        .offset(y: hasAppeared ? 0 : 30)
                        .padding(.horizontal)
                        
                        // Settings Section
                        HStack {
                            Text("SETTINGS")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                        .padding(.horizontal, 25)
                        
                        VStack(spacing: 15) {
                            Button(action: { showSecuritySheet = true }) {
                                AnimatedSettingRow(
                                    icon: "lock",
                                    iconColor: .blue,
                                    title: "Security",
                                    subtitle: "Change MPIN & Biometrics",
                                    index: 0,
                                    hasAppeared: hasAppeared
                                )
                            }
                            
                            Button(action: { showAboutSheet = true }) {
                                AnimatedSettingRow(
                                    icon: "info.circle",
                                    iconColor: .orange,
                                    title: "About DocLock",
                                    subtitle: "Why we are safe & secure",
                                    index: 1,
                                    hasAppeared: hasAppeared
                                )
                            }
                            
                            Button(action: { withAnimation { showLogoutModal = true } }) {
                                AnimatedSettingRow(
                                    icon: "rectangle.portrait.and.arrow.right",
                                    iconColor: .purple,
                                    title: "Logout",
                                    subtitle: "Sign out of this device",
                                    index: 2,
                                    hasAppeared: hasAppeared
                                )
                            }
                            
                            Button(action: { withAnimation { showDeleteModal = true } }) {
                                AnimatedSettingRow(
                                    icon: "trash",
                                    iconColor: .red,
                                    title: "Delete Account",
                                    subtitle: "Permanently remove your account",
                                    index: 3,
                                    hasAppeared: hasAppeared
                                )
                            }
                        }
                        .padding(.horizontal)
                        .opacity(settingsOpacity)
                        
                        Spacer().frame(height: 100)
                    }
                }
            }
        }
        .onAppear {
            // Trigger entrance animations
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                hasAppeared = true
                headerOffset = 0
                copyButtonScale = 1.0
            }
            
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.2)) {
                profileCardScale = 1.0
            }
            
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.4)) {
                settingsOpacity = 1.0
            }
        }
        .sheet(isPresented: $showAboutSheet) {
            AboutView()
        }
        .sheet(isPresented: $showSecuritySheet) {
            CreatePINView(isPresented: $showSecuritySheet, authService: authService)
        }
        // Toast for Copy Feedback
        .toast(message: $copyToastMessage, type: .success)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $inputImage, isPresented: $showImagePicker)
        }
        .onChange(of: inputImage) { newImage in
            guard let image = newImage else { return }
            isUploadingProfileImage = true
            authService.uploadProfileImage(image: image) { success, url in
                isUploadingProfileImage = false
                if success {
                    // Success - inputImage stays as preview
                    profileImageTrigger = UUID()
                    if let userId = authService.user?.mobile {
                        authService.verifyMobile(mobile: userId) { _, _ in }
                    }
                    copyToastMessage = "Profile updated! ✨"
                } else {
                    // Failed
                    copyToastMessage = "Upload failed 😢"
                    // Optionally reset inputImage if you want to undo the preview
                }
            }
        }
    }
}

struct SettingRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 50, height: 50)
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.black)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

// Premium Animated Setting Row
struct AnimatedSettingRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let index: Int
    let hasAppeared: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 50, height: 50)
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.black)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
        .opacity(hasAppeared ? 1 : 0)
        .offset(x: hasAppeared ? 0 : -30)
        .animation(
            .spring(response: 0.6, dampingFraction: 0.75)
            .delay(Double(index) * 0.08),
            value: hasAppeared
        )
    }
}

struct EditNameView: View {
    @ObservedObject var authService: AuthService
    @Binding var isPresented: Bool
    @State private var newName: String = ""
    @State private var isSaving = false
    @State private var sheetOffset: CGFloat = 800
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
                
                // Header Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(red: 0.28, green: 0.65, blue: 0.66).opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "pencil.line")
                        .font(.system(size: 28))
                        .foregroundColor(Color(red: 0.28, green: 0.65, blue: 0.66))
                }
                .padding(.top, 5)
                
                // Title & Subtitle
                VStack(spacing: 8) {
                    Text("Update Name")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                    
                    Text("Time for a rebrand? Pick a name that\nmatches your vibe! ✨")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal)
                }
                
                // Input Field
                TextField("Enter your full name", text: $newName)
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
                    .onSubmit {
                        if !newName.isEmpty {
                            // Trigger save
                        }
                    }
                
                // Action Buttons
                VStack(spacing: 15) {
                    Button(action: {
                        isSaving = true
                        authService.updateName(name: newName) { success, _ in
                            isSaving = false
                            if success {
                                withAnimation { isPresented = false }
                            }
                        }
                    }) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.trailing, 5)
                            }
                            Text(isSaving ? "Saving..." : "Save Changes")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(newName.isEmpty || isSaving ? Color.gray.opacity(0.5) : Color(red: 0.28, green: 0.65, blue: 0.66))
                        .cornerRadius(15)
                    }
                    .disabled(newName.isEmpty || isSaving)
                    
                    Button(action: {
                        withAnimation { isPresented = false }
                    }) {
                        Text("Wait, I changed my mind")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                    }
                }
                .padding(.horizontal, 25)
                .padding(.bottom, 20)
            }
            .background(
                Color.white
                    .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight]))
                    .edgesIgnoringSafeArea(.bottom)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 10, y: -5)
            .offset(y: sheetOffset)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .onAppear {
                newName = authService.user?.name ?? ""
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    sheetOffset = 0
                }
            }
        }
        .zIndex(200)
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var isPresented: Bool
    var allowsEditing: Bool = true // Default to true for backward compatibility

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = allowsEditing // Use the property
        // Only allow image types (JPG, JPEG, PNG, and all iOS supported image types)
        picker.mediaTypes = ["public.image"]
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            parent.isPresented = false
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}
