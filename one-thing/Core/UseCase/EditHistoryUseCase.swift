import Foundation

/// 履歴編集時に発生しうる業務エラーを表す。
enum EditHistoryUseCaseError: Error, Equatable {
    case emptyTitle
    case noChanges
}

/// 履歴編集後に画面へ返す更新結果を表す。
struct EditHistoryResult {
    let thing: Thing
}

/// 過去日の Thing を編集するユースケース。
struct EditHistoryUseCase {
    private let repository: ThingRepository

    /// タスク保存先を受け取る。
    init(repository: ThingRepository) {
        self.repository = repository
    }

    /// 指定日の Thing を更新（存在しない場合は新規作成）し、保存後の内容を返す。
    func execute(
        date: Date,
        title: String? = nil,
        status: ThingStatus? = nil
    ) async throws -> EditHistoryResult {
        guard title != nil || status != nil else {
            throw EditHistoryUseCaseError.noChanges
        }

        let thing: Thing
        if let existing = try await repository.fetchThing(on: date) {
            thing = existing
            if let title {
                let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedTitle.isEmpty else {
                    throw EditHistoryUseCaseError.emptyTitle
                }
                thing.title = trimmedTitle
            }
            if let status {
                thing.status = status
            }
            try await repository.saveChanges()
        } else {
            let trimmedTitle = (title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedTitle.isEmpty else {
                throw EditHistoryUseCaseError.emptyTitle
            }
            thing = try await repository.createThing(
                date: date,
                title: trimmedTitle,
                status: status ?? .done
            )
        }

        return EditHistoryResult(thing: thing)
    }
}
