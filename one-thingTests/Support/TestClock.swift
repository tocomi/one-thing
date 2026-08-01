import Foundation

/// 実行環境のタイムゾーンや現在時刻に左右されないよう、固定した Calendar と日付を提供する。
enum TestClock {
    /// テスト全体で共有する固定 Calendar（グレゴリオ暦・Asia/Tokyo）。
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .gmt
        calendar.locale = Locale(identifier: "ja_JP")
        return calendar
    }()

    /// 指定した年月日時分に対応する Date を固定 Calendar 上で作る。
    static func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int = 0,
        _ minute: Int = 0
    ) -> Date {
        let components = DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )

        // テストデータの日付は常に有効な組み合わせを渡す前提とする。
        guard let date = calendar.date(from: components) else {
            preconditionFailure("テスト用の日付を生成できませんでした: \(components)")
        }

        return date
    }

    /// 指定日の 0 時（アプリが Thing に紐づける「日付」の値）を作る。
    static func day(_ year: Int, _ month: Int, _ dayOfMonth: Int) -> Date {
        date(year, month, dayOfMonth)
    }

    /// 現在時刻を固定するテストの基準時刻。日付境界（4 時）から十分離れた時刻にしている。
    static let fixedNow = date(2026, 8, 1, 10, 0)

    /// `fixedNow` に対応する、アプリ上の「今日」の日付。
    static let fixedToday = day(2026, 8, 1)
}
