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
                                        gradient: LinearGradient(colors: [Color.blue, Color(red: 0.3, green: 0.5, blue: 1.0)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                        icon: "folder.fill"
                                    )
                                    PremiumCard(
                                        title: "Secure Sharing",
                                        description: "Share documents with time-limited links. Control exactly who sees what.",
                                        gradient: LinearGradient(colors: [Color(red: 0.0, green: 0.7, blue: 0.6), Color(red: 0.0, green: 0.5, blue: 0.4)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                        icon: "link"
                                    )
                                    PremiumCard(
                                        title: "Wallet Cards",
                                        description: "Save your Debit & Credit cards securely. Copy details with a single tap.",
                                        gradient: LinearGradient(colors: [Color(red: 0.5, green: 0.3, blue: 1.0), Color(red: 0.3, green: 0.2, blue: 0.9)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                        icon: "creditcard.fill"
                                    )
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 30) // Add ample vertical padding for shadows and size
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
    let gradient: LinearGradient
    let icon: String
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Background with Gradient
            RoundedRectangle(cornerRadius: 25)
                .fill(gradient)
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 8)
            
            // Decorative background circles
            GeometryReader { geometry in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .offset(x: geometry.size.width - 100, y: -50)
                
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 150, height: 150)
                    .offset(x: geometry.size.width - 50, y: 80)
            }
            .clipShape(RoundedRectangle(cornerRadius: 25))
            
            VStack(alignment: .leading, spacing: 15) {
                // Header Icon
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 40, height: 40)
                        Image(systemName: icon)
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(3)
                }
                
                Spacer()
                
                // Detailed Visual at the bottom
                HStack {
                    Spacer()
                    if title == "Folder Organization" {
                        // Stacked folders
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 60, height: 40)
                                .rotationEffect(.degrees(-10))
                                .offset(x: -10, y: -5)
                            
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.5))
                                .frame(width: 65, height: 45)
                                .rotationEffect(.degrees(-5))
                                .offset(x: -5, y: -2)
                            
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white)
                                .frame(width: 70, height: 50)
                                .overlay(
                                    Image(systemName: "folder.fill")
                                        .foregroundColor(Color.blue.opacity(0.8))
                                )
                        }
                        .offset(x: 10, y: 10)
                        
                    } else if title == "Secure Sharing" {
                        // Connected dots
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.4))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "link")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(45))
                        }
                        .offset(x: 10, y: 10)
                        
                    } else {
                        // Credit Card
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 80, height: 50)
                                .rotationEffect(.degrees(-15))
                                .offset(x: -15, y: -5)
                            
                            RoundedRectangle(cornerRadius: 6)
                                .fill(LinearGradient(colors: [.white, .white.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 80, height: 50)
                                .rotationEffect(.degrees(-5))
                                .shadow(radius: 5)
                                .overlay(
                                    VStack(alignment: .leading, spacing: 4) {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.black.opacity(0.1))
                                            .frame(width: 15, height: 10)
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.black.opacity(0.05))
                                            .frame(width: 40, height: 4)
                                        Spacer()
                                    }
                                    .padding(6)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                )
                        }
                        .offset(x: 15, y: 10)
                    }
                }
            }
            .padding(25)
        }
        .frame(width: 280, height: 200) // Slightly wider and taller feel
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
