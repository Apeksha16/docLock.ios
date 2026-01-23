import SwiftUI

struct DocumentSelectionSheet: View {
    let documents: [DocumentFile]
    let onShare: (DocumentFile) -> Void
    @Binding var isPresented: Bool
    
    @State private var searchText = ""
    @State private var selectedDocId: String? = nil
    @State private var sheetOffset: CGFloat = 600
    
    var filteredDocuments: [DocumentFile] {
        if searchText.isEmpty {
            return documents
        }
        return documents.filter { doc in
            doc.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var imageDocuments: [DocumentFile] {
        filteredDocuments.filter { $0.type == "image" }
    }
    
    var pdfDocuments: [DocumentFile] {
        filteredDocuments.filter { $0.type == "document" }
    }
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        sheetOffset = 600
                        isPresented = false
                    }
                }
            
            // Bottom Sheet
            VStack {
                Spacer()
                VStack(spacing: 0) {
                    // Drag Handle
                    Capsule()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 4)
                        .padding(.top, 10)
                        .padding(.bottom, 20)
                    
                    // Header
                    Text("Share Document")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                        .padding(.bottom, 20)
                    
                    if documents.count > 3 {
                        TextField("Search documents...", text: $searchText)
                            .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .padding(.horizontal)
                            .padding(.bottom, 10)
                    }
                    
                    if documents.isEmpty {
                        VStack(spacing: 15) {
                            Image(systemName: "doc.slash")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("No documents available to share.")
                                .foregroundColor(.gray)
                        }
                        .frame(height: 150)
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                if !imageDocuments.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Images")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.gray)
                                            .padding(.horizontal)
                                        
                                        ForEach(imageDocuments) { doc in
                                            DocumentSelectionRow(
                                                document: doc,
                                                isSelected: selectedDocId == doc.id,
                                                onTap: {
                                                    selectedDocId = doc.id
                                                }
                                            )
                                        }
                                    }
                                }
                                
                                if !pdfDocuments.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Documents")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.gray)
                                            .padding(.horizontal)
                                        
                                        ForEach(pdfDocuments) { doc in
                                            DocumentSelectionRow(
                                                document: doc,
                                                isSelected: selectedDocId == doc.id,
                                                onTap: {
                                                    selectedDocId = doc.id
                                                }
                                            )
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(maxHeight: 350)
                    }
                    
                    Spacer().frame(height: 20)
                    
                    Button(action: {
                        if let docId = selectedDocId, let doc = documents.first(where: { $0.id == docId }) {
                            onShare(doc)
                            withAnimation { isPresented = false }
                        }
                    }) {
                        Text("Share Document")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedDocId == nil ? Color.gray : Color.blue)
                            .cornerRadius(15)
                    }
                    .disabled(selectedDocId == nil)
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
                .background(
                    ZStack {
                        Color(red: 0.98, green: 0.98, blue: 0.96)
                        
                        // Decorative Pops
                        GeometryReader { proxy in
                            Circle()
                                .fill(Color.cyan.opacity(0.05))
                                .frame(width: 150, height: 150)
                                .position(x: 50, y: 100)
                                .blur(radius: 20)
                            
                            Circle()
                                .fill(Color.blue.opacity(0.05))
                                .frame(width: 200, height: 200)
                                .position(x: proxy.size.width - 20, y: 50)
                                .blur(radius: 30)
                        }
                    }
                    .cornerRadius(30, corners: [.topLeft, .topRight])
                    .edgesIgnoringSafeArea(.bottom)
                )
                .offset(y: sheetOffset)
                .transition(.move(edge: .bottom))
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        sheetOffset = 0
                    }
                }
            }
        }
        .zIndex(2000)
        .ignoresSafeArea(edges: .bottom)
    }
}

struct DocumentSelectionRow: View {
    let document: DocumentFile
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 15) {
                // Document Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(document.type == "image" ? Color.cyan.opacity(0.1) : Color.blue.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: document.type == "image" ? "photo.fill" : "doc.fill")
                        .font(.system(size: 20))
                        .foregroundColor(document.type == "image" ? .cyan : .blue)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(document.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                        .lineLimit(1)
                    
                    Text(formatFileSize(Int64(document.size)))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 22))
                } else {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        .frame(width: 22, height: 22)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.05) : Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
