import Foundation

/// 履歴カレンダーが扱う月の並びを組み立てる。
enum HistoryMonthRange {
    /// 記録がなくても遡れるようにする月ページ数。
    /// 過去の日は記録がなくても書けるため、記録の有無に関わらずここまでは開けるようにする。
    /// これより古い記録があれば、その月までページを広げる。
    private static let minimumPastMonthCount = 120

    /// 記録を読む前でも扱える、既定の月ページ一覧を返す。
    static func defaultMonths(endingAt currentMonth: Date, calendar: Calendar) -> [Date] {
        guard let startMonth = calendar.date(
            byAdding: .month,
            value: -minimumPastMonthCount,
            to: currentMonth
        ) else {
            return [currentMonth]
        }

        return months(from: startMonth, to: currentMonth, calendar: calendar)
    }

    /// 指定した日付が属する月の初日を返す。月ページのキーはこの値に揃える。
    static func monthStart(of date: Date, calendar: Calendar) -> Date {
        calendar.dateInterval(of: .month, for: date)?.start ?? calendar.startOfDay(for: date)
    }

    /// 開始月から終了月までの各月を昇順で返す。
    /// 開始月が終了月より後の場合は、終了月だけを持つ 1 か月ぶんを返す。
    static func months(from startMonth: Date, to endMonth: Date, calendar: Calendar) -> [Date] {
        var result: [Date] = []
        var month = monthStart(of: startMonth, calendar: calendar)
        let lastMonth = monthStart(of: endMonth, calendar: calendar)

        while month < lastMonth {
            result.append(month)

            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: month) else {
                break
            }

            month = monthStart(of: nextMonth, calendar: calendar)
        }

        return result + [lastMonth]
    }
}
