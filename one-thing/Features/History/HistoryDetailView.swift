import SwiftUI

/// 履歴で選択した 1 日の内容表示と編集を行うシート。
struct HistoryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var status: ThingStatus

    let dateText: String
    let day: HistoryCalendarDay
    let isSaving: Bool
    let errorMessage: String?
    let save: (Date, String, ThingStatus) async -> Bool

    /// 表示対象の日付データと保存処理を受け取る。
    init(
        dateText: String,
        day: HistoryCalendarDay,
        isSaving: Bool,
        errorMessage: String?,
        save: @escaping (Date, String, ThingStatus) async -> Bool
    ) {
        self.dateText = dateText
        self.day = day
        self.isSaving = isSaving
        self.errorMessage = errorMessage
        self.save = save
        _title = State(initialValue: day.thing?.title ?? "")
        _status = State(initialValue: Self.editableStatus(for: day.thing?.status))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                header
                formContent
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(24)
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("日次詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        Task {
                            await saveHistory()
                        }
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text(dateText)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(Color.appPrimary)

            Text(resultText(for: day.thing?.status))
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(Color.appSecondary)
        }
    }

    private var formContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("やったこと")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.appPrimary)

                TextField("記録なし", text: $title, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(Color.appPrimary)
                    .padding(14)
                    .background(Color.white.opacity(0.72))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .disabled(day.thing == nil)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("結果")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.appPrimary)

                Picker("結果", selection: $status) {
                    Text("できた").tag(ThingStatus.done)
                    Text("休んだ").tag(ThingStatus.rested)
                }
                .pickerStyle(.segmented)
                .disabled(day.thing == nil)
            }

            if day.thing == nil {
                Text("この日はまだ編集できる記録がありません。")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(Color.appSecondary)
            } else if let errorMessage {
                Text(errorMessage)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(Color.appAccent)
            }
        }
    }

    private var canSave: Bool {
        day.date != nil
            && day.thing != nil
            && !trimmedTitle.isEmpty
            && !isSaving
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func saveHistory() async {
        guard let date = day.date, canSave else {
            return
        }

        if await save(date, trimmedTitle, status) {
            dismiss()
        }
    }

    private func resultText(for status: ThingStatus?) -> String {
        switch status {
        case .done:
            return "できた"
        case .rested:
            return "休んだ"
        default:
            return "記録なし"
        }
    }

    private static func editableStatus(for status: ThingStatus?) -> ThingStatus {
        status == .done ? .done : .rested
    }
}

#Preview {
    HistoryDetailView(
        dateText: "5月8日 (金)",
        day: HistoryCalendarDay(
            date: Date(),
            dayNumber: 8,
            thing: Thing(title: "散歩する", status: .done),
            isToday: true,
            isFuture: false
        ),
        isSaving: false,
        errorMessage: nil,
        save: { _, _, _ in true }
    )
}
