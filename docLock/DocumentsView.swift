import SwiftUI

struct DocFolder: Identifiable {
    let id = UUID()
    let name: String
    let itemCount: Int
    let icon: String
}

struct DocumentsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText: String = ""
    @State private var showFabMenu = false
    
    // Sample Data
    @State private var folders: [DocFolder] = [
        DocFolder(name: "Health", itemCount: 0, icon: "folder"),
        DocFolder(name: "Medical", itemCount: 1, icon: "folder"),
        DocFolder(name: "Government ID", itemCount: 0, icon: "folder")
    ]
    
    // Breadcrumb state
    @State private var currentPath: [String] = ["HOME"]
    
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
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(10)
                            .background(Color.white)
                            .cornerRadius(12)
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
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search docs...", text: $searchText)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(15)
                .padding(.horizontal)
                .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                
                // Breadcrumbs
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
                
                // Content
                ScrollView {
                    VStack(spacing: 15) {
                        if currentPath.last == "Health" { // Example Empty State
                             EmptyStateView()
                        } else {
                            ForEach(folders) { folder in
                                Button(action: {
                                    withAnimation {
                                        currentPath.append(folder.name)
                                    }
                                }) {
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
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(20)
                                    .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .blur(radius: showFabMenu ? 2 : 0) // Blur background when FAB menu open
            
            // FAB Overlay
            if showFabMenu {
                Color.white.opacity(0.8)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                         withAnimation {
                             showFabMenu = false
                         }
                    }
                
                VStack(spacing: 20) {
                     Spacer()
                    
                    FabMenuButton(title: "Create Folder", icon: "folder.badge.plus", color: Color(red: 0.3, green: 0.35, blue: 0.4))
                    FabMenuButton(title: "Upload Img", icon: "photo", color: .blue)
                    FabMenuButton(title: "Upload Doc", icon: "doc.text", color: .blue)
                    
                    Spacer().frame(height: 80) // Space for close button
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // FAB Button
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
        .navigationBarHidden(true)
        .swipeToDismiss()
    }
}

// MARK: - Subviews
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 50)
            
            ZStack {
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.blue)
                    .frame(width: 100, height: 100)
                Image(systemName: "doc.text")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            .shadow(color: Color.blue.opacity(0.3), radius: 15, y: 10)
            
            Text("No Documents Found")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
            
            Text("Start by uploading your first document or creating a\nfolder to organize your files.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal, 40)
            
            VStack(spacing: 15) {
                FabMenuButton(title: "Create Folder", icon: "folder", color: Color(red: 0.3, green: 0.35, blue: 0.4))
                FabMenuButton(title: "Upload Img", icon: "photo", color: .blue)
                FabMenuButton(title: "Upload Doc", icon: "doc.text", color: .blue)
            }
            .padding(.top, 20)
            
            Spacer()
        }
    }
}

struct FabMenuButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        Button(action: {}) {
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
}
