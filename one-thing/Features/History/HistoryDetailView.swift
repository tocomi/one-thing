import SwiftUI

/// 履歴で選択した 1 日の内容表示と編集を行うシート。
struct HistoryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var status: ThingStatus
    @State private var isDeleteConfirmationPresented = false

    let dateText: String
    let day: HistoryCalendarDay
    let isSaving: Bool
    let errorMessage: String?
    let save: (Date, String, ThingStatus) async -> Bool
    let delete: (Date) async -> Bool

    /// 表示対象の日付データと保存処理を受け取る。
    init(
        dateText: String,
        day: HistoryCalendarDay,
        isSaving: Bool,
        errorMessage: String?,
        save: @escaping (Date, String, ThingStatus) async -> Bool,
        delete: @escaping (Date) async -> Bool
    ) {
        self.dateText = dateText
        self.day = day
        self.isSaving = isSaving
        self.errorMessage = errorMessage
        self.save = save
        self.delete = delete
        _title = State(initialValue: day.thing?.title ?? "")
        _status = State(initialValue: Self.editableStatus(for: day.thing?.status))
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                header
                    .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 18) {
                    HistoryDetailFormView(title: $title, status: $status)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(Color.appAccent)
                    }

                    if canDelete {
                        deleteButton
                    }
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(24)
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("日次詳細")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog(
                "この日の記録を削除しますか？",
                isPresented: $isDeleteConfirmationPresented,
                titleVisibility: .visible
            ) {
                Button("削除", role: .destructive) {
                    Task {
                        await deleteHistory()
                    }
                }

                Button("キャンセル", role: .cancel) {}
            }
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

    private var deleteButton: some View {
        Button(role: .destructive) {
            isDeleteConfirmationPresented = true
        } label: {
            Label("この日の記録を削除", systemImage: "trash")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(Color.appAccent)
        .disabled(isSaving)
    }

    private var canSave: Bool {
        day.date != nil
            && !trimmedTitle.isEmpty
            && !isSaving
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canDelete: Bool {
        day.date != nil && day.thing != nil
    }

    private func saveHistory() async {
        guard let date = day.date, canSave else {
            return
        }

        if await save(date, trimmedTitle, status) {
            dismiss()
        }
    }

    private func deleteHistory() async {
        guard let date = day.date, canDelete, !isSaving else {
            return
        }

        if await delete(date) {
            dismiss()
        }
    }

    private func resultText(for status: ThingStatus?) -> String {
        switch status {
        case .done:
            "できた"
        case .rested:
            "休んだ"
        default:
            "記録なし"
        }
    }

    private static func editableStatus(for status: ThingStatus?) -> ThingStatus {
        status == .done ? .done : .rested
    }
}

#if DEBUG
/// Preview で使う「今日」のセル。日付・曜日・`isToday` を固定した現在時刻に合わせる。
private func previewTodayCell(thing: ThingSnapshot?) -> HistoryCalendarDay {
    HistoryCalendarDay(
        date: PreviewClock.today,
        dayNumber: PreviewClock.calendar.component(.day, from: PreviewClock.today),
        thing: thing,
        isToday: true,
        isFuture: false
    )
}

#Preview("記録あり") {
    HistoryDetailView(
        dateText: PreviewClock.dayText(for: PreviewClock.today),
        day: previewTodayCell(thing: ThingSnapshot(title: "散歩する", status: .done)),
        isSaving: false,
        errorMessage: nil,
        save: { _, _, _ in true },
        delete: { _ in true }
    )
}

#Preview("記録なし") {
    let date = PreviewClock.daysAgo(4)

    HistoryDetailView(
        dateText: PreviewClock.dayText(for: date),
        day: HistoryCalendarDay(
            date: date,
            dayNumber: PreviewClock.calendar.component(.day, from: date),
            thing: nil,
            isToday: false,
            isFuture: false
        ),
        isSaving: false,
        errorMessage: nil,
        save: { _, _, _ in true },
        delete: { _ in true }
    )
}

#Preview("保存エラー") {
    HistoryDetailView(
        dateText: PreviewClock.dayText(for: PreviewClock.today),
        day: previewTodayCell(thing: ThingSnapshot(title: "散歩する", status: .done)),
        isSaving: false,
        errorMessage: "やったことを入力してください。",
        save: { _, _, _ in false },
        delete: { _ in false }
    )
}

#Preview("保存中") {
    HistoryDetailView(
        dateText: PreviewClock.dayText(for: PreviewClock.today),
        day: previewTodayCell(thing: ThingSnapshot(title: "散歩する", status: .done)),
        isSaving: true,
        errorMessage: nil,
        save: { _, _, _ in true },
        delete: { _ in true }
    )
}
#endif
