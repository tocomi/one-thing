import SwiftUI

/// アプリ内の主要アクションに使う共通ボタン。
struct PrimaryActionButton: View {
    let title: String
    let action: () -> Void

    /// タイトルと実行処理を持つ強調ボタンを描画する。
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
    }
}

#Preview {
    PrimaryActionButton(title: "Done") {}
        .padding()
}
