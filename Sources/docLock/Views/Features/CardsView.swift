import SwiftUI
#if os(iOS)
import VisionKit
import Vision
#endif
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Models
enum CardType: String, CaseIterable {
    case debit = "Debit Card"
    case credit = "Credit Card"
}

struct CardModel: Identifiable {
    var id: String
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
    @ObservedObject var notificationService: NotificationService
    let userId: String
    
    @State private var showingAddCard = false
    @State private var selectedCardToEdit: CardModel?
    @State private var showingDeleteAlert = false
    @State private var cardToDeleteId: String?
    @State private var hasAppeared = false
    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []
    
    // Toast State
    @State private var toastMessage: String?
    @State private var toastType: ToastType = .success
    
    // FAB State
    @State private var showFabMenu = false
    @State private var selectedNewCardType: CardType = .debit

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.98, green: 0.96, blue: 0.98) // Light Lavender/Pinkish
                .edgesIgnoringSafeArea(.all)
            
            // Animated Ambient Gradients
            GeometryReader { proxy in
                // Top Right - Animated Warm Glow (Pink/Red for Cards theme)
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color(red: 1.0, green: 0.2, blue: 0.5).opacity(hasAppeared ? 0.15 : 0.05),
                                Color(red: 1.0, green: 0.2, blue: 0.5).opacity(hasAppeared ? 0.08 : 0.03),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 10,
                            endRadius: hasAppeared ? 180 : 150
                        )
                    )
                    .frame(width: 450, height: 450)
                    .position(x: proxy.size.width * 0.9, y: hasAppeared ? -50 : -100)
                    .blur(radius: 50)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: hasAppeared)
                
                // Top Left - Animated Purple/Blue Haze
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.3, green: 0.2, blue: 0.9).opacity(hasAppeared ? 0.06 : 0.02),
                                Color(red: 0.3, green: 0.2, blue: 0.9).opacity(0.03),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 20,
                            endRadius: 200
                        )
                    )
                    .frame(width: 350, height: 350)
                    .position(x: -50, y: hasAppeared ? 80 : 50)
                    .blur(radius: 60)
                    .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: hasAppeared)
                
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
                    .frame(width: proxy.size.width * 1.3, height: 400)
                    .position(x: proxy.size.width / 2, y: proxy.size.height * 1.1)
                    .blur(radius: 70)
                    .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: hasAppeared)
            }
            
            VStack {
                // Header
                HStack {
                    Button(action: {
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
                    Text("My Cards")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                    Spacer()
                    

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
                
                if cardsService.cards.isEmpty {
                    // Premium Animated Empty State (Cards)
                    VStack {
                        Spacer().frame(height: 50)
                        
                        ZStack {
                            // Animated Background Glow
                            RoundedRectangle(cornerRadius: 50)
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 1.0, green: 0.9, blue: 0.95).opacity(hasAppeared ? 1 : 0.5), // Light Pink
                                            Color(red: 1.0, green: 0.95, blue: 0.98).opacity(hasAppeared ? 0.8 : 0.3)
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
                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 90, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 1.0, green: 0.2, blue: 0.5),
                                            Color(red: 1.0, green: 0.4, blue: 0.6)
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
                                            Color.pink.opacity(0.4),
                                            Color.orange.opacity(0.2)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)
                                .offset(x: -90, y: -80)
                                .scaleEffect(hasAppeared ? 1 : 0.5)
                                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: hasAppeared)
                            
                            Circle()
                                .fill(Color.pink.opacity(0.2))
                                .frame(width: 30, height: 30)
                                .offset(x: .random(in: 60...100), y: .random(in: 60...80))
                                .scaleEffect(hasAppeared ? 1 : 0.5)
                                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5), value: hasAppeared)
                        }
                        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: hasAppeared)
                        
                        Spacer().frame(height: 40)
                        
                        // Content Text
                        VStack(spacing: 18) {
                            Text("No Cards Added")
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
                            
                            Text("Securely store your debit and credit cards\nfor easy and quick access.")
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
                        
                        Spacer()
                        
                        // Action Button
                        Button(action: {
                             // Use FAB logic for empty state too
                             withAnimation(.spring()) {
                                 showFabMenu = true
                             }
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                Text("Add New Card")
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .frame(width: 220, height: 56)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 1.0, green: 0.2, blue: 0.5),
                                        Color(red: 1.0, green: 0.4, blue: 0.6)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(20)
                            .shadow(color: Color.pink.opacity(0.4), radius: 10, y: 5)
                        }
                        .padding(.bottom, 50)
                        .opacity(hasAppeared ? 1 : 0)
                        .offset(y: hasAppeared ? 0 : 30)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.4), value: hasAppeared)
                    }
                    .onAppear {
                        withAnimation {
                            hasAppeared = true
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 5) {
                        
                        let debitCards = cardsService.cards.filter { $0.type == .debit }
                        if !debitCards.isEmpty {
                            SectionHeader(title: "Debit Cards", count: debitCards.count)
                                .padding(.horizontal)
                            
                            TabView {
                                ForEach(debitCards) { card in
                                    CardView(card: card, onEdit: {
                                        selectedCardToEdit = card
                                    }, onDelete: {
                                        cardToDeleteId = card.id
                                        showingDeleteAlert = true
                                    }, onShare: {
                                        let text = "Card Name: \(card.cardName)\nNumber: \(card.cardNumber)\nHolder: \(card.cardHolder)\nExpiry: \(card.expiry)"
                                        shareItems = [text]
                                        showingShareSheet = true
                                    }, onCopy: { message in
                                        toastMessage = message
                                        toastType = .success
                                    })
                                    .padding(.horizontal) // Add horizontal padding inside the page
                                }
                            }
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                            .frame(height: 220) // Reduced height to save space

                        }
                        
                        let creditCards = cardsService.cards.filter { $0.type == .credit }
                        if !creditCards.isEmpty {
                            SectionHeader(title: "Credit Cards", count: creditCards.count)
                                .padding(.horizontal)
                            
                            TabView {
                                ForEach(creditCards) { card in
                                    CardView(card: card, onEdit: {
                                        selectedCardToEdit = card
                                    }, onDelete: {
                                        cardToDeleteId = card.id
                                        showingDeleteAlert = true
                                    }, onShare: {
                                        let text = "Card Name: \(card.cardName)\nNumber: \(card.cardNumber)\nHolder: \(card.cardHolder)\nExpiry: \(card.expiry)"
                                        shareItems = [text]
                                        showingShareSheet = true
                                    }, onCopy: { message in
                                        toastMessage = message
                                        toastType = .success
                                    })
                                    .padding(.horizontal)
                                }
                            }
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                            .frame(height: 220) // Reduced height to save space

                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 10)
                }
            }
            .blur(radius: (showFabMenu || showingAddCard) ? 2 : 0) // Blur background when modal is open
            
            // FAB Menu Overlay
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
                    
                    Button(action: {
                        withAnimation {
                            showFabMenu = false
                            selectedNewCardType = .credit
                            showingAddCard = true
                        }
                    }) {
                        FabMenuRow(title: "Credit Card", icon: "creditcard.fill", color: .purple)
                    }
                    
                    Button(action: {
                        withAnimation {
                            showFabMenu = false
                            selectedNewCardType = .debit
                            showingAddCard = true
                        }
                    }) {
                        FabMenuRow(title: "Debit Card", icon: "creditcard", color: .blue)
                    }
                    
                    Spacer().frame(height: 80) // Space for close button
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // FAB Button (Center Bottom)
            if !cardsService.cards.isEmpty {
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
                                    .fill(showFabMenu ? Color(red: 1.0, green: 0.2, blue: 0.5).opacity(0.8) : Color(red: 1.0, green: 0.2, blue: 0.5))
                                    .frame(width: 60, height: 60)
                                    .shadow(color: Color(red: 1.0, green: 0.2, blue: 0.5).opacity(0.4), radius: 10, x: 0, y: 5)
                                
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
            
            // Delete Alert Modal Overlay
            // Delete Alert Modal Overlay
            if showingDeleteAlert {
                CustomActionModal(
                    icon: "trash.fill",
                    iconBgColor: .red,
                    title: "Delete Card?",
                    subtitle: nil,
                    message: "Are you sure you want to delete this card?\nThis action cannot be undone.",
                    primaryButtonText: "Yes, Delete",
                    primaryButtonColor: .red,
                    onPrimaryAction: {
                        if let id = cardToDeleteId {
                           cardsService.deleteCard(userId: userId, cardId: id) { success, error in
                               DispatchQueue.main.async {
                                   if success {
                                       toastMessage = "Card deleted successfully"
                                       toastType = .success
                                   } else {
                                       print("Error deleting card: \(error ?? "Unknown")")
                                       toastMessage = "Failed to delete card"
                                       toastType = .error
                                   }
                               }
                           }
                        }
                        showingDeleteAlert = false
                    },
                    onCancel: {
                        showingDeleteAlert = false
                    }
                )
            }
            
        }
        .navigationBarHidden(true)
        .swipeToDismiss()
        .toast(message: $toastMessage, type: toastType)
        .onAppear {
            cardsService.retry(userId: userId)
            withAnimation(.easeOut(duration: 1.0)) {
                hasAppeared = true
            }
        }
        .sheet(isPresented: $showingAddCard) {

            AddEditCardView(isPresented: $showingAddCard, cardType: selectedNewCardType, card: nil as CardModel?, userId: userId, cardsService: cardsService, notificationService: notificationService) { message in
                toastMessage = message
                toastType = .success
            }
        }
        .sheet(item: $selectedCardToEdit) { card in
            AddEditCardView(isPresented: Binding(
                get: { selectedCardToEdit != nil },
                set: { if !$0 { selectedCardToEdit = nil } }
            ), card: card, userId: userId, cardsService: cardsService, notificationService: notificationService) { message in
                toastMessage = message
                toastType = .success
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            #if os(iOS)
            ShareSheet(items: shareItems)
            #else
            EmptyView()
            #endif
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
    let onShare: () -> Void
    let onCopy: (String) -> Void
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Card Background
            LinearGradient(gradient: Gradient(colors: [card.colorStart, card.colorEnd]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.7),
                                    Color.white.opacity(0.5)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.5
                        )
                )
            
            VStack(alignment: .leading) {
                // Top Row: Actions + VISA
                HStack {
                    HStack(spacing: 10) {
                        CircleButton(icon: "pencil", action: onEdit)
                        CircleButton(icon: "trash", action: onDelete)
                        CircleButton(icon: "square.and.arrow.up", action: onShare)
                    }
                    Spacer()
                    Text(getCardBrand(number: card.cardNumber))
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
                    .onTapGesture {
                        UIPasteboard.general.string = card.cardName
                        onCopy("Card Name copied")
                    }
                
                Text(maskCardNumber(card.cardNumber))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.bottom, 20)
                    .onTapGesture {
                        UIPasteboard.general.string = card.cardNumber
                        onCopy("Card Number copied")
                    }
                
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading) {
                        Text("CARD HOLDER")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                        Text(card.cardHolder.uppercased())
                            .font(.footnote)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .onTapGesture {
                                UIPasteboard.general.string = card.cardHolder
                                onCopy("Card Holder copied")
                            }
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
                            .onTapGesture {
                                UIPasteboard.general.string = card.expiry
                                onCopy("Expiry Date copied")
                            }
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("CVV")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                        Text("***") // Should we copy real CVV or masked? User asked to copy detail. Usually real CVV.
                            .font(.footnote)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .onTapGesture {
                                UIPasteboard.general.string = card.cvv
                                onCopy("CVV copied")
                            }
                    }
                }
            }
            .padding(20)
        }
        .frame(height: 200)
    }
    
    private func maskCardNumber(_ number: String) -> String {
        let parts = number.components(separatedBy: " ")
        if parts.count == 4 {
            return "\(parts[0]) **** **** \(parts[3])"
        } else if number.count > 8 {
             let prefix = number.prefix(4)
             let suffix = number.suffix(4)
             return "\(prefix) **** **** \(suffix)"
        }
        return number
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
    @State var cardType: CardType
    @State var cardName: String = ""
    @State var cardNumber: String = ""
    @State var cardHolder: String = ""
    @State var expiry: String = ""
    @State var cvv: String = ""
    @State private var showingScanner = false
    
    var card: CardModel? // If nil, adding mode
    let userId: String
    let cardsService: CardsService
    let notificationService: NotificationService
    var onSuccess: ((String) -> Void)?
    @State private var isLoading = false
    
    // Predefined vibrant card colors
    let cardColors: [[Color]] = [
        [Color(red: 0.95, green: 0.85, blue: 0.4), Color(red: 0.9, green: 0.7, blue: 0.2)], // Gold
        [Color(red: 0.9, green: 0.4, blue: 0.6), Color(red: 0.95, green: 0.6, blue: 0.75)], // Pinkish
        [Color(red: 0.2, green: 0.6, blue: 0.9), Color(red: 0.4, green: 0.8, blue: 1.0)], // Blue
        [Color(red: 0.4, green: 0.8, blue: 0.6), Color(red: 0.6, green: 0.9, blue: 0.7)], // Green
        [Color(red: 0.6, green: 0.4, blue: 0.9), Color(red: 0.7, green: 0.5, blue: 1.0)], // Purple
        [Color(red: 1.0, green: 0.6, blue: 0.4), Color(red: 1.0, green: 0.7, blue: 0.5)], // Orange
        [Color(red: 0.2, green: 0.2, blue: 0.2), Color(red: 0.3, green: 0.3, blue: 0.3)], // Dark/Black
        [Color(red: 0.8, green: 0.2, blue: 0.2), Color(red: 1.0, green: 0.4, blue: 0.4)], // Red
        [Color(red: 0.0, green: 0.5, blue: 0.5), Color(red: 0.0, green: 0.7, blue: 0.7)]  // Teal
    ]
    
    @State private var selectedColorIndex: Int = 0
    @State private var hasAppeared = false

    init(isPresented: Binding<Bool>, cardType: CardType = .debit, card: CardModel?, userId: String, cardsService: CardsService, notificationService: NotificationService, onSuccess: ((String) -> Void)? = nil) {
        self._isPresented = isPresented
        self.card = card
        self.userId = userId
        self.cardsService = cardsService
        self.notificationService = notificationService
        self.onSuccess = onSuccess
        
        // Initialize state from existing card if editing
        if let existingCard = card {
            _cardType = State(initialValue: existingCard.type)
            _cardName = State(initialValue: existingCard.cardName)
            _cardNumber = State(initialValue: existingCard.cardNumber)
            _cardHolder = State(initialValue: existingCard.cardHolder)
            _expiry = State(initialValue: existingCard.expiry)
            _cvv = State(initialValue: existingCard.cvv)
            // Try to find matching color index, default to 0
            // Note: Exact color matching might be tricky with float comparison, relying on stored colors for display is fine.
            // For editing, we might just keep the current color or allow re-selection.
            // For now, we won't change color on edit unless we add a picker.
            // For now, we won't change color on edit unless we add a picker.
        } else {
            _cardType = State(initialValue: cardType)
            // Randomly select a color for new card
            _selectedColorIndex = State(initialValue: Int.random(in: 0..<cardColors.count))
        }
    }
    
    var body: some View {
        ZStack {
            // Premium Animated Background Theme
            ZStack {
                // Base Background with gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.99, green: 0.99, blue: 0.99),
                        Color(red: 0.98, green: 0.98, blue: 0.99)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
                
                // Animated Ambient Gradients
                GeometryReader { proxy in
                    // Top Right - Animated Warm Glow
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.orange.opacity(hasAppeared ? 0.15 : 0.05),
                                    Color.orange.opacity(hasAppeared ? 0.08 : 0.03),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 10,
                                endRadius: hasAppeared ? 180 : 150
                            )
                        )
                        .frame(width: 450, height: 450)
                        .position(x: proxy.size.width * 0.9, y: hasAppeared ? -50 : -100)
                        .blur(radius: 50)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: hasAppeared)
                    
                    // Top Left - Animated Blue Haze
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(hasAppeared ? 0.06 : 0.02),
                                    Color.blue.opacity(0.03),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 20,
                                endRadius: 200
                            )
                        )
                        .frame(width: 350, height: 350)
                        .position(x: -50, y: hasAppeared ? 80 : 50)
                        .blur(radius: 60)
                        .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: hasAppeared)
                    
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
                        .frame(width: proxy.size.width * 1.3, height: 400)
                        .position(x: proxy.size.width / 2, y: proxy.size.height * 1.1)
                        .blur(radius: 70)
                        .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: hasAppeared)
                }
            }
            .onAppear {
                 withAnimation {
                     hasAppeared = true
                 }
            }
            
            ScrollView {
                VStack(spacing: 20) {
                // Header
                HStack {
                    Button(action: { isPresented = false }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .frame(width: 56, height: 56)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color(red: 0.8, green: 0.8, blue: 0.9), lineWidth: 1)
                                )
                            
                            Image(systemName: "arrow.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.black)
                        }
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    Spacer()
                    Text(card == nil ? "Add Card" : "Edit Card")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                    Spacer()
                    #if os(iOS)
                    if #available(iOS 16.0, *) {
                        Button(action: {
                            if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                                showingScanner = true
                            }
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                                    .frame(width: 56, height: 56)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color(red: 0.8, green: 0.8, blue: 0.9), lineWidth: 1)
                                    )
                                
                                Image(systemName: "camera.viewfinder")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.black)
                            }
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                    } else {
                        Color.clear.frame(width: 56, height: 56)
                    }
                    #else
                    Color.clear.frame(width: 56, height: 56)
                    #endif
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                // Card Preview
                ZStack {
                    LinearGradient(gradient: Gradient(colors: card != nil ? [card!.colorStart, card!.colorEnd] : cardColors[selectedColorIndex]), startPoint: .leading, endPoint: .trailing)
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
                            if !getCardBrand(number: cardNumber).isEmpty {
                                Text(getCardBrand(number: cardNumber))
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(5)
                                    .background(Color.white.opacity(0.3))
                                    .cornerRadius(5)
                            }
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
                                Text(cvv.isEmpty ? "123" : "•••")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(20)
                }
                .padding(.horizontal)
                
                    // Card Type selection removed as it is now handled by FAB menu

                // Form
                VStack(alignment: .leading, spacing: 10) {
                    Group {
                        CustomFormTextField(title: "Card Name", placeholder: "e.g., Personal Visa", text: $cardName)
                            .onChange(of: cardName) { newValue in
                                var filtered = newValue.filter { $0.isLetter || $0.isWhitespace || $0 == "-" }
                                if filtered.count > 30 {
                                    filtered = String(filtered.prefix(30))
                                }
                                if filtered != newValue {
                                    cardName = filtered
                                }
                            }
                        
                        CustomFormTextField(title: "Card Number", placeholder: "0000 0000 0000 0000", text: $cardNumber, keyboardType: .numberPad)
                            .onChange(of: cardNumber) { newValue in
                                formatCardNumber(newValue)
                            }
                            
                        CustomFormTextField(title: "Card Holder Name", placeholder: "New User", text: $cardHolder)
                            .onChange(of: cardHolder) { newValue in
                                var filtered = newValue.filter { $0.isLetter || $0.isWhitespace || $0 == "-" }
                                if filtered.count > 25 {
                                    filtered = String(filtered.prefix(25))
                                }
                                if filtered != newValue {
                                    cardHolder = filtered
                                }
                            }
                        
                        HStack {
                             CustomFormTextField(title: "Expiry Date", placeholder: "MM/YY", text: $expiry, keyboardType: .numberPad)
                                .onChange(of: expiry) { newValue in
                                    formatExpiry(newValue)
                                }
                            Spacer()
                             CustomFormTextField(title: "CVV", placeholder: "123", text: $cvv, isSecure: true, keyboardType: .numberPad)
                                .onChange(of: cvv) { newValue in
                                    formatCVV(newValue)
                                }
                        }
                    }
                }
                .padding()
                
                // Action Button
                Button(action: {
                    saveCard()
                }) {
                    ZStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(card == nil ? "Save Card" : "Update Card")
                                .fontWeight(.bold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 1.0, green: 0.2, blue: 0.5))
                    .foregroundColor(.white)
                    .cornerRadius(15)
                }
                .disabled(cardName.isEmpty || cardNumber.isEmpty || cardHolder.isEmpty || expiry.isEmpty || cvv.isEmpty || isLoading)
                .opacity((cardName.isEmpty || cardNumber.isEmpty || cardHolder.isEmpty || expiry.isEmpty || cvv.isEmpty || isLoading) ? 0.6 : 1)
                .padding()
                
                Spacer()
            }
        }
        .sheet(isPresented: $showingScanner) {
            #if os(iOS)
            if #available(iOS 16.0, *) {
                CardScannerView(isPresented: $showingScanner) { number, expiry, name in
                    self.cardNumber = number
                    if let exp = expiry {
                        self.expiry = exp
                    }
                    if let name = name {
                        // self.cardHolder = name
                    }
                }
            }
            #endif
        }
        .background(Color.clear)
        }
    }
    
    func saveCard() {
        isLoading = true
        // If editing, keep original colors unless we add a picker. If adding, use selected random color.
        let colors = card != nil ? [card!.colorStart, card!.colorEnd] : cardColors[selectedColorIndex]
        
        let newCard = CardModel(
            id: card?.id ?? UUID().uuidString,
            type: cardType,
            cardName: cardName,
            cardNumber: cardNumber,
            cardHolder: cardHolder,
            expiry: expiry,
            cvv: cvv,
            colorStart: colors[0],
            colorEnd: colors[1]
        )
        
        if card == nil {
            // Add
            cardsService.addCard(userId: userId, card: newCard) { success, error in
                DispatchQueue.main.async {
                    if success {
                        // Trigger Notification
                        notificationService.addNotification(
                            userId: userId,
                            title: "Card Added",
                            message: "A new \(cardType.rawValue) '\(cardName)' has been added to your list.",
                            type: "security"
                        )
                        isLoading = false
                        isPresented = false
                        onSuccess?("Card added successfully")
                    } else {
                        isLoading = false
                        print("Error adding card: \(error ?? "Unknown")")
                    }
                }
            }
        } else {
            // Update
            cardsService.updateCard(userId: userId, cardId: newCard.id, card: newCard) { success, error in
                DispatchQueue.main.async {
                    if success {
                        notificationService.addNotification(
                            userId: userId,
                            title: "Card Updated",
                            message: "Your \(cardType.rawValue) '\(cardName)' has been updated.",
                            type: "security"
                        )
                        isLoading = false
                        isPresented = false
                        onSuccess?("Card updated successfully")
                    } else {
                        isLoading = false
                    }
                }
            }
        }
    }

    // Helper not strictly needed anymore given random selection, but kept for fallback or validation
    func getGradientColors(for type: CardType) -> [Color] {
         return cardColors[0] // Default fallback
    }
    
    // MARK: - Validation Helpers
    func formatCardNumber(_ value: String) {
        let clean = value.filter { "0123456789".contains($0) }
        let trimmed = String(clean.prefix(16))
        
        var formatted = ""
        for (i, char) in trimmed.enumerated() {
            if i > 0 && i % 4 == 0 {
                formatted += " "
            }
            formatted.append(char)
        }
        
        if cardNumber != formatted {
            cardNumber = formatted
        }
    }
    
    func formatExpiry(_ value: String) {
        var clean = value.replacingOccurrences(of: "/", with: "")
        clean = clean.filter { "0123456789".contains($0) }
        
        if clean.count > 4 {
            clean = String(clean.prefix(4))
        }
        
        // Month validation
        if clean.count >= 2 {
            if let month = Int(clean.prefix(2)), month > 12 {
                clean = "12" + clean.dropFirst(2)
            } else if let month = Int(clean.prefix(2)), month == 0 {
                // Allow typing 0
            }
        }
        
        var formatted = clean
        // Auto append slash if length is 2 or more
        if clean.count >= 2 {
            formatted = String(clean.prefix(2)) + "/" + String(clean.suffix(from: clean.index(clean.startIndex, offsetBy: 2)))
        }
        
        if expiry != formatted {
            expiry = formatted
        }
    }
    
    func formatCVV(_ value: String) {
        let clean = value.filter { "0123456789".contains($0) }
        let limit = 4
        let trimmed = String(clean.prefix(limit))
        
        if cvv != trimmed {
            cvv = trimmed
        }
    }
}

