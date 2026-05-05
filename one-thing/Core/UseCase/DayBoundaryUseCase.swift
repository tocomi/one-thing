import Foundation

struct DayBoundaryUseCase {
    nonisolated static let defaultBoundaryHour = 4

    private let calendar: Calendar

    init(calendar: Calendar = .autoupdatingCurrent) {
        self.calendar = calendar
    }

    func execute(
        now: Date = Date(),
        dayBoundaryHour: Int = Self.defaultBoundaryHour
    ) -> Date {
        let normalizedBoundaryHour = min(max(dayBoundaryHour, 0), 23)
        let startOfCurrentDay = calendar.startOfDay(for: now)

        guard let boundaryDate = calendar.date(
            byAdding: .hour,
            value: normalizedBoundaryHour,
            to: startOfCurrentDay
        ) else {
            return startOfCurrentDay
        }

        if now < boundaryDate,
           let previousDay = calendar.date(byAdding: .day, value: -1, to: startOfCurrentDay) {
            return previousDay
        }

        return startOfCurrentDay
    }
}
