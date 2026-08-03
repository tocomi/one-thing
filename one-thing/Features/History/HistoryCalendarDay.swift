import Foundation

/// 月カレンダーの 1 マスに表示する日付と記録状態。
struct HistoryCalendarDay: Identifiable, Equatable {
    let id: String
    let date: Date?
    let dayNumber: Int?
    let thing: ThingSnapshot?
    let isToday: Bool
    let isFuture: Bool

    /// カレンダーセルの表示情報を受け取り、日付セルには日付由来の安定 ID を割り当てる。
    init(
        id: String? = nil,
        date: Date?,
        dayNumber: Int?,
        thing: ThingSnapshot?,
        isToday: Bool,
        isFuture: Bool
    ) {
        self.id = id ?? date.map { "day-\(Int($0.timeIntervalSinceReferenceDate))" } ?? "empty"
        self.date = date
        self.dayNumber = dayNumber
        self.thing = thing
        self.isToday = isToday
        self.isFuture = isFuture
    }

    /// 月初の曜日位置を合わせるための空セルを返す。
    static func empty(month: Date, index: Int, calendar: Calendar) -> HistoryCalendarDay {
        let monthStart = calendar.startOfDay(for: month)
        return HistoryCalendarDay(
            id: "empty-\(Int(monthStart.timeIntervalSinceReferenceDate))-\(index)",
            date: nil,
            dayNumber: nil,
            thing: nil,
            isToday: false,
            isFuture: false
        )
    }

    /// 指定した月に並べる 1 か月分のセルを、先頭の空セルを含めて組み立てる。
    static func makeMonth(
        for month: Date,
        things: [Thing],
        today: Date,
        calendar: Calendar
    ) -> [HistoryCalendarDay] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month),
              let dayRange = calendar.range(of: .day, in: .month, for: monthInterval.start)
        else {
            return []
        }

        // カレンダーは表示中ずっと保持されるため、永続化オブジェクトではなく値を写して持つ。
        let thingsByDay = Dictionary(uniqueKeysWithValues: things.map {
            (calendar.startOfDay(for: $0.date), ThingSnapshot($0))
        })
        let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
        let leadingEmptyCount = (firstWeekday - calendar.firstWeekday + 7) % 7
        var result = (0..<leadingEmptyCount).map { index in
            HistoryCalendarDay.empty(month: monthInterval.start, index: index, calendar: calendar)
        }

        for day in dayRange {
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: monthInterval.start) else {
                continue
            }

            let startOfDay = calendar.startOfDay(for: date)
            result.append(
                HistoryCalendarDay(
                    date: date,
                    dayNumber: day,
                    thing: thingsByDay[startOfDay],
                    isToday: startOfDay == today,
                    isFuture: today < startOfDay
                )
            )
        }

        return result
    }
}
