import SwiftUI

/// 履歴詳細の編集フォーム。やったことの入力と結果の選択をまとめる。
struct HistoryDetailFormView: View {
    @Binding var title: String
    @Binding var status: ThingStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HistoryDetailTitleField(title: $title)
            HistoryDetailResultPicker(status: $status)
        }
    }
}

/// やったことの入力欄。
private struct HistoryDetailTitleField: View {
    @Binding var title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HistoryDetailSectionLabel(text: "やったこと")

            ThingTextField(
                accessibilityLabel: "やったこと",
                text: $title,
                maxWidth: .infinity
            )
        }
    }
}

/// できた・休んだを切り替える結果の選択欄。
private struct HistoryDetailResultPicker: View {
    @Binding var status: ThingStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HistoryDetailSectionLabel(text: "結果")

            Picker("結果", selection: $status) {
                Text("できた").tag(ThingStatus.done)
                Text("休んだ").tag(ThingStatus.rested)
            }
            .pickerStyle(.segmented)
        }
    }
}

/// フォーム内の各セクションに付ける見出し。
private struct HistoryDetailSectionLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(.subheadline, design: .rounded, weight: .semibold))
            .foregroundStyle(Color.appPrimary)
    }
}

#Preview {
    @Previewable @State var title = ""
    @Previewable @State var status = ThingStatus.done

    HistoryDetailFormView(title: $title, status: $status)
        .padding(24)
        .background(Color.appBackground)
}
