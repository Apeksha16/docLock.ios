import SwiftUI

struct DashboardView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "folder.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                Text("Welcome to DocLock")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                Text("Your documents are safe here.")
                    .foregroundColor(.gray)
            }
            .navigationTitle("Dashboard")
        }
    }
}
