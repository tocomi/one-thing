import SwiftUI

/// 履歴シートの入口となる画面。
struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Color.appBackground
                .ignoresSafeArea()
                .navigationTitle("これまで")
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
    HistoryView()
}
