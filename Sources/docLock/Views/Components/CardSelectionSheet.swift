import SwiftUI

struct CardSelectionSheet: View {
    let cards: [CardModel]
    let onShare: (CardModel) -> Void
    @Binding var isPresented: Bool
    
    @State private var searchText = ""
    @State private var selectedCardId: String? = nil
    @State private var sheetOffset: CGFloat = 600
    
    var filteredCards: [CardModel] {
        if searchText.isEmpty {
            return cards
        }
        return cards.filter { card in
            card.cardName.localizedCaseInsensitiveContains(searchText) ||
            card.cardHolder.localizedCaseInsensitiveContains(searchText) ||
            card.cardNumber.contains(searchText)
        }
    }
    
    var debitCards: [CardModel] {
        filteredCards.filter { $0.type == .debit }
    }
    
    var creditCards: [CardModel] {
        filteredCards.filter { $0.type == .credit }
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
                    Text("Share Card")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                        .padding(.bottom, 20)
                    
                    if cards.count > 3 {
                        TextField("Search cards...", text: $searchText)
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
                    
                    if cards.isEmpty {
                        VStack(spacing: 15) {
                            Image(systemName: "creditcard.slash")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("No cards available to share.")
                                .foregroundColor(.gray)
                        }
                        .frame(height: 150)
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                if !debitCards.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Debit Cards")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.gray)
                                            .padding(.horizontal)
                                        
                                        ForEach(debitCards) { card in
                                            CardSelectionRow(
                                                card: card,
                                                isSelected: selectedCardId == card.id,
                                                onTap: {
                                                    selectedCardId = card.id
                                                }
                                            )
                                        }
                                    }
                                }
                                
                                if !creditCards.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Credit Cards")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.gray)
                                            .padding(.horizontal)
                                        
                                        ForEach(creditCards) { card in
                                            CardSelectionRow(
                                                card: card,
                                                isSelected: selectedCardId == card.id,
                                                onTap: {
                                                    selectedCardId = card.id
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
                        if let cardId = selectedCardId, let card = cards.first(where: { $0.id == cardId }) {
                            onShare(card)
                            withAnimation { isPresented = false }
                        }
                    }) {
                        Text("Share Card")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedCardId == nil ? Color.gray : Color.blue)
                            .cornerRadius(15)
                    }
                    .disabled(selectedCardId == nil)
                    .padding(.horizontal)
                    .padding(.bottom, 40)
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
        .zIndex(2000)
        .ignoresSafeArea(edges: .bottom)
    }
}

struct CardSelectionRow: View {
    let card: CardModel
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 15) {
                // Card Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [card.colorStart.opacity(0.3), card.colorEnd.opacity(0.3)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: card.type == .debit ? "creditcard" : "creditcard.fill")
                        .font(.system(size: 20))
                        .foregroundColor(card.colorStart)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.cardName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                    
                    Text("•••• \(card.cardNumber.suffix(4))")
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
}
