import Foundation
import Observation

/// 月の読み込み結果を書き戻してよいかを判断するための引換券。
/// 破棄をまたいだ読み込みを見分けるため、キャッシュ側でしか作れないようにしている。
struct HistoryMonthLoadToken: Equatable {
    let month: Date
    fileprivate let generation: Int
}

/// 月ごとのカレンダー表示データと読み込み状態を保持する。
/// 同じ月の読み込みが重ならないよう、読み込みを開始してよいかの判断もここで行う。
@MainActor
@Observable
final class HistoryMonthCache {
    private var daysByMonth: [Date: [HistoryCalendarDay]] = [:]
    private var loadingMonths: Set<Date> = []
    private var errorsByMonth: [Date: String] = [:]
    /// 破棄のたびに進む世代。これより古い読み込みの結果は受け取らない。
    private var generation = 0

    /// 読み込み済みの月のセルを返す。未取得の月は nil を返す。
    func days(for month: Date) -> [HistoryCalendarDay]? {
        daysByMonth[month]
    }

    /// 指定した月を読み込み中かどうかを返す。
    func isLoading(_ month: Date) -> Bool {
        loadingMonths.contains(month)
    }

    /// 指定した月の読み込みに失敗したときのメッセージを返す。
    func error(for month: Date) -> String? {
        errorsByMonth[month]
    }

    /// 読み込みを開始できるならその月を読み込み中にして引換券を返す。
    /// すでに同じ月の読み込みが走っている場合は nil を返して重複を防ぐ。
    func beginLoading(_ month: Date) -> HistoryMonthLoadToken? {
        guard !loadingMonths.contains(month) else {
            return nil
        }

        loadingMonths.insert(month)
        errorsByMonth[month] = nil
        return HistoryMonthLoadToken(month: month, generation: generation)
    }

    /// 読み込み結果を保存し、読み込み中を解除する。
    func finishLoading(_ token: HistoryMonthLoadToken, days: [HistoryCalendarDay]) {
        guard isCurrent(token) else {
            return
        }

        loadingMonths.remove(token.month)
        daysByMonth[token.month] = days
        errorsByMonth[token.month] = nil
    }

    /// 読み込み失敗を記録し、読み込み中を解除する。
    func finishLoading(_ token: HistoryMonthLoadToken, error: String) {
        guard isCurrent(token) else {
            return
        }

        loadingMonths.remove(token.month)
        errorsByMonth[token.month] = error
    }

    /// 取得済みデータと読み込み中の状態をまとめて破棄する。
    /// 破棄より前に始まった読み込みの結果は、あとから届いても書き戻らない。
    func reset() {
        generation += 1
        daysByMonth.removeAll()
        errorsByMonth.removeAll()
        loadingMonths.removeAll()
    }

    private func isCurrent(_ token: HistoryMonthLoadToken) -> Bool {
        token.generation == generation
    }
}
