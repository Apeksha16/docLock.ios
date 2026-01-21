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
    var colorIndex: Int? // Store index to persist color selection reliably
    var isShared: Bool = false
    var sharedBy: String? = nil
    
    // Static Palettes
    static let creditCardColors: [[Color]] = [
        [Color(red: 0.9, green: 0.2, blue: 0.6), Color(red: 0.95, green: 0.4, blue: 0.7)], // Hot Pink
        [Color(red: 0.6, green: 0.1, blue: 0.4), Color(red: 0.8, green: 0.2, blue: 0.5)], // Deep Berry
        [Color(red: 1.0, green: 0.6, blue: 0.2), Color(red: 1.0, green: 0.8, blue: 0.4)], // Gold/Orange
        [Color(red: 0.8, green: 0.1, blue: 0.1), Color(red: 1.0, green: 0.4, blue: 0.4)], // Red
        [Color(red: 0.4, green: 0.1, blue: 0.6), Color(red: 0.6, green: 0.3, blue: 0.8)]  // Purple
    ]
    
    static let debitCardColors: [[Color]] = [
        [Color(red: 0.1, green: 0.4, blue: 0.8), Color(red: 0.3, green: 0.6, blue: 1.0)], // Blue
        [Color(red: 0.0, green: 0.6, blue: 0.6), Color(red: 0.2, green: 0.8, blue: 0.8)], // Teal
        [Color(red: 0.1, green: 0.7, blue: 0.5), Color(red: 0.3, green: 0.9, blue: 0.6)], // Green
        [Color(red: 0.05, green: 0.2, blue: 0.4), Color(red: 0.2, green: 0.4, blue: 0.6)], // Navy
        [Color(red: 0.3, green: 0.5, blue: 0.9), Color(red: 0.5, green: 0.7, blue: 1.0)]  // Light Blue
    ]
    
    static func getColors(for type: CardType, index: Int) -> [Color] {
        let palette = type == .credit ? creditCardColors : debitCardColors
        let safeIndex = max(0, min(index, palette.count - 1))
        return palette[safeIndex]
    }
}

