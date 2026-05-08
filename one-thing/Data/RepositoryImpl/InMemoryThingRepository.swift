import Foundation

/// プレビューやテストで使う、メモリ上だけに Thing を保持するリポジトリ。
final class InMemoryThingRepository: ThingRepository {
    private var things: [Thing]

    /// 初期データを受け取り、メモリ内の保存先を準備する。
    init(things: [Thing] = []) {
        self.things = things
    }

    /// メモリ上の配列から指定日の Thing を 1 件取得する。
    func fetchThing(on date: Date) async throws -> Thing? {
        things.first { $0.date == date }
    }

    /// メモリ上の配列から指定期間の Thing を日付順で取得する。
    func fetchThings(from startDate: Date, to endDate: Date) async throws -> [Thing] {
        things
            .filter { thing in
                startDate <= thing.date && thing.date < endDate
            }
            .sorted { $0.date < $1.date }
    }

    /// メモリ上の配列に新しい Thing を追加する。
    func createThing(date: Date, title: String, status: ThingStatus) async throws -> Thing {
        let thing = Thing(date: date, title: title, status: status)
        things.append(thing)
        return thing
    }

    /// 永続化を持たないため、保存処理を何もせず完了させる。
    func saveChanges() async throws {}

    /// メモリ上の配列から指定日の Thing を削除する。
    func deleteThing(on date: Date) async throws {
        things.removeAll { $0.date == date }
    }

    /// メモリ上に保持している Thing をすべて削除する。
    func deleteAllThings() async throws {
        things.removeAll()
    }
}
