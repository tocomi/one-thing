import SwiftUI

/// タスク入力・編集で共通して使うテキストフィールド。
/// プレースホルダーは仕様上表示しないため、VoiceOver 向けのラベルだけを受け取る。
struct ThingTextField: View {
    let accessibilityLabel: String
    @Binding var text: String
    let maxWidth: CGFloat
    @FocusState private var isFocused: Bool

    /// VoiceOver 用のラベルと入力内容を受け取る。
    /// `maxWidth` はホームの中央寄せレイアウトに合わせた既定値を持ち、
    /// 幅いっぱいに広げたい画面では `.infinity` を渡す。
    init(
        accessibilityLabel: String,
        text: Binding<String>,
        maxWidth: CGFloat = 360
    ) {
        self.accessibilityLabel = accessibilityLabel
        _text = text
        self.maxWidth = maxWidth
    }

    var body: some View {
        // 空文字のタイトルにするとプレースホルダーは出ないが VoiceOver も無名になるため、
        // ラベルは accessibilityLabel で別に与える。
        TextField("", text: $text, axis: .vertical)
            .font(.system(size: 19, weight: .medium, design: .rounded))
            .foregroundStyle(Color.appPrimary)
            .tint(Color.appAccent)
            .textFieldStyle(.plain)
            .submitLabel(.done)
            .lineLimit(1...3)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 18)
            .padding(.vertical, 15)
            .frame(maxWidth: maxWidth, minHeight: 58, alignment: .topLeading)
            .focused($isFocused)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.appSurface)
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.appBorder, lineWidth: 1.5)
                    }
            }
            .accessibilityLabel(accessibilityLabel)
            .onSubmit {
                isFocused = false
            }
            .onChange(of: text) { _, newValue in
                guard newValue.contains("\n") else {
                    return
                }

                text = newValue.replacingOccurrences(of: "\n", with: "")
                isFocused = false
            }
    }
}

#Preview {
    @Previewable @State var text = ""

    ThingTextField(accessibilityLabel: "今日やること", text: $text)
        .padding(32)
        .background(Color.appBackground)
}