// MARK: - Main Cards View
struct CardsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var cardsService: CardsService
    @ObservedObject var friendsService: FriendsService
    @ObservedObject var notificationService: NotificationService
    let userId: String
    let userName: String?
    
    @State private var showingAddCard = false
    @State private var selectedCardToEdit: CardModel?
    @State private var showingDeleteAlert = false
    @State private var cardToDeleteId: String?
    @State private var hasAppeared = false
    @State private var showingShareSheet = false
    @State private var showingFriendSelection = false
    @State private var cardToShare: CardModel?
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
                        .font(.system(size: 24, weight: .bold))
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
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 0) { // Set spacing to 0, handle via padding in item
                                    ForEach(debitCards) { card in
                                        GeometryReader { geo in
                                            let minX = geo.frame(in: .global).minX
                                            let width = UIScreen.main.bounds.width
                                            // Calculate blur: 0 at approx 20px (left padding), increasing as it moves right
                                            let offset = minX - 20 
                                            // If offset is < 0 (scrolled slightly left), we also blur.
                                            // Normalize roughly: 0 -> 0 blur. Width -> 10 blur.
                                            let blurAmount =  min(max(abs(offset) / (width * 0.4) * 2.5, 0), 3) // Cap at 3 for subtler effect
                                            
                                            CardView(card: card, onEdit: {
                                                selectedCardToEdit = card
                                            }, onDelete: {
                                                cardToDeleteId = card.id
                                                showingDeleteAlert = true
                                            }, onShare: {
                                                cardToShare = card
                                                showingFriendSelection = true
                                            }, onCopy: { message in
                                                toastMessage = message
                                                toastType = .success
                                            })
                                            .blur(radius: blurAmount)
                                            .scaleEffect(blurAmount > 1 ? 0.95 : 1.0) // Subtle scale down
                                            .animation(.spring(), value: blurAmount)
                                        }
                                        .frame(width: UIScreen.main.bounds.width * 0.85, height: 210) // Fixed height including padding
                                        .padding(.trailing, 15) // Spacing handled here
                                    }
                                }
                                .padding(.horizontal, 20) // Initial padding
                                .padding(.bottom, 10)
                            }

                        }
                        
                        let creditCards = cardsService.cards.filter { $0.type == .credit }
                        if !creditCards.isEmpty {
                            SectionHeader(title: "Credit Cards", count: creditCards.count)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 0) {
                                    ForEach(creditCards) { card in
                                        GeometryReader { geo in
                                            let minX = geo.frame(in: .global).minX
                                            let width = UIScreen.main.bounds.width
                                            let offset = minX - 20
                                            let blurAmount = min(max(abs(offset) / (width * 0.4) * 2.5, 0), 3) // Cap at 3
                                            
                                            CardView(card: card, onEdit: {
                                                selectedCardToEdit = card
                                            }, onDelete: {
                                                cardToDeleteId = card.id
                                                showingDeleteAlert = true
                                            }, onShare: {
                                                cardToShare = card
                                                showingFriendSelection = true
                                            }, onCopy: { message in
                                                toastMessage = message
                                                toastType = .success
                                            })
                                            .blur(radius: blurAmount)
                                            .scaleEffect(blurAmount > 1 ? 0.95 : 1.0)
                                            .animation(.spring(), value: blurAmount)
                                        }
                                        .frame(width: UIScreen.main.bounds.width * 0.85, height: 210)
                                        .padding(.trailing, 15)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 10)
                            }

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
                        FabMenuRow(title: "Credit Card", icon: "creditcard.fill", colors: [Color(red: 0.29, green: 0.0, blue: 0.88), Color(red: 0.56, green: 0.18, blue: 0.89)])
                    }
                    
                    Button(action: {
                        withAnimation {
                            showFabMenu = false
                            selectedNewCardType = .debit
                            showingAddCard = true
                        }
                    }) {
                        FabMenuRow(title: "Debit Card", icon: "creditcard", colors: [Color(red: 0.0, green: 0.38, blue: 0.9), Color(red: 0.2, green: 0.68, blue: 1.0)])
                    }
                    
                    Spacer().frame(height: 80) // Space for close button
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // FAB Button (Center Bottom)
            if !cardsService.cards.isEmpty && !showingAddCard && !showingDeleteAlert && !showingFriendSelection && selectedCardToEdit == nil {
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
            
            // Friend Selection Sheet (Same sheet for both debit and credit cards)
            if showingFriendSelection {
                FriendSelectionSheet(
                    friends: friendsService.friends,
                    onShare: { friend in
                        if let card = cardToShare {
                            cardsService.shareCard(userId: userId, card: card, friendId: friend.id, notificationService: notificationService) { success, error in
                                DispatchQueue.main.async {
                                    if success {
                                        toastMessage = "Card shared with \(friend.name)"
                                        toastType = .success
                                    } else {
                                        toastMessage = "Failed to share: \(error ?? "Unknown")"
                                        toastType = .error
                                    }
                                }
                            }
                        }
                    },
                    isPresented: $showingFriendSelection,
                    sharingTitle: cardToShare.map { $0.type.rawValue } ?? "Card"
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

            AddEditCardView(isPresented: $showingAddCard, cardType: selectedNewCardType, card: nil as CardModel?, userId: userId, userName: userName, cardsService: cardsService, notificationService: notificationService) { message in
                toastMessage = message
                toastType = .success
            }
        }
        .sheet(item: $selectedCardToEdit) { card in
            AddEditCardView(isPresented: Binding(
                get: { selectedCardToEdit != nil },
                set: { if !$0 { selectedCardToEdit = nil } }
            ), card: card, userId: userId, userName: userName, cardsService: cardsService, notificationService: notificationService) { message in
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
                .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2)) // Explicitly set dark color
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
                    if card.isShared {
                        Text("SHARED")
                           .font(.caption2)
                           .fontWeight(.bold)
                           .foregroundColor(.white)
                           .padding(4)
                           .background(Color.black.opacity(0.3))
                           .cornerRadius(4)
                    } else {
                        HStack(spacing: 10) {
                            CircleButton(icon: "pencil", action: onEdit)
                            CircleButton(icon: "trash", action: onDelete)
                            CircleButton(icon: "square.and.arrow.up", action: onShare)
                        }
                    }
                    
                    Spacer()
                    
                    if !getCardBrand(number: card.cardNumber).isEmpty {
                        Text(getCardBrand(number: card.cardNumber))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(5)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(5)
                    }
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
    
    // Focus State
    enum Field: Hashable {
        case name, number, holder, expiry, cvv
    }
    @FocusState private var focusedField: Field?
    
    var card: CardModel? // If nil, adding mode
    let userId: String
    let cardsService: CardsService
    let notificationService: NotificationService
    var onSuccess: ((String) -> Void)?
    let accountName: String?
    @State private var isLoading = false
    
    // Distinct Palettes

    
    @State private var selectedColorIndex: Int = 0
    @State private var hasAppeared = false

    init(isPresented: Binding<Bool>, cardType: CardType = .debit, card: CardModel?, userId: String, userName: String?, cardsService: CardsService, notificationService: NotificationService, onSuccess: ((String) -> Void)? = nil) {
        self._isPresented = isPresented
        self.card = card
        self.userId = userId
        self.accountName = userName
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
            _selectedColorIndex = State(initialValue: existingCard.colorIndex ?? 0)
        } else {
            _cardType = State(initialValue: cardType)
            // Pre-fill card holder with account name
            _cardHolder = State(initialValue: userName ?? "")
            // Auto-select random color from appropriate palette
            if cardType == .credit {
                _selectedColorIndex = State(initialValue: Int.random(in: 0..<5))
            } else {
                _selectedColorIndex = State(initialValue: Int.random(in: 0..<5))
            }
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
            
            ScrollViewReader { scrollProxy in // START ScrollViewReader
            ScrollView {
                VStack(spacing: 20) {
                // ID for scrolling
                Color.clear.frame(height: 1).id("Top")
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
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                    Spacer()
                    #if os(iOS)
                    if #available(iOS 16.0, *) {
                        /*
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
                        */
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
                    let colors = CardModel.getColors(for: cardType, index: selectedColorIndex)
                    LinearGradient(gradient: Gradient(colors: colors), startPoint: .leading, endPoint: .trailing)
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
                        // Card Name
                        buildTextField(title: "Card Name", placeholder: "e.g., Personal Visa", text: $cardName, field: .name, nextField: .number)
                            .onChange(of: cardName) { newValue in
                                var filtered = newValue.filter { $0.isLetter || $0.isWhitespace || $0 == "-" }
                                if filtered.count > 30 {
                                    filtered = String(filtered.prefix(30))
                                }
                                if filtered != newValue {
                                    cardName = filtered
                                }
                            }
                        
                        // Card Number (Use numberPad)
                        buildTextField(title: "Card Number", placeholder: "0000 0000 0000 0000", text: $cardNumber, field: .number, nextField: .holder, keyboardType: .numberPad)
                            .onChange(of: cardNumber) { newValue in
                                formatCardNumber(newValue)
                            }
                            
                        // Card Holder
                        buildTextField(title: "Card Holder Name", placeholder: "New User", text: $cardHolder, field: .holder, nextField: .expiry)
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
                             // Expiry
                             buildTextField(title: "Expiry Date", placeholder: "MM/YY", text: $expiry, field: .expiry, nextField: .cvv, keyboardType: .numberPad)
                                .onChange(of: expiry) { newValue in
                                    formatExpiry(newValue)
                                }
                            Spacer()
                             // CVV
                             buildTextField(title: "CVV", placeholder: "123", text: $cvv, field: .cvv, nextField: nil, isSecure: true, keyboardType: .numberPad)
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
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: CardModel.getColors(for: cardType, index: selectedColorIndex)),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .padding(.horizontal)
                }
                .disabled(cardName.isEmpty || cardNumber.isEmpty || cardHolder.isEmpty || expiry.isEmpty || cvv.isEmpty || isLoading)
                .opacity((cardName.isEmpty || cardNumber.isEmpty || cardHolder.isEmpty || expiry.isEmpty || cvv.isEmpty || isLoading) ? 0.6 : 1)
                .padding(.bottom, focusedField != nil ? 320 : 20)
                
                Spacer()
            }
        }
        /*
        .sheet(isPresented: $showingScanner) {
            #if os(iOS)
            if #available(iOS 16.0, *) {
                CardScannerView(isPresented: $showingScanner) { number, expiry, name in
                    self.cardNumber = number
                    if let exp = expiry {
                        self.expiry = exp
                    }
                    // Name extraction available but not used currently
                    _ = name
                }
            }
            #endif
        }
        */
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
        )
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    withAnimation { scrollProxy.scrollTo("Top", anchor: .top) }
                }
                Spacer()
            }
        }
    } // End ScrollViewReader
    } // End ZStack
    } // End body
    
    func saveCard() {
        isLoading = true
        // Get colors based on index
        let colors = CardModel.getColors(for: cardType, index: selectedColorIndex)
        
        let newCard = CardModel(
            id: card?.id ?? UUID().uuidString,
            type: cardType,
            cardName: cardName,
            cardNumber: cardNumber,
            cardHolder: cardHolder,
            expiry: expiry,
            cvv: cvv,
            colorStart: colors[0],
            colorEnd: colors[1],
            colorIndex: selectedColorIndex
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
         return CardModel.getColors(for: type, index: 0)
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
    
    // Check if we need to implement buildTextField logic
    @ViewBuilder
    private func buildTextField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        field: Field,
        nextField: Field?,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .foregroundColor(.black)
            
            ZStack(alignment: .leading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .foregroundColor(Color(red: 0.8, green: 0.8, blue: 0.8)) // Explicit placeholder color
                        .padding(.horizontal)
                        .padding(.vertical, 12) // Approximate padding to match TextField
                }
                
                if isSecure {
                    SecureField("", text: text) // Empty string for native placeholder
                        .focused($focusedField, equals: field)
                        .submitLabel(nextField == nil ? .done : .next)
                        .onSubmit {
                            if let next = nextField {
                                focusedField = next
                            } else {
                                focusedField = nil
                            }
                        }
                        .keyboardType(keyboardType)
                        .padding()
                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                        .background(Color.clear) // Clear background for field, background is on ZStack/Container if needed, or we keep it here but standard z-ordering
                } else {
                    TextField("", text: text) // Empty string for native placeholder
                        .focused($focusedField, equals: field)
                        .submitLabel(nextField == nil ? .done : .next)
                        .onSubmit {
                            if let next = nextField {
                                focusedField = next
                            } else {
                                focusedField = nil
                            }
                        }
                        .keyboardType(keyboardType)
                        .padding()
                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                        .background(Color.clear)
                }
            }
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
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
            
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(Color(red: 0.8, green: 0.8, blue: 0.8)) // Explicit placeholder color
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                }
                
                if isSecure {
                    SecureField("", text: $text)
                        .applyKeyboardType(keyboardType)
                        .padding()
                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                        .background(Color.clear)
                } else {
                    TextField("", text: $text)
                        .applyKeyboardType(keyboardType)
                        .padding()
                        .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                        .background(Color.clear)
                }
            }
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
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
    
    // Visa: Starts with 4
    if cleanNumber.hasPrefix("4") { return "VISA" }
    
    // Amex: Starts with 34 or 37
    if cleanNumber.hasPrefix("34") || cleanNumber.hasPrefix("37") { return "AMEX" }
    
    // Mastercard: 51-55 or 2221-2720
    if cleanNumber.hasPrefix("51") || cleanNumber.hasPrefix("52") || cleanNumber.hasPrefix("53") || cleanNumber.hasPrefix("54") || cleanNumber.hasPrefix("55") {
        return "MASTERCARD"
    }
    
    // Mastercard 2-series (2221-2720)
    if cleanNumber.hasPrefix("2") {
        if cleanNumber.count >= 2 {
            let prefix2 = Int(cleanNumber.prefix(2)) ?? 0
            if prefix2 >= 22 && prefix2 <= 27 {
                // More precise check if enough digits
                if cleanNumber.count >= 4 {
                    let prefix4 = Int(cleanNumber.prefix(4)) ?? 0
                    if prefix4 >= 2221 && prefix4 <= 2720 { return "MASTERCARD" }
                } else {
                    // If only 2 or 3 digits, we show it if it's in range
                    return "MASTERCARD"
                }
            }
        }
    }
    
    // RuPay: Very broad range in India
    // Common prefixes: 60, 65, 81, 82, 508, 353, 356
    // Also 6061-6085 range is common for RuPay
    let ruPayPrefixes = ["60", "65", "81", "82", "508", "353", "356"]
    for prefix in ruPayPrefixes {
        if cleanNumber.hasPrefix(prefix) { return "RUPAY" }
    }
    
    // Additional RuPay 6-digit BIN check if available
    if cleanNumber.count >= 6 {
        let prefix6 = Int(cleanNumber.prefix(6)) ?? 0
        if (prefix6 >= 606100 && prefix6 <= 608599) || (prefix6 >= 652150 && prefix6 <= 653149) {
            return "RUPAY"
        }
    }

    // Generic RuPay starts with 6
    if cleanNumber.hasPrefix("6") && !cleanNumber.hasPrefix("60") && !cleanNumber.hasPrefix("65") {
        // Many RuPay cards start with 6. If not Visa (4) or MC (5), and starts with 6/5/8...
        // But 6 is also used by Discover/Maestro. In India, 6 is heavily RuPay.
        return "RUPAY" 
    }
    
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
                        if let extractedName = extractCardholderName(from: textContent) {
                            scannedName = extractedName
                            print("📱 CardScanner: Found name: \(extractedName)")
                        }
                    }
                    
                case .barcode(let barcode):
                    // Handle barcode if needed
                    print("📱 CardScanner: Scanned barcode: \(barcode.payloadStringValue ?? "Unknown")")
                    
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
