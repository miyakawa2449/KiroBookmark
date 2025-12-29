//
//  ToastView.swift
//  KiroBookmark
//
//  Toast notification view for user feedback
//

import SwiftUI

/// Toast notification view
struct ToastView: View {
    let message: String
    let type: ToastType
    let onDismiss: () -> Void

    enum ToastType {
        case success
        case error
        case info

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "exclamationmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }

        var backgroundColor: Color {
            switch self {
            case .success: return Color.green
            case .error: return Color.red
            case .info: return Color.blue
            }
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.system(size: 20))
                .foregroundColor(.white)

            Text(message)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(2)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(type.backgroundColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

/// Toast modifier for easy integration
struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    let type: ToastView.ToastType
    let duration: TimeInterval

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content

            if isPresented {
                VStack {
                    ToastView(
                        message: message,
                        type: type,
                        onDismiss: { isPresented = false }
                    )
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        // Auto dismiss after duration
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            withAnimation {
                                isPresented = false
                            }
                        }
                    }
                    .onTapGesture {
                        withAnimation {
                            isPresented = false
                        }
                    }

                    Spacer()
                }
                .zIndex(999)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPresented)
    }
}

extension View {
    /// Show toast notification
    /// - Parameters:
    ///   - isPresented: Binding to control visibility
    ///   - message: Message to display
    ///   - type: Toast type (success, error, info)
    ///   - duration: Auto-dismiss duration (default: 3 seconds)
    func toast(
        isPresented: Binding<Bool>,
        message: String,
        type: ToastView.ToastType = .success,
        duration: TimeInterval = 3.0
    ) -> some View {
        modifier(ToastModifier(
            isPresented: isPresented,
            message: message,
            type: type,
            duration: duration
        ))
    }
}

// MARK: - Preview

#Preview {
    VStack {
        ToastView(
            message: "ブックマークに登録しました",
            type: .success,
            onDismiss: {}
        )

        ToastView(
            message: "ブックマークの追加に失敗しました",
            type: .error,
            onDismiss: {}
        )

        ToastView(
            message: "お知らせがあります",
            type: .info,
            onDismiss: {}
        )
    }
    .padding()
}
