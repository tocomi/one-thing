import Foundation

/// 履歴カレンダーで遡れる下限を決めるため、最も古い記録の日付を取得するユースケース。
struct LoadEarliestHistoryDateUseCase {
    private let repository: ThingRepository

    /// タスク保存先を受け取る。
    init(repository: ThingRepository) {
        self.repository = repository
    }

    /// 保存済みの Thing のうち最も古い日付を返す。記録がなければ nil を返す。
    func execute() async throws -> Date? {
        try await repository.fetchEarliestThing()?.date
    }
}
