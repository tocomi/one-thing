import Foundation

/// 今日を起点に、連続して完了した日数を計算するユースケース。
struct CalculateStreakUseCase {
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

    /// 今日から過去に向かって、done が連続している日数を返す。
    func execute(
        now: Date = Date(),
        dayBoundaryHour: Int = DayBoundaryUseCase.defaultBoundaryHour
    ) async throws -> Int {
        var currentDate = dayBoundaryUseCase.execute(
            now: now,
            dayBoundaryHour: dayBoundaryHour
        )
        var count = 0

        while let thing = try await repository.fetchThing(on: currentDate),
              thing.status == .done {
            count += 1

            guard let previousDate = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }

            currentDate = previousDate
        }

        return count
    }
}
