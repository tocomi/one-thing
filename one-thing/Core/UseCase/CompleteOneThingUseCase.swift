import Foundation

/// 今日のタスク完了時に発生しうる業務エラーを表す。
enum CompleteOneThingUseCaseError: Error, Equatable {
    case thingNotFound
}

/// 今日やることを完了状態へ更新するユースケース。
struct CompleteOneThingUseCase {
    private let repository: ThingRepository
    private let dayBoundaryUseCase: DayBoundaryUseCase

    /// タスク保存先と日付境界の判定ロジックを受け取る。
    init(
        repository: ThingRepository,
        dayBoundaryUseCase: DayBoundaryUseCase = DayBoundaryUseCase()
    ) {
        self.repository = repository
        self.dayBoundaryUseCase = dayBoundaryUseCase
    }

    /// 今日の Thing を取得し、存在する場合は done に変更して保存する。
    func execute(
        now: Date = Date(),
        dayBoundaryHour: Int = DayBoundaryUseCase.defaultBoundaryHour
    ) async throws -> Thing {
        let today = dayBoundaryUseCase.execute(
            now: now,
            dayBoundaryHour: dayBoundaryHour
        )

        guard let thing = try await repository.fetchThing(on: today) else {
            throw CompleteOneThingUseCaseError.thingNotFound
        }

        thing.status = .done
        try await repository.saveChanges()
        return thing
    }
}
