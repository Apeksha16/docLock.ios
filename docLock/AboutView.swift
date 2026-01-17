import SwiftUI

struct AboutView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.98, blue: 0.98) // White background
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                // Header
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20))
                            .foregroundColor(.black)
                            .padding(10)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    
                    Spacer()
                    
                    Text("About")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    // Empty view to balance layout
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        
                        // Hero Section
                        VStack(spacing: 15) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.05))
                                    .frame(width: 120, height: 120)
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 80, height: 80)
                                    .shadow(color: Color.blue.opacity(0.1), radius: 10, x: 0, y: 5)
                                Image(systemName: "lock.open")
                                    .font(.system(size: 30))
                                    .foregroundColor(.blue)
                            }
                            
                            VStack(spacing: 5) {
                                Text("Secure. Smart.")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                                Text("Simple.")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                            
                            Text("Your personal digital fortress. Military-grade\nencryption meets beautiful design.")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                        }
                        
                        // Why DocLock? Grid
                        VStack(alignment: .leading, spacing: 15) {
                            Text("WHY DOCLOCK?")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity, alignment: .center)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    FeatureGridItem(icon: "shield.fill", color: .green, title: "Bank-Grade\nSecurity", description: "AES-256 encryption ensures your data is yours alone.")
                                    FeatureGridItem(icon: "bolt.fill", color: .orange, title: "Instant Access", description: "Find any document in seconds with smart search.")
                                    FeatureGridItem(icon: "cloud.fill", color: .blue, title: "Cloud Sync", description: "Access your files from any device, anywhere.")
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Premium Features - Horizontal Scroll
                        VStack(alignment: .leading, spacing: 15) {
                            Text("PREMIUM FEATURES")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity, alignment: .center)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    PremiumCard(
                                        title: "Folder Organization",
                                        description: "Efficient categorization for your files. Store IDs, Meds, and more.",
                                        color: .blue,
                                        icon: "folder"
                                    )
                                    PremiumCard(
                                        title: "Secure Sharing",
                                        description: "Share documents with time-limited links. Control exactly who sees what.",
                                        color: Color(red: 0.0, green: 0.6, blue: 0.5), // Teal
                                        icon: "square.and.arrow.up"
                                    )
                                    PremiumCard(
                                        title: "Wallet Cards",
                                        description: "Save your Debit & Credit cards securely. Copy details with a single tap.",
                                        color: Color(red: 0.4, green: 0.3, blue: 1.0), // Purple
                                        icon: "creditcard"
                                    )
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Pro Tips
                        VStack(alignment: .leading, spacing: 20) {
                            Text("PRO TIPS")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity, alignment: .center)
                            
                            VStack(alignment: .leading, spacing: 15) {
                                ProTipRow(title: "Quick Add", description: "Use the floating action button (+) to instantly upload documents or add cards.")
                                ProTipRow(title: "Offline Access", description: "Your cards are cached locally so you can access them even without internet.")
                                ProTipRow(title: "Secure Profile", description: "Update your M-PIN regularly in settings to keep your fortress impenetrable.")
                            }
                            .padding(.horizontal)
                        }
                        
                        // Footer
                        VStack(spacing: 5) {
                            Text("Designed by Apeksha Verma")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                                .overlay(
                                    // Make "Apeksha Verma" pink? A simple color overlay trick or attributed string if needed.
                                    // For now simple text.
                                    GeometryReader { g in
                                       // keeping it simple
                                    }
                                )
                            
                            Text("Developed & Architected by Pranav Katiyar")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 20)
                        
                        Spacer().frame(height: 50)
                    }
                }
            }
        }
    }
}

// Components

struct FeatureGridItem: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(color)
                    .frame(width: 50, height: 50)
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                .fixedSize(horizontal: false, vertical: true)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(4)
            
            Spacer(minLength: 0)
        }
        .padding()
        .frame(width: 160, height: 220, alignment: .leading)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

struct PremiumCard: View {
    let title: String
    let description: String
    let color: Color
    let icon: String
    
    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(color)
            
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                // Placeholder visual for card content (e.g. progress bar or card shape)
                HStack {
                    if title == "Folder Organization" || title == "Secure Sharing" {
                        // Creating a fake progress bar look
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 40)
                            .overlay(
                                HStack {
                                    Image(systemName: icon == "folder" ? "heart.fill" : "link.circle.fill")
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                .padding(.horizontal)
                            )
                    } else {
                        // Wallet Card look
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            .frame(width: 100, height: 60)
                            .rotationEffect(.degrees(-10))
                            .offset(x: 100, y: 0)
                    }
                }
            }
            .padding(25)
        }
        .frame(width: 300, height: 200)
    }
}

struct ProTipRow: View {
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.7)) // Mint
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.05, green: 0.07, blue: 0.2))
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
