import Foundation

/// 今日取り組む「ひとつのこと」を登録または更新するユースケース。
struct SetOneThingUseCase {
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

    /// 今日の Thing があれば内容を更新し、なければ新規作成する。
    func execute(
        title: String,
        now: Date = Date(),
        dayBoundaryHour: Int = DayBoundaryUseCase.defaultBoundaryHour
    ) async throws -> Thing {
        let today = dayBoundaryUseCase.execute(
            now: now,
            dayBoundaryHour: dayBoundaryHour
        )

        if let thing = try await repository.fetchThing(on: today) {
            thing.title = title
            thing.status = .inProgress
            try await repository.saveChanges()
            return thing
        }

        return try await repository.createThing(
            date: today,
            title: title,
            status: .inProgress
        )
    }
}