struct CustomFormTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: FormKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .applyKeyboardType(keyboardType)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            } else {
                TextField(placeholder, text: $text)
                    .applyKeyboardType(keyboardType)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            }
        }
    }
}

// MARK: - Form Helpers
enum FormKeyboardType {
    case `default`, numberPad, emailAddress, decimalPad
    
    #if os(iOS)
    var uiType: UIKeyboardType {
        switch self {
        case .default: return .default
        case .numberPad: return .numberPad
        case .emailAddress: return .emailAddress
        case .decimalPad: return .decimalPad
        }
    }
    #endif
}

extension View {
    @ViewBuilder
    func applyKeyboardType(_ type: FormKeyboardType) -> some View {
        #if os(iOS)
        self.keyboardType(type.uiType)
        #else
        self
        #endif
    }
}

// MARK: - Helper Functions
func getCardBrand(number: String) -> String {
    let cleanNumber = number.replacingOccurrences(of: " ", with: "")
    if cleanNumber.isEmpty { return "" }
    
    if cleanNumber.hasPrefix("4") { return "VISA" }
    if cleanNumber.hasPrefix("34") || cleanNumber.hasPrefix("37") { return "AMEX" }
    
    // Mastercard
    if cleanNumber.hasPrefix("51") || cleanNumber.hasPrefix("52") || cleanNumber.hasPrefix("53") || cleanNumber.hasPrefix("54") || cleanNumber.hasPrefix("55") { return "MASTERCARD" }
    if cleanNumber.hasPrefix("2") {
        let prefixInt = Int(cleanNumber.prefix(4)) ?? 0
        // Check if we have enough digits to definitively say it's MC 2-series range (2221-2720)
        // If we only have "2", we don't know yet. But user wants auto-detect AS THEY TYPE.
        // If user types "2", we probably shouldn't show MC yet unless we are sure.
        // But 2221... requires 4 digits.
        if cleanNumber.count >= 4 {
             if prefixInt >= 2221 && prefixInt <= 2720 { return "MASTERCARD" }
        }
    }
    
    // RuPay
    if cleanNumber.hasPrefix("60") || cleanNumber.hasPrefix("65") || cleanNumber.hasPrefix("81") || cleanNumber.hasPrefix("82") || cleanNumber.hasPrefix("508") || cleanNumber.hasPrefix("353") || cleanNumber.hasPrefix("356") { return "RUPAY" }
    
    return ""
}

