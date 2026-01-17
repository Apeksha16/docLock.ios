import SwiftUI

// MARK: - Models
enum CardType: String, CaseIterable {
    case debit = "Debit Card"
    case credit = "Credit Card"
}

struct CardModel: Identifiable {
    var id = UUID()
    var type: CardType
    var cardName: String
    var cardNumber: String
    var cardHolder: String
    var expiry: String
    var cvv: String
    var colorStart: Color
    var colorEnd: Color
}

// MARK: - Main Cards View
struct CardsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var cardsService: CardsService
    let userId: String
    
    @State private var showingAddCard = false
    @State private var selectedCardToEdit: CardModel?
    @State private var showingDeleteAlert = false
    @State private var cardToDeleteId: UUID?

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.98, green: 0.96, blue: 0.98) // Light Lavender/Pinkish
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
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
                    Text("My Cards")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding()
                
                // Tip
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text("Tip: Click any card detail to copy it.")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Spacer()
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Debit Cards Section
                        if !cardsService.cards.filter({ $0.type == .debit }).isEmpty {
                            SectionHeader(title: "Debit Cards", count: cardsService.cards.filter({ $0.type == .debit }).count)
                            ForEach(cardsService.cards.filter({ $0.type == .debit })) { card in
                                CardView(card: card, onEdit: {
                                    selectedCardToEdit = card
                                }, onDelete: {
                                    cardToDeleteId = card.id
                                    showingDeleteAlert = true
                                })
                            }
                        }
                        
                        // Credit Cards Section
                        if !cardsService.cards.filter({ $0.type == .credit }).isEmpty {
                            SectionHeader(title: "Credit Cards", count: cardsService.cards.filter({ $0.type == .credit }).count)
                            ForEach(cardsService.cards.filter({ $0.type == .credit })) { card in
                                CardView(card: card, onEdit: {
                                    selectedCardToEdit = card
                                }, onDelete: {
                                    cardToDeleteId = card.id
                                    showingDeleteAlert = true
                                })
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, 80) // Space for FAB
                }
            }
            
            // FAB
            VStack {
                Spacer()
                Button(action: {
                    showingAddCard = true
                }) {
                    Image(systemName: "plus")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color(red: 1.0, green: 0.2, blue: 0.5)) // Pink
                        .clipShape(Circle())
                        .shadow(color: Color.pink.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .padding(.bottom, 30)
            }
            
            // Delete Alert Modal Overlay
            if showingDeleteAlert {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture { showingDeleteAlert = false }
                
                VStack(spacing: 20) {
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 60, height: 60)
                        .overlay(Image(systemName: "trash").foregroundColor(.red))
                    
                    Text("Delete Card?")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text("Are you sure you want to delete?\nThis action cannot be undone.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        if let id = cardToDeleteId {
                           // TODO: Call delete on service
                           // cardsService.deleteCard(id: id)
                           print("Deleting card: \(id)")
                        }
                        showingDeleteAlert = false
                    }) {
                        Text("Yes, Delete")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                    
                    Button("Cancel") {
                        showingDeleteAlert = false
                    }
                    .foregroundColor(.gray)
                }
                .padding(30)
                .background(Color.white)
                .cornerRadius(20)
                .padding(.horizontal, 40)
            }
        }
        .navigationBarHidden(true)
        .swipeToDismiss()
        .onAppear {
            cardsService.retry(userId: userId)
        }
        .sheet(isPresented: $showingAddCard) {
            AddEditCardView(isPresented: $showingAddCard, card: nil) { newCard in
                // Call add card service
            }
        }
        .sheet(item: $selectedCardToEdit) { card in
            AddEditCardView(isPresented: Binding(
                get: { selectedCardToEdit != nil },
                set: { if !$0 { selectedCardToEdit = nil } }
            ), card: card) { updatedCard in
                // Call update card service
            }
        }
    }
}

// MARK: - Subviews
struct SectionHeader: View {
    let title: String
    let count: Int
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
            Spacer()
            Text("\(count) cards")
                .font(.caption)
                .foregroundColor(Color.green)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.green.opacity(0.1))
                .cornerRadius(20)
        }
    }
}

struct CardView: View {
    let card: CardModel
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Card Background
            LinearGradient(gradient: Gradient(colors: [card.colorStart, card.colorEnd]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .cornerRadius(20)
                .shadow(radius: 5)
            
            VStack(alignment: .leading) {
                // Top Row: Actions + VISA
                HStack {
                    HStack(spacing: 10) {
                        CircleButton(icon: "pencil", action: onEdit)
                        CircleButton(icon: "trash", action: onDelete)
                        CircleButton(icon: "square.and.arrow.up", action: {})
                    }
                    Spacer()
                    Text("VISA")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(5)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(5)
                }
                
                Spacer()
                
                Text(card.cardName.uppercased())
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Text(card.cardNumber)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.bottom, 20)
                
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading) {
                        Text("CARD HOLDER")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                        Text(card.cardHolder.uppercased())
                            .font(.footnote)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("EXPIRES")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                        Text(card.expiry)
                            .font(.footnote)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("CVV")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                        Text("***")
                            .font(.footnote)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(20)
        }
        .frame(height: 200)
    }
}

struct CircleButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(Color.black.opacity(0.2))
                .clipShape(Circle())
        }
    }
}

