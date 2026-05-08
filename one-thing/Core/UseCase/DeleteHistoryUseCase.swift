import Foundation

/// 過去日の Thing を削除するユースケース。
struct DeleteHistoryUseCase {
    private let repository: ThingRepository

    /// タスク保存先を受け取る。
    init(repository: ThingRepository) {
        self.repository = repository
    }

    /// 指定日の Thing が存在する場合に削除する。
    func execute(date: Date) async throws {
        try await repository.deleteThing(on: date)
    }
}
