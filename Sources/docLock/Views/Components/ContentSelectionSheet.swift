import SwiftUI

// Note: CardModel and DocumentFile are defined in CardsView.swift and DocumentsView.swift respectively
// They need to be accessible here. If compilation fails, move these structs to a shared Models file.

struct ContentSelectionSheet: View {
    let cards: [CardModel]
    let documents: [DocumentFile]
    let requestType: String // "card" or "document"
    let onShare: (Any) -> Void // Can be CardModel or DocumentFile
    @Binding var isPresented: Bool
    
    @State private var searchText = ""
    @State private var selectedCardId: String? = nil
    @State private var selectedDocumentId: String? = nil
    
    @State private var sheetOffset: CGFloat = 600
    
    var filteredCards: [CardModel] {
        if searchText.isEmpty {
            return cards
        }
        return cards.filter { card in
            card.cardName.localizedCaseInsensitiveContains(searchText) ||
            card.cardHolder.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var filteredDocuments: [DocumentFile] {
        if searchText.isEmpty {
            return documents
        }
        return documents.filter { doc in
            doc.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var hasSelection: Bool {
        if requestType == "card" {
            return selectedCardId != nil
        } else {
            return selectedDocumentId != nil
        }
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
            
            // Bottom Sheet - Sticked to bottom
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
                    Text("Select \(requestType == "card" ? "Card" : "Document") to Share")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                        .padding(.bottom, 20)
                    
                    // Search Bar
                    if (requestType == "card" ? cards.count : documents.count) > 6 {
                        TextField("Search...", text: $searchText)
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
                    
                    if (requestType == "card" ? filteredCards.isEmpty : filteredDocuments.isEmpty) {
                        VStack(spacing: 15) {
                            Image(systemName: requestType == "card" ? "creditcard.slash" : "doc.text.slash")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("No \(requestType == "card" ? "cards" : "documents") available to share.")
                                .foregroundColor(.gray)
                        }
                        .frame(height: 150)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                if requestType == "card" {
                                    ForEach(filteredCards) { card in
                                        Button(action: {
                                            selectedCardId = card.id
                                            selectedDocumentId = nil
                                        }) {
                                            HStack(spacing: 15) {
                                                // Icon
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(Color.blue.opacity(0.1))
                                                        .frame(width: 44, height: 44)
                                                    Image(systemName: "creditcard.fill")
                                                        .font(.headline)
                                                        .foregroundColor(.blue)
                                                }
                                                
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(card.cardName)
                                                        .font(.subheadline)
                                                        .fontWeight(.medium)
                                                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                                                    Text(card.cardHolder)
                                                        .font(.caption)
                                                        .foregroundColor(.gray)
                                                }
                                                
                                                Spacer()
                                                
                                                if selectedCardId == card.id {
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
                                            .background(selectedCardId == card.id ? Color.blue.opacity(0.05) : Color.white)
                                            .cornerRadius(16)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(selectedCardId == card.id ? Color.blue : Color.gray.opacity(0.1), lineWidth: 1)
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                } else {
                                    ForEach(filteredDocuments) { document in
                                        Button(action: {
                                            selectedDocumentId = document.id
                                            selectedCardId = nil
                                        }) {
                                            HStack(spacing: 15) {
                                                // Icon
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(Color.blue.opacity(0.1))
                                                        .frame(width: 44, height: 44)
                                                    Image(systemName: document.type == "image" ? "photo.fill" : "doc.text.fill")
                                                        .font(.headline)
                                                        .foregroundColor(.blue)
                                                }
                                                
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(document.name)
                                                        .font(.subheadline)
                                                        .fontWeight(.medium)
                                                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                                                    Text(document.type == "image" ? "Image" : "Document")
                                                        .font(.caption)
                                                        .foregroundColor(.gray)
                                                }
                                                
                                                Spacer()
                                                
                                                if selectedDocumentId == document.id {
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
                                            .background(selectedDocumentId == document.id ? Color.blue.opacity(0.05) : Color.white)
                                            .cornerRadius(16)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(selectedDocumentId == document.id ? Color.blue : Color.gray.opacity(0.1), lineWidth: 1)
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(maxHeight: 350)
                    }
                    
                    Spacer().frame(height: 20)
                    
                    Button(action: {
                        if requestType == "card", let cardId = selectedCardId, let card = cards.first(where: { $0.id == cardId }) {
                            onShare(card)
                            withAnimation { isPresented = false }
                        } else if requestType == "document", let docId = selectedDocumentId, let document = documents.first(where: { $0.id == docId }) {
                            onShare(document)
                            withAnimation { isPresented = false }
                        }
                    }) {
                        Text("Share \(requestType == "card" ? "Card" : "Document")")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(hasSelection ? Color.blue : Color.gray)
                            .cornerRadius(15)
                    }
                    .disabled(!hasSelection)
                    .padding(.horizontal)
                    .padding(.bottom, 40) // Bottom safe area padding
                }
                .background(
                    ZStack {
                        Color(red: 0.98, green: 0.98, blue: 0.96)
                        
                        // Decorative Pops
                        GeometryReader { proxy in
                            Circle()
                                .fill(Color.blue.opacity(0.05))
                                .frame(width: 150, height: 150)
                                .position(x: 50, y: 100)
                                .blur(radius: 20)
                            
                            Circle()
                                .fill(Color.purple.opacity(0.05))
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
        .zIndex(100)
        .ignoresSafeArea(edges: .bottom)
    }
}
