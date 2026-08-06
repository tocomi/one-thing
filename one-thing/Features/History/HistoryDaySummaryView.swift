import SwiftUI

/// カレンダーから選んだ日の記録を読み取り専用で表示する。
/// 履歴で編集できるのは過去の日だけのため、今日を選んだときはこの表示になる。
struct HistoryDaySummaryView: View {
    @Environment(\.dismiss) private var dismiss
    let dateText: String
    let thing: ThingSnapshot?

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Text(dateText)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.appPrimary)

                VStack(spacing: 10) {
                    Text(resultText)
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(Color.appPrimary)

                    if let thing {
                        Text(thing.title)
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(Color.appPrimary)
                            .multilineTextAlignment(.center)
                    }
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(32)
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("日次詳細")
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

    private var resultText: String {
        HistoryResultText.text(for: thing?.status)
    }
}

#if DEBUG
#Preview("今日・できた") {
    HistoryDaySummaryView(
        dateText: PreviewClock.dayText(for: PreviewClock.today),
        thing: ThingSnapshot(title: "散歩する", status: .done)
    )
}

#Preview("今日・進行中") {
    HistoryDaySummaryView(
        dateText: PreviewClock.dayText(for: PreviewClock.today),
        thing: ThingSnapshot(title: "散歩する", status: .inProgress)
    )
}

#Preview("記録なし") {
    HistoryDaySummaryView(
        dateText: PreviewClock.dayText(for: PreviewClock.today),
        thing: nil
    )
}
#endif
