import Foundation
import Observation

/// 履歴シートの月ページとカレンダー表示用データを管理する。
@MainActor
@Observable
final class HistoryViewModel {
    /// 表示中の月。月ページの selection として View から双方向に更新される。
    var displayedMonth: Date
    /// 表示できる月の一覧。昇順で、末尾は基準にしている今月。未来の月は持たない。
    private(set) var months: [Date] = []
    var selectedDay: HistoryCalendarDay?
    var isSaving = false
    /// 保存・削除の失敗を詳細シートへ伝えるメッセージ。月の読み込みエラーとは別に扱う。
    var errorMessage: String?

    /// 表示中ずっと基準にする今月。
    /// ページ範囲と移動可否をこの 1 つの値から導き、開いたまま月が替わってもずれないようにする。
    private var currentMonth: Date
    /// 記録から月ページの下限を決め終えたかどうか。
    private var isMonthRangeResolved = false

    private let loadHistoryUseCase: LoadHistoryUseCase
    private let loadEarliestHistoryDateUseCase: LoadEarliestHistoryDateUseCase
    // 日次編集は HistoryViewModel+DayEditing.swift に分けているため、そこから参照できるようにしている。
    let editHistoryUseCase: EditHistoryUseCase
    let deleteHistoryUseCase: DeleteHistoryUseCase
    let calendar: Calendar
    private let userDefaults: UserDefaults
    private let dayBoundaryUseCase: DayBoundaryUseCase
    private let monthCache = HistoryMonthCache()
    private let monthFormatter: DateFormatter
    private let dayFormatter: DateFormatter
    private let nowProvider: () -> Date

    /// 履歴読み込みユースケースと日付計算用の Calendar を受け取る。
    /// `nowProvider` は現在時刻の取得を差し替えるためのもので、テストでは固定時刻を渡す。
    init(
        loadHistoryUseCase: LoadHistoryUseCase,
        loadEarliestHistoryDateUseCase: LoadEarliestHistoryDateUseCase,
        editHistoryUseCase: EditHistoryUseCase,
        deleteHistoryUseCase: DeleteHistoryUseCase,
        calendar: Calendar = .autoupdatingCurrent,
        userDefaults: UserDefaults = .standard,
        dayBoundaryUseCase: DayBoundaryUseCase? = nil,
        nowProvider: @escaping () -> Date = { Date() }
    ) {
        self.loadHistoryUseCase = loadHistoryUseCase
        self.loadEarliestHistoryDateUseCase = loadEarliestHistoryDateUseCase
        self.editHistoryUseCase = editHistoryUseCase
        self.deleteHistoryUseCase = deleteHistoryUseCase
        self.calendar = calendar
        self.userDefaults = userDefaults
        let dayBoundaryUseCase = dayBoundaryUseCase ?? DayBoundaryUseCase(calendar: calendar)
        self.dayBoundaryUseCase = dayBoundaryUseCase
        self.nowProvider = nowProvider

        let monthFormatter = DateFormatter()
        monthFormatter.locale = Locale(identifier: "ja_JP")
        monthFormatter.dateFormat = "yyyy年M月"
        self.monthFormatter = monthFormatter

        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "ja_JP")
        dayFormatter.dateFormat = "M月d日 (E)"
        self.dayFormatter = dayFormatter

        let currentMonth = HistoryMonthRange.monthStart(
            of: dayBoundaryUseCase.execute(
                now: nowProvider(),
                dayBoundaryMinutes: Self.dayBoundaryMinutes(in: userDefaults)
            ),
            calendar: calendar
        )
        self.currentMonth = currentMonth
        displayedMonth = currentMonth
        months = HistoryMonthRange.defaultMonths(endingAt: currentMonth, calendar: calendar)
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

    /// 表示中の月が基準にしている今月かどうかを返す。
    var isDisplayingCurrentMonth: Bool {
        displayedMonth == currentMonth
    }

    /// 翌月へ移動できるかどうかを返す。今月より未来へは移動できない。
    var canMoveToNextMonth: Bool {
        !isDisplayingCurrentMonth
    }

    /// 前月へ移動できるかどうかを返す。月ページの先頭より過去へは移動できない。
    var canMoveToPreviousMonth: Bool {
        months.first != displayedMonth
    }

    /// 指定した月の表示データを返す。まだ取得していない月は nil を返す。
    func days(for month: Date) -> [HistoryCalendarDay]? {
        monthCache.days(for: month)
    }

