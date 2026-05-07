import Foundation
import Observation

/// 履歴シートの月移動とカレンダー表示用データを管理する。
@MainActor
@Observable
final class HistoryViewModel {
    var displayedMonth: Date
    var days: [HistoryCalendarDay] = []
    var selectedDay: HistoryCalendarDay?
    var isLoading = false
    var errorMessage: String?

    private let loadHistoryUseCase: LoadHistoryUseCase
    private let calendar: Calendar
    private let monthFormatter: DateFormatter
    private let dayFormatter: DateFormatter

    /// 履歴読み込みユースケースと日付計算用の Calendar を受け取る。
    init(
        loadHistoryUseCase: LoadHistoryUseCase,
        calendar: Calendar = .autoupdatingCurrent,
        initialMonth: Date = Date()
    ) {
        self.loadHistoryUseCase = loadHistoryUseCase
        self.calendar = calendar
        displayedMonth = calendar.startOfDay(for: initialMonth)

        let monthFormatter = DateFormatter()
        monthFormatter.locale = Locale(identifier: "ja_JP")
        monthFormatter.dateFormat = "yyyy年M月"
        self.monthFormatter = monthFormatter

        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "ja_JP")
        dayFormatter.dateFormat = "M月d日 (E)"
        self.dayFormatter = dayFormatter
    }

    /// 表示中の月名を返す。
    var monthText: String {
        monthFormatter.string(from: displayedMonth)
    }

    /// 曜日ヘッダーの短い表記を返す。
    var weekdaySymbols: [String] {
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let startIndex = max(calendar.firstWeekday - 1, 0)
        return Array(symbols[startIndex...] + symbols[..<startIndex])
    }

    /// 表示中の月の履歴を読み込む。
    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let things = try await loadHistoryUseCase.execute(monthContaining: displayedMonth)
            days = makeCalendarDays(for: displayedMonth, things: things)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// 前月へ移動して履歴を読み込む。
    func moveToPreviousMonth() async {
        guard let previousMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) else {
            return
        }

        displayedMonth = previousMonth
        await load()
    }

    /// 翌月へ移動して履歴を読み込む。
    func moveToNextMonth() async {
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) else {
            return
        }

        displayedMonth = nextMonth
        await load()
    }

    /// 日次詳細シートで表示する日付文字列を返す。
    func dayText(for date: Date) -> String {
        dayFormatter.string(from: date)
    }

    private func makeCalendarDays(for month: Date, things: [Thing]) -> [HistoryCalendarDay] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month),
              let dayRange = calendar.range(of: .day, in: .month, for: monthInterval.start) else {
            return []
        }

        let thingsByDay = Dictionary(uniqueKeysWithValues: things.map {
            (calendar.startOfDay(for: $0.date), $0)
        })
        let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
        let leadingEmptyCount = (firstWeekday - calendar.firstWeekday + 7) % 7
        var result = (0..<leadingEmptyCount).map { _ in HistoryCalendarDay.empty() }

        for day in dayRange {
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: monthInterval.start) else {
                continue
            }

            result.append(
                HistoryCalendarDay(
                    date: date,
                    dayNumber: day,
                    thing: thingsByDay[calendar.startOfDay(for: date)]
                )
            )
        }

        return result
    }
}

/// 月カレンダーの 1 マスに表示する日付と記録状態。
struct HistoryCalendarDay: Identifiable, Equatable {
    let id = UUID()
    let date: Date?
    let dayNumber: Int?
    let thing: Thing?

    /// 月初の曜日位置を合わせるための空セルを返す。
    static func empty() -> HistoryCalendarDay {
        HistoryCalendarDay(date: nil, dayNumber: nil, thing: nil)
    }
}
