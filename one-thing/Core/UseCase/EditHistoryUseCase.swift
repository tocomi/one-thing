import Foundation

/// 履歴編集時に発生しうる業務エラーを表す。
enum EditHistoryUseCaseError: Error, Equatable {
    case thingNotFound
    case emptyTitle
    case noChanges
}

/// 履歴編集後に画面へ返す更新結果を表す。
struct EditHistoryResult {
    let thing: Thing
    let streakCount: Int
}

/// 過去日の Thing を編集し、編集後の連続達成日数を再計算するユースケース。
struct EditHistoryUseCase {
    private let repository: ThingRepository
    private let calculateStreakUseCase: CalculateStreakUseCase

    /// タスク保存先とストリーク再計算ユースケースを受け取る。
    init(
        repository: ThingRepository,
        calculateStreakUseCase: CalculateStreakUseCase
    ) {
        self.repository = repository
        self.calculateStreakUseCase = calculateStreakUseCase
    }

    /// 指定日の Thing を更新し、保存後の連続達成日数を返す。
    func execute(
        date: Date,
        title: String? = nil,
        status: ThingStatus? = nil,
        now: Date = Date(),
        dayBoundaryHour: Int = DayBoundaryUseCase.defaultBoundaryHour
    ) async throws -> EditHistoryResult {
        guard title != nil || status != nil else {
            throw EditHistoryUseCaseError.noChanges
        }

        guard let thing = try await repository.fetchThing(on: date) else {
            throw EditHistoryUseCaseError.thingNotFound
        }

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
        let streakCount = try await calculateStreakUseCase.execute(
            now: now,
            dayBoundaryHour: dayBoundaryHour
        )

        return EditHistoryResult(thing: thing, streakCount: streakCount)
    }
}
