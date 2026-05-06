import Foundation

/// 開発中の確認用に保存済みデータを初期化するユースケース。
struct ResetThingDataUseCase {
    private let repository: ThingRepository

    /// 初期化対象の保存先を受け取る。
    init(repository: ThingRepository) {
        self.repository = repository
    }

    /// 保存済みの Thing をすべて削除する。
    func execute() async throws {
        try await repository.deleteAllThings()
    }
}
