import SwiftUI

struct SearchResultsOverlay: View {
    @ObservedObject var documentsService: DocumentsService
    @Binding var searchText: String
    var onSelect: (DocumentFile) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            if documentsService.isSearching {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Searching...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .frame(maxWidth: .infinity)
            } else if documentsService.searchResults.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 30))
                        .foregroundColor(.gray.opacity(0.3))
                    Text("No Matching Documents")
                        .font(.footnote)
                        .foregroundColor(.gray.opacity(0.8))
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(documentsService.searchResults) { doc in
                            Button(action: {
                                onSelect(doc)
                            }) {
                                HStack(spacing: 12) {
                                    // Icon
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(doc.type == "image" ? Color.purple.opacity(0.1) : Color.blue.opacity(0.1))
                                            .frame(width: 36, height: 36)
                                        
                                        Image(systemName: doc.type == "image" ? "photo" : "doc.text.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(doc.type == "image" ? .purple : .blue)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(doc.name)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                        
                                        HStack(spacing: 4) {
                                            Text(doc.type.capitalized)
                                            Text("•")
                                            Text(formatDate(doc.createdAt))
                                        }
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.gray.opacity(0.5))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider()
                                .padding(.leading, 64)
                        }
                    }
                }
                .frame(maxHeight: 300) // Max height for dropdown
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }
    
    // Helper to format date
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}