// MARK: - Add/Edit Sheet
struct AddEditCardView: View {
    @Binding var isPresented: Bool
    @State var cardType: CardType = .debit
    @State var cardName: String = ""
    @State var cardNumber: String = ""
    @State var cardHolder: String = ""
    @State var expiry: String = ""
    @State var cvv: String = ""
    
    var card: CardModel? // If nil, adding mode
    var onSave: (CardModel) -> Void
    
    init(isPresented: Binding<Bool>, card: CardModel?, onSave: @escaping (CardModel) -> Void) {
        self._isPresented = isPresented
        self.card = card
        self.onSave = onSave
        
        // Initialize state from existing card if editing
        if let existingCard = card {
            _cardType = State(initialValue: existingCard.type)
            _cardName = State(initialValue: existingCard.cardName)
            _cardNumber = State(initialValue: existingCard.cardNumber)
            _cardHolder = State(initialValue: existingCard.cardHolder)
            _expiry = State(initialValue: existingCard.expiry)
            _cvv = State(initialValue: existingCard.cvv)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.black)
                    }
                    Spacer()
                    Text(card == nil ? "Add Card" : "Edit Card")
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                    Color.clear.frame(width: 20, height: 20)
                }
                .padding()
                
                // Card Preview
                ZStack {
                    LinearGradient(gradient: Gradient(colors: getGradientColors(for: cardType)), startPoint: .leading, endPoint: .trailing)
                        .cornerRadius(20)
                        .frame(height: 200)
                        
                    VStack(alignment: .leading) {
                         HStack {
                            VStack(alignment: .leading) {
                                Text("CARD NAME")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.7))
                                Text(cardName.isEmpty ? "CARD NAME" : cardName.uppercased())
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            Text("VISA")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(5)
                                .background(Color.white.opacity(0.3))
                                .cornerRadius(5)
                        }
                        
                        Spacer()
                        
                        Text(cardNumber.isEmpty ? "0000 0000 0000 0000" : cardNumber)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.bottom, 10)
                        
                        HStack {
                             VStack(alignment: .leading) {
                                Text("CARD HOLDER")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.7))
                                Text(cardHolder.isEmpty ? "NEW USER" : cardHolder.uppercased())
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            Spacer()
                             VStack(alignment: .leading) {
                                Text("EXPIRES")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.7))
                                Text(expiry.isEmpty ? "MM/YY" : expiry)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            Spacer()
                             VStack(alignment: .leading) {
                                Text("CVV")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.7))
                                Text(cvv.isEmpty ? "123" : cvv)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(20)
                }
                .padding()
                
                // Form
                VStack(alignment: .leading, spacing: 10) {
                    Text("Card Type")
                         .fontWeight(.bold)
                    
                    HStack(spacing: 15) {
                        Button(action: { cardType = .debit }) {
                            HStack {
                                Image(systemName: "building.columns.fill")
                                Text("Debit Card")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(cardType == .debit ? Color(red: 1.0, green: 0.2, blue: 0.5) : Color.white)
                            .foregroundColor(cardType == .debit ? .white : .gray)
                            .cornerRadius(10)
                            .shadow(radius: 2)
                        }
                        
                        Button(action: { cardType = .credit }) {
                            HStack {
                                Image(systemName: "creditcard.fill")
                                Text("Credit Card")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(cardType == .credit ? Color(red: 1.0, green: 0.2, blue: 0.5) : Color.white)
                            .foregroundColor(cardType == .credit ? .white : .gray)
                            .cornerRadius(10)
                            .shadow(radius: 2)
                        }
                    }
                    
                    Group {
                         CustomFormTextField(title: "Card Name", placeholder: "e.g., Personal Visa", text: $cardName)
                        
                        CustomFormTextField(title: "Card Number", placeholder: "0000 0000 0000 0000", text: $cardNumber)
                            .keyboardType(.numberPad)
                            
                        CustomFormTextField(title: "Card Holder Name", placeholder: "New User", text: $cardHolder)
                        
                        HStack {
                             CustomFormTextField(title: "Expiry Date", placeholder: "MM/YY", text: $expiry)
                            Spacer()
                             CustomFormTextField(title: "CVV", placeholder: "123", text: $cvv)
                                .keyboardType(.numberPad)
                        }
                    }
                }
                .padding()
                
                Button(action: {
                    let colors = getGradientColors(for: cardType)
                    let newCard = CardModel(id: card?.id ?? UUID(), type: cardType, cardName: cardName, cardNumber: cardNumber, cardHolder: cardHolder, expiry: expiry, cvv: cvv, colorStart: colors[0], colorEnd: colors[1])
                    onSave(newCard)
                    isPresented = false
                }) {
                    Text(card == nil ? "Save Card" : "Update Card")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 1.0, green: 0.2, blue: 0.5))
                        .foregroundColor(.white)
                        .cornerRadius(15)
                }
                .padding()
                
                Spacer()
            }
        }
    }
    
    func getGradientColors(for type: CardType) -> [Color] {
        switch type {
        case .debit:
            return [Color(red: 0.95, green: 0.85, blue: 0.4), Color(red: 0.9, green: 0.7, blue: 0.2)] // Gold/Yellow
        case .credit:
            return [Color(red: 0.9, green: 0.4, blue: 0.6), Color(red: 0.95, green: 0.6, blue: 0.75)] // Pinkish
        }
    }
}

struct CustomFormTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.footnote)
                .fontWeight(.bold)
            TextField(placeholder, text: $text)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
        }
    }
}
