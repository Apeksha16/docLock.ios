import SwiftUI

enum ToastType {
    case success
    case error
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        }
    }
}

struct ToastView: View {
    let message: String
    let type: ToastType
    @Binding var show: Bool
    
    var body: some View {
        VStack {
            if show {
                HStack(spacing: 12) {
                    // Icon
                    if type == .success {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, Color.blue)
                    } else {
                        Image(systemName: type.icon)
                            .font(.system(size: 24))
                            .foregroundColor(type.color)
                    }
                    
                    Text(message)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.95))
                .cornerRadius(40)
                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                .padding(.top, 55) // Adjusted for dynamic island position
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .top).combined(with: .scale(scale: 0.2, anchor: .top)),
                        removal: .opacity.combined(with: .scale(scale: 0.8, anchor: .top))
                    )
                )
            }
            Spacer()
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: show)
        .zIndex(1000) // Ensure it's on top
    }
}

struct ToastModifier: ViewModifier {
    @Binding var toastMessage: String?
    var toastType: ToastType = .error
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if let message = toastMessage {
                ToastView(
                    message: message,
                    type: toastType,
                    show: .constant(true)
                )
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        toastMessage = nil
                    }
                }
            }
        }
    }
}

extension View {
    func toast(message: Binding<String?>, type: ToastType = .error) -> some View {
        self.modifier(ToastModifier(toastMessage: message, toastType: type))
    }
}
