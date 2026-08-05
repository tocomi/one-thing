#if DEBUG
import Foundation

/// Preview の見え方を実行日やタイムゾーンに左右させないため、固定した Calendar と現在時刻を提供する。
enum PreviewClock {
    /// Preview 全体で共有する固定 Calendar（グレゴリオ暦・Asia/Tokyo）。
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .gmt
        calendar.locale = Locale(identifier: "ja_JP")
        return calendar
    }()

    /// 固定 Calendar で日付境界を判定するユースケース。Preview 用のユースケースへ渡して基準をそろえる。
    static let dayBoundaryUseCase = DayBoundaryUseCase(calendar: calendar)

    /// Preview の基準にする現在時刻。日付境界（4 時）から十分離れた時刻にしている。
    static let now = date(2026, 5, 8, 10, 0)

    /// `now` に対応する、アプリ上の「今日」の日付。
    static let today = day(2026, 5, 8)

    /// 指定した年月日時分に対応する Date を固定 Calendar 上で作る。
    static func date(
        _ year: Int,
        _ month: Int,
        _ dayOfMonth: Int,
        _ hour: Int = 0,
        _ minute: Int = 0
    ) -> Date {
        let components = DateComponents(
            year: year,
            month: month,
            day: dayOfMonth,
            hour: hour,
            minute: minute
        )

        // Preview 用の日付は常に有効な組み合わせを渡す前提とする。
        guard let date = calendar.date(from: components) else {
            preconditionFailure("Preview 用の日付を生成できませんでした: \(components)")
        }

        return date
    }

    /// 指定日の 0 時（アプリが Thing に紐づける「日付」の値）を作る。
    static func day(_ year: Int, _ month: Int, _ dayOfMonth: Int) -> Date {
        date(year, month, dayOfMonth)
    }

    /// 画面が日付を出すときと同じ「M月d日 (E)」形式の文字列を返す。
    /// 基準日を変えても Preview の日付表示が実際の日付とずれないよう、文字列も固定 Calendar から作る。
    static func dayText(for date: Date) -> String {
        dayFormatter.string(from: date)
    }

    /// `today` から指定日数だけ遡った日付を作る。
    static func daysAgo(_ days: Int) -> Date {
        calendar.date(byAdding: .day, value: -days, to: today) ?? today
    }

    /// 日付表示に使うフォーマッタ。HomeViewModel / HistoryViewModel と同じ書式にそろえる。
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日 (E)"
        return formatter
    }()
}
#endif