#if os(iOS)
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil as [UIActivity]?)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Card Scanner View
@available(iOS 16.0, *)
struct CardScannerView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onScanComplete: (String, String?, String?) -> Void // number, expiry, name
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: Set([DataScannerViewController.RecognizedDataType.text()]),
            qualityLevel: .accurate,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: false,
            isHighlightingEnabled: true
        )
        
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        if isPresented {
            if !uiViewController.isScanning {
                try? uiViewController.startScanning()
            }
        } else {
            if uiViewController.isScanning {
                uiViewController.stopScanning()
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let parent: CardScannerView
        private var scannedNumber: String?
        private var scannedExpiry: String?
        private var scannedName: String?
        private var allScannedText: [String] = []
        
        init(_ parent: CardScannerView) {
            self.parent = parent
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            for item in addedItems {
                switch item {
                case .text(let text):
                    let textContent = text.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                    allScannedText.append(textContent)
                    
                    // Try to extract credit card number
                    if scannedNumber == nil {
                        if let cardNumber = extractCardNumber(from: textContent) {
                            scannedNumber = cardNumber
                            print("📱 CardScanner: Found card number: \(cardNumber)")
                        }
                    }
                    
                    // Try to extract expiry date
                    if scannedExpiry == nil {
                        if let expiry = extractExpiryDate(from: textContent) {
                            scannedExpiry = expiry
                            print("📱 CardScanner: Found expiry: \(expiry)")
                        }
                    }
                    
                    // Try to extract cardholder name
                    if scannedName == nil {
                        if let name = extractCardholderName(from: textContent) {
                            scannedName = name
                            print("📱 CardScanner: Found name: \(name)")
                        }
                    }
                    
                case .barcode(let barcode):
                    // Handle barcode if needed
                    print("📱 CardScanner: Scanned barcode: \(barcode.payloadStringValue)")
                    
                @unknown default:
                    break
                }
            }
            
            // If we have a card number, complete the scan
            if let number = scannedNumber {
                let formattedExpiry = formatExpiryFromString(scannedExpiry)
                parent.onScanComplete(number, formattedExpiry, scannedName)
                DispatchQueue.main.async {
                    self.parent.isPresented = false
                }
            }
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            // Handle removed items if needed
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            // Handle updated items if needed
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            // Handle tap if needed
        }
        
        private func extractCardNumber(from text: String) -> String? {
            // Remove spaces and dashes
            let cleaned = text.replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: "-", with: "")
                .replacingOccurrences(of: "•", with: "")
            
            // Check if it's a valid credit card number (13-19 digits)
            let cardNumberPattern = "^[0-9]{13,19}$"
            if let regex = try? NSRegularExpression(pattern: cardNumberPattern, options: []),
               regex.firstMatch(in: cleaned, options: [], range: NSRange(location: 0, length: cleaned.utf16.count)) != nil {
                return cleaned
            }
            
            // Also check for formatted numbers like "1234 5678 9012 3456"
            let formattedPattern = "^[0-9]{4}\\s[0-9]{4}\\s[0-9]{4}\\s[0-9]{4}$"
            if let regex = try? NSRegularExpression(pattern: formattedPattern, options: []),
               regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) != nil {
                return cleaned
            }
            
            return nil
        }
        
        private func extractExpiryDate(from text: String) -> String? {
            // Look for MM/YY or MM/YYYY format
            let expiryPattern = "\\b(0[1-9]|1[0-2])/([0-9]{2}|[0-9]{4})\\b"
            if let regex = try? NSRegularExpression(pattern: expiryPattern, options: []),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) {
                let matchedString = (text as NSString).substring(with: match.range)
                // Convert to MM/YY format if needed
                if matchedString.count == 7 { // MM/YYYY
                    let components = matchedString.split(separator: "/")
                    if components.count == 2, let year = Int(components[1]) {
                        let shortYear = year % 100
                        return "\(components[0])/\(String(format: "%02d", shortYear))"
                    }
                }
                return matchedString
            }
            
            // Also check for MMYY format (4 digits)
            let mmYYPattern = "\\b(0[1-9]|1[0-2])([0-9]{2})\\b"
            if let regex = try? NSRegularExpression(pattern: mmYYPattern, options: []),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) {
                let matchedString = (text as NSString).substring(with: match.range)
                if matchedString.count == 4 {
                    let index = matchedString.index(matchedString.startIndex, offsetBy: 2)
                    return "\(matchedString[..<index])/\(matchedString[index...])"
                }
            }
            
            return nil
        }
        
        private func extractCardholderName(from text: String) -> String? {
            // Look for names (2-4 words, mostly letters, may have some special chars)
            let namePattern = "^[A-Z][A-Za-z]+(?:\\s+[A-Z][A-Za-z]+){1,3}$"
            if let regex = try? NSRegularExpression(pattern: namePattern, options: []),
               regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) != nil {
                // Make sure it's not a card number or expiry
                if !text.contains(where: { $0.isNumber }) && text.count > 5 && text.count < 50 {
                    return text
                }
            }
            return nil
        }
        
        private func formatExpiryFromString(_ expiry: String?) -> String? {
            guard let expiry = expiry else { return nil }
            // Ensure MM/YY format
            if expiry.count == 4 && expiry.allSatisfy({ $0.isNumber }) {
                let index = expiry.index(expiry.startIndex, offsetBy: 2)
                return "\(expiry[..<index])/\(expiry[index...])"
            }
            return expiry
        }
    }
}
#endif
