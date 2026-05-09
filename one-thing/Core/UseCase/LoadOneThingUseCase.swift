import Foundation

/// 今日やることを読み込むユースケース。
struct LoadOneThingUseCase {
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

    /// アプリ上の今日に該当する Thing を取得する。
    func execute(
        now: Date = Date(),
        dayBoundaryHour: Int = DayBoundaryUseCase.defaultBoundaryHour,
        dayBoundaryMinutes: Int? = nil
    ) async throws -> Thing? {
        let today = dayBoundaryUseCase.execute(
            now: now,
            dayBoundaryMinutes: dayBoundaryMinutes ?? dayBoundaryHour * 60
        )

        return try await repository.fetchThing(on: today)
    }
}
