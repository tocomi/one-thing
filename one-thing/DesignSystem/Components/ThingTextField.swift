import SwiftUI

/// タスク入力・編集で共通して使うテキストフィールド。
struct ThingTextField: View {
    let placeholder: String
    @Binding var text: String
    let onSubmit: () -> Void

    var body: some View {
        TextField(placeholder, text: $text, axis: .vertical)
            .font(.system(size: 19, weight: .medium, design: .rounded))
            .foregroundStyle(Color.appPrimary)
            .tint(Color.appAccent)
            .textFieldStyle(.plain)
            .submitLabel(.done)
            .lineLimit(1...3)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 18)
            .padding(.vertical, 15)
            .frame(maxWidth: 360, minHeight: 58, alignment: .topLeading)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.appSurface)
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.appBorder, lineWidth: 1.5)
                    }
            }
            .onSubmit(onSubmit)
    }
}

#Preview {
    @Previewable @State var text = ""

    ThingTextField(placeholder: "今日やること...", text: $text) {}
        .padding(32)
        .background(Color.appBackground)
}
