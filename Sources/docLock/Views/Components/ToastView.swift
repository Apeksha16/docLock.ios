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
            Spacer()
            
            if show {
                HStack(spacing: 12) {
                    Image(systemName: type.icon)
                        .font(.system(size: 20))
                        .foregroundColor(type.color)
                    
                    Text(message)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: show)
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