    /// 指定した月を読み込み中かどうかを返す。
    func isLoading(_ month: Date) -> Bool {
        monthCache.isLoading(month)
    }

    /// 指定した月の読み込みエラーを返す。
    func loadError(for month: Date) -> String? {
        monthCache.error(for: month)
    }

    /// 月ページの範囲を必要なら決めたうえで、表示中の月をまだ持っていなければ読み込む。
    func loadDisplayedMonthIfNeeded() async {
        await resolveMonthRangeIfNeeded()
        await loadMonth(displayedMonth, force: false)
    }

    /// 履歴シート表示前に、選択状態と取得済みデータを破棄して今月に戻す。
    func prepareForPresentation() {
        selectedDay = nil
        errorMessage = nil
        // 破棄より前に始まった読み込みの結果は、あとから届いても反映されない。
        monthCache.reset()
        currentMonth = monthStart(of: appToday())
        displayedMonth = currentMonth
        months = HistoryMonthRange.defaultMonths(endingAt: currentMonth, calendar: calendar)
        isMonthRangeResolved = false
    }

    /// 前月のページへ移動する。読み込み中でもページ送り自体は止めない。
    func moveToPreviousMonth() {
        guard canMoveToPreviousMonth,
              let previousMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth)
        else {
            return
        }

        displayedMonth = monthStart(of: previousMonth)
    }

    /// 翌月のページへ移動する。今月を表示しているときは動かない。
    func moveToNextMonth() {
        guard canMoveToNextMonth,
              let nextMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth)
        else {
            return
        }

        displayedMonth = monthStart(of: nextMonth)
    }

    /// 日次詳細シートで表示する日付文字列を返す。
    func dayText(for date: Date) -> String {
        dayFormatter.string(from: date)
    }

    /// 最も古い記録が既定の下限より古ければ、その月まで月ページを広げる。
    private func resolveMonthRangeIfNeeded() async {
        guard !isMonthRangeResolved else {
            return
        }

        let baseMonth = currentMonth

        do {
            let earliestDate = try await loadEarliestHistoryDateUseCase.execute()

            // 取得中に表示をリセットしていた場合は、そのとき始まった結果を反映しない。
            guard baseMonth == currentMonth else {
                return
            }

            isMonthRangeResolved = true

            guard let earliestMonth = earliestDate.map({ monthStart(of: $0) }),
                  let firstMonth = months.first,
                  earliestMonth < firstMonth
            else {
                return
            }

            months = HistoryMonthRange.months(from: earliestMonth, to: baseMonth, calendar: calendar)
        } catch {
            // 下限を広げられなくても既定の範囲は表示できるため、次の機会に決め直す。
        }
    }

    /// 指定した月を読み込む。取得済みの月は `force` を指定したときだけ読み直す。
    /// 保存・削除のあとに読み直すため、日次編集の拡張からも呼べるようにしている。
    func loadMonth(_ month: Date, force: Bool) async {
        if !force, monthCache.days(for: month) != nil {
            return
        }

        // 同じ月の読み込み中は引換券を得られないため、素早いページ送りでもリクエストが重複しない。
        guard let token = monthCache.beginLoading(month) else {
            return
        }

        do {
            let things = try await loadHistoryUseCase.execute(monthContaining: month)
            monthCache.finishLoading(
                token,
                days: HistoryCalendarDay.makeMonth(
                    for: month,
                    things: things,
                    today: appToday(),
                    calendar: calendar
                )
            )
        } catch {
            monthCache.finishLoading(token, error: error.localizedDescription)
        }
    }

    private func monthStart(of date: Date) -> Date {
        HistoryMonthRange.monthStart(of: date, calendar: calendar)
    }

    /// アプリ上の「今日」を返す。日次編集の可否判定でも使うため、拡張から参照できるようにしている。
    func appToday() -> Date {
        dayBoundaryUseCase.execute(
            now: nowProvider(),
            dayBoundaryMinutes: Self.dayBoundaryMinutes(in: userDefaults)
        )
    }

    private static func dayBoundaryMinutes(in userDefaults: UserDefaults) -> Int {
        userDefaults.object(forKey: SettingsKeys.dayBoundaryMinutes) == nil
            ? DayBoundaryUseCase.defaultBoundaryMinutes
            : userDefaults.integer(forKey: SettingsKeys.dayBoundaryMinutes)
    }
}
