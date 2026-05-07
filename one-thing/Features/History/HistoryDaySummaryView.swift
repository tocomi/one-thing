import SwiftUI

/// カレンダーから選んだ日の記録を読み取り専用で表示する。
struct HistoryDaySummaryView: View {
    @Environment(\.dismiss) private var dismiss
    let dateText: String
    let thing: Thing?

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

    private var resultText: String {
        switch thing?.status {
        case .done:
            return "できた"
        case .rested:
            return "休んだ"
        default:
            return "記録なし"
        }
    }
}

#Preview {
    HistoryDaySummaryView(
        dateText: "5月8日 (金)",
        thing: Thing(title: "散歩する", status: .done)
    )
}
