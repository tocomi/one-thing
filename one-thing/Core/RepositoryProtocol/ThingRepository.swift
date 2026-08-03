import Foundation

/// Thing の取得・作成・保存を抽象化し、永続化方式を Core から切り離す。
@MainActor
protocol ThingRepository {
    /// 指定日の Thing を 1 件取得する。
    func fetchThing(on date: Date) async throws -> Thing?

    /// 指定期間に含まれる Thing を日付順で取得する。
    func fetchThings(from startDate: Date, to endDate: Date) async throws -> [Thing]

    /// 保存済みの Thing のうち、最も古い 1 件を取得する。
    func fetchEarliestThing() async throws -> Thing?

    /// 指定日の Thing を新規作成して保存対象に追加する。
    func createThing(date: Date, title: String, status: ThingStatus) async throws -> Thing

    /// 既存エンティティへの変更を永続化する。
    func saveChanges() async throws

    /// 指定日の Thing を削除する。
    func deleteThing(on date: Date) async throws

    /// 開発中の確認用に、保存済みの Thing をすべて削除する。
    func deleteAllThings() async throws
}
