#if DEBUG
import Foundation

/// Preview で使う Thing のシード。`PreviewClock` の固定日付を基準に組み立てる。
@MainActor
enum PreviewThingSeed {
    /// 完了状態の Preview で称賛メッセージを固定するための識別子。
    private static let doneThingID = UUID(uuidString: "0E5F7B2A-0000-4000-8000-00000000AA01") ?? UUID()

    /// 記録が 1 件もない状態のリポジトリを作る。
    static func makeEmptyRepository() -> InMemoryThingRepository {
        InMemoryThingRepository()
    }

    /// 過去の記録だけを持ち、今日はまだ未設定のリポジトリを作る。
    static func makeRecordedRepository() -> InMemoryThingRepository {
        InMemoryThingRepository(things: pastThings())
    }

    /// 今日のことが進行中のリポジトリを作る。
    static func makeInProgressRepository() -> InMemoryThingRepository {
        InMemoryThingRepository(
            things: pastThings() + [
                Thing(date: PreviewClock.today, title: "散歩する", status: .inProgress)
            ]
        )
    }

    /// 今日のことが完了済みのリポジトリを作る。
    static func makeDoneRepository() -> InMemoryThingRepository {
        InMemoryThingRepository(
            things: pastThings() + [
                Thing(id: doneThingID, date: PreviewClock.today, title: "散歩する", status: .done)
            ]
        )
    }

    /// 今日の記録が「休んだ」になっているリポジトリを作る。
    /// ホームがこれを完了として扱わないこと（未設定表示に戻ること）の確認に使う。
    static func makeRestedTodayRepository() -> InMemoryThingRepository {
        InMemoryThingRepository(
            things: pastThings() + [
                Thing(date: PreviewClock.today, title: "散歩する", status: .rested)
            ]
        )
    }

    /// 履歴カレンダーと候補表示のもとになる過去の記録。
    /// 「今日」からの相対日で置くことで、`PreviewClock` の基準日を変えても同じ並びになる。
    /// 18 日前まで遡るため、月初が基準日でも前月のページに記録が残る。
    private static func pastThings() -> [Thing] {
        [
            Thing(date: PreviewClock.daysAgo(1), title: "散歩する", status: .done),
            Thing(date: PreviewClock.daysAgo(2), title: "本を読む", status: .done),
            Thing(date: PreviewClock.daysAgo(3), title: "日記を書く", status: .rested),
            Thing(date: PreviewClock.daysAgo(6), title: "散歩する", status: .done),
            Thing(date: PreviewClock.daysAgo(10), title: "本を読む", status: .done),
            Thing(date: PreviewClock.daysAgo(18), title: "散歩する", status: .done)
        ]
    }
}

/// Preview のエラー表示で見せるメッセージを持つエラー。
enum PreviewRepositoryError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        "記録を読み込めませんでした。"
    }
}

/// 読み込みも保存も必ず失敗する Preview 用リポジトリ。エラー表示の確認に使う。
final class PreviewFailingThingRepository: ThingRepository {
    /// 失敗する Preview 用リポジトリを作る。
    init() {}

    /// 常に失敗する取得。
    func fetchThing(on date: Date) async throws -> Thing? {
        throw PreviewRepositoryError.unavailable
    }

    /// 常に失敗する期間取得。
    func fetchThings(from startDate: Date, to endDate: Date) async throws -> [Thing] {
        throw PreviewRepositoryError.unavailable
    }

    /// 常に失敗する最古データの取得。
    func fetchEarliestThing() async throws -> Thing? {
        throw PreviewRepositoryError.unavailable
    }

    /// 常に失敗する新規作成。
    func createThing(date: Date, title: String, status: ThingStatus) async throws -> Thing {
        throw PreviewRepositoryError.unavailable
    }

    /// 常に失敗する保存。
    func saveChanges() async throws {
        throw PreviewRepositoryError.unavailable
    }

    /// 常に失敗する削除。
    func deleteThing(on date: Date) async throws {
        throw PreviewRepositoryError.unavailable
    }

    /// 常に失敗する全削除。
    func deleteAllThings() async throws {
        throw PreviewRepositoryError.unavailable
    }
}
#endif
