import SwiftUI

/// 設定シートの入口となる画面。
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Color.appBackground
                .ignoresSafeArea()
                .navigationTitle("設定")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("閉じる") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

#Preview {
    SettingsView()
}
