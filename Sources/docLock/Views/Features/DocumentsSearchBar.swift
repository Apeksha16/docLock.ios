
import SwiftUI

struct DocumentsSearchBar: View {
    @Binding var searchText: String
    @ObservedObject var documentsService: DocumentsService
    @Binding var documentToPreview: DocumentFile?
    @Binding var showDocumentPreview: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(searchText.isEmpty ? .gray : .blue)
                .font(.system(size: 18, weight: .semibold))
            
            TextField("Search your documents...", text: $searchText)
                .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                .tint(.blue)
            
            if !searchText.isEmpty {
                Button(action: {
                    withAnimation(.spring()) {
                        searchText = ""
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray.opacity(0.8))
                        .font(.system(size: 18))
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            ZStack {
                Color.white
                RoundedRectangle(cornerRadius: 18)
                    .stroke(searchText.isEmpty ? Color.clear : Color.blue.opacity(0.3), lineWidth: 1.5)
            }
        )
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
        .padding(.horizontal)
        .padding(.bottom, 5)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: searchText.isEmpty)
        .overlay(
            Group {
                if !searchText.isEmpty {
                    SearchResultsOverlay(
                        documentsService: documentsService,
                        searchText: $searchText,
                        onSelect: { document in
                            // Dismiss search and open document
                            withAnimation {
                                searchText = ""
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }
                            documentToPreview = document
                            showDocumentPreview = true
                        }
                    )
                    .offset(y: 70) // Push below search bar
                }
            },
            alignment: .top
        )
        .zIndex(20) // Ensure dropdown appears above breadcrumbs and list
    }
}
