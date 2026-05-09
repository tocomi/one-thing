import Foundation

/// 過去の履歴から、今日やることの候補を頻度順に提案するユースケース。
struct SuggestThingsUseCase {
    private struct SuggestionSummary {
        let title: String
        var count: Int
        var lastUsedAt: Date
    }

    private let repository: ThingRepository
    private let dayBoundaryUseCase: DayBoundaryUseCase
    private let calendar: Calendar

    /// タスク保存先と日付範囲の計算に使う依存を受け取る。
    init(
        repository: ThingRepository,
        dayBoundaryUseCase: DayBoundaryUseCase = DayBoundaryUseCase(),
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.repository = repository
        self.dayBoundaryUseCase = dayBoundaryUseCase
        self.calendar = calendar
    }

    /// 今日より前の1年間の履歴から、よく選ばれたタイトルを最大件数分返す。
    func execute(
        now: Date = Date(),
        dayBoundaryHour: Int = DayBoundaryUseCase.defaultBoundaryHour,
        limit: Int = 3
    ) async throws -> [String] {
        guard limit > 0 else {
            return []
        }

        let today = dayBoundaryUseCase.execute(
            now: now,
            dayBoundaryHour: dayBoundaryHour
        )
        let startDate = calendar.date(byAdding: .year, value: -1, to: today) ?? today
        let things = try await repository.fetchThings(from: startDate, to: today)
        let summaries = summarize(things: things)

        return summaries
            .sorted { lhs, rhs in
                if lhs.count != rhs.count {
                    return lhs.count > rhs.count
                }
                if lhs.lastUsedAt != rhs.lastUsedAt {
                    return lhs.lastUsedAt > rhs.lastUsedAt
                }
                return lhs.title < rhs.title
            }
            .prefix(limit)
            .map(\.title)
    }

    /// 前後空白を除いた完全一致で履歴タイトルを集計する。
    private func summarize(things: [Thing]) -> [SuggestionSummary] {
        var summariesByTitle: [String: SuggestionSummary] = [:]

        for thing in things {
            let title = thing.title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty else {
                continue
            }

            if var summary = summariesByTitle[title] {
                summary.count += 1
                summary.lastUsedAt = max(summary.lastUsedAt, thing.date)
                summariesByTitle[title] = summary
            } else {
                summariesByTitle[title] = SuggestionSummary(
                    title: title,
                    count: 1,
                    lastUsedAt: thing.date
                )
            }
        }

        return Array(summariesByTitle.values)
    }
}
