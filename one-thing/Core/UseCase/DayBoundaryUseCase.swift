import Foundation

/// 日付の切り替わり時刻を考慮して、アプリ上の「今日」を決めるユースケース。
struct DayBoundaryUseCase {
    nonisolated static let defaultBoundaryHour = 4
    nonisolated static let defaultBoundaryMinutes = defaultBoundaryHour * 60

    private let calendar: Calendar

    /// 日付計算に使う Calendar を受け取る。
    init(calendar: Calendar = .autoupdatingCurrent) {
        self.calendar = calendar
    }

    /// 現在時刻と境界時刻から、タスクを紐づける日付の開始時刻を返す。
    func execute(
        now: Date = Date(),
        dayBoundaryHour: Int = Self.defaultBoundaryHour
    ) -> Date {
        execute(
            now: now,
            dayBoundaryMinutes: dayBoundaryHour * 60
        )
    }

    /// 現在時刻と分単位の境界時刻から、タスクを紐づける日付の開始時刻を返す。
    func execute(
        now: Date = Date(),
        dayBoundaryMinutes: Int
    ) -> Date {
        let normalizedBoundaryMinutes = min(max(dayBoundaryMinutes, 0), (24 * 60) - 1)
        let startOfCurrentDay = calendar.startOfDay(for: now)

        guard let boundaryDate = calendar.date(
            byAdding: .minute,
            value: normalizedBoundaryMinutes,
            to: startOfCurrentDay
        ) else {
            return startOfCurrentDay
        }

        if now < boundaryDate,
           let previousDay = calendar.date(byAdding: .day, value: -1, to: startOfCurrentDay)
        {
            return previousDay
        }

        return startOfCurrentDay
    }
}
