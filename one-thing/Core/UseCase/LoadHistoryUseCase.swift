import Foundation

/// カレンダー履歴で表示する月単位の Thing を読み込むユースケース。
struct LoadHistoryUseCase {
    private let repository: ThingRepository
    private let calendar: Calendar

    /// タスク保存先と月範囲の計算に使う Calendar を受け取る。
    init(
        repository: ThingRepository,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.repository = repository
        self.calendar = calendar
    }

    /// 指定日を含む月に記録された Thing を日付昇順で返す。
    func execute(monthContaining date: Date = Date()) async throws -> [Thing] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else {
            return []
        }

        return try await repository.fetchThings(
            from: monthInterval.start,
            to: monthInterval.end
        )
    }
}
