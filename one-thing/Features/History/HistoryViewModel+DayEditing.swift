import Foundation

/// 履歴シートのうち、選んだ 1 日の編集可否と保存・削除を担当する。
extension HistoryViewModel {
    /// 選んだ日を履歴から編集できるかどうかを返す。
    /// 編集できるのは過去の日だけで、今日と未来日は読み取り専用として扱う。
    func isEditable(_ day: HistoryCalendarDay) -> Bool {
        guard let date = day.date else {
            return false
        }

        return isEditableDate(date)
    }

    /// 選択中の日の履歴を保存し、その月のカレンダーを更新する。
    func saveHistoryDay(date: Date, title: String, status: ThingStatus) async -> Bool {
        guard isEditableDate(date) else {
            errorMessage = Self.notEditableMessage
            return false
        }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            let result = try await editHistoryUseCase.execute(
                date: calendar.startOfDay(for: date),
                title: title,
                status: status
            )
            await loadMonth(displayedMonth, force: true)
            selectedDay = days(for: displayedMonth)?.first {
                guard let dayDate = $0.date else {
                    return false
                }
                return calendar.isDate(dayDate, inSameDayAs: result.thing.date)
            }
            return true
        } catch {
            errorMessage = Self.historyErrorMessage(for: error)
            return false
        }
    }

    /// 選択中の日の履歴を削除し、その月のカレンダーを更新する。
    func deleteHistoryDay(date: Date) async -> Bool {
        guard isEditableDate(date) else {
            errorMessage = Self.notEditableMessage
            return false
        }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            try await deleteHistoryUseCase.execute(date: calendar.startOfDay(for: date))
            await loadMonth(displayedMonth, force: true)
            selectedDay = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// その日付が履歴の編集対象かどうかを判定する。
    /// 今日のことはホーム画面で扱うため、履歴が書き込むのはアプリ上の今日より前の日だけにする。
    private func isEditableDate(_ date: Date) -> Bool {
        calendar.startOfDay(for: date) < appToday()
    }

    /// 読み取り専用の日に書き込みを求められたときに出すメッセージ。
    private static let notEditableMessage = "今日のことは履歴から変更できません。"

    private static func historyErrorMessage(for error: Error) -> String {
        guard let error = error as? EditHistoryUseCaseError else {
            return error.localizedDescription
        }

        switch error {
        case .emptyTitle:
            return "やったことを入力してください。"
        case .noChanges:
            return "変更する内容がありません。"
        }
    }
}
