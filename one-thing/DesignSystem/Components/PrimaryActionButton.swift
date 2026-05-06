import SwiftUI

/// アプリ内の主要アクションに使う共通ボタン。
struct PrimaryActionButton: View {
    let title: String
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(isEnabled ? 1.0 : 0.6))
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    Color.appAccent.opacity(isEnabled ? 1.0 : 0.35),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
        }
        .buttonStyle(SpringScaleButtonStyle())
    }
}

/// タップ時に軽く縮んでバネで戻るフィードバックを与えるスタイル。
private struct SpringScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.80 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(duration: 0.22, bounce: 0.3), value: configuration.isPressed)
    }
}

#Preview {
    PrimaryActionButton(title: "決めた！") {}
        .padding(32)
        .background(Color.appBackground)
}
