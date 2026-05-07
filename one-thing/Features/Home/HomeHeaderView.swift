import SwiftUI

/// ホーム画面上部に履歴と設定への操作を配置するヘッダー。
struct HomeHeaderView: View {
    @Binding var isHistoryPresented: Bool
    @Binding var isSettingsPresented: Bool

    var body: some View {
        VStack {
            HStack {
                headerButton(
                    systemName: "gearshape",
                    accessibilityLabel: "設定"
                ) {
                    isSettingsPresented = true
                }

                Spacer()

                headerButton(
                    systemName: "calendar",
                    accessibilityLabel: "これまで"
                ) {
                    isHistoryPresented = true
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    /// アイコンだけで表現するヘッダー操作ボタンを作る。
    private func headerButton(
        systemName: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Color.appSecondary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

#Preview {
    HomeHeaderView(
        isHistoryPresented: .constant(false),
        isSettingsPresented: .constant(false)
    )
}
