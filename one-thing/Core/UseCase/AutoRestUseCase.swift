import Foundation

/// 前日の未完了タスクを自動的に休息扱いへ更新するユースケース。
struct AutoRestUseCase {
    private let repository: ThingRepository
    private let dayBoundaryUseCase: DayBoundaryUseCase
    private let calendar: Calendar

    /// タスク保存先、日付境界の判定、日付計算に使う Calendar を受け取る。
    init(
        repository: ThingRepository,
        dayBoundaryUseCase: DayBoundaryUseCase = DayBoundaryUseCase(),
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.repository = repository
        self.dayBoundaryUseCase = dayBoundaryUseCase
        self.calendar = calendar
    }

    /// 今日の境界から見た前日の未完了タスクがあれば rested に変更する。
    @discardableResult
    func execute(
        now: Date = Date(),
        dayBoundaryHour: Int = DayBoundaryUseCase.defaultBoundaryHour,
        dayBoundaryMinutes: Int? = nil
    ) async throws -> Thing? {
        let today = dayBoundaryUseCase.execute(
            now: now,
            dayBoundaryMinutes: dayBoundaryMinutes ?? dayBoundaryHour * 60
        )

        guard let previousDay = calendar.date(byAdding: .day, value: -1, to: today),
              let thing = try await repository.fetchThing(on: previousDay),
              thing.status == .inProgress else {
            return nil
        }

        thing.status = .rested
        try await repository.saveChanges()
        return thing
    }
}
