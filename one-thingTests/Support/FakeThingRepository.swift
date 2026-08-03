import Foundation
@testable import one_thing

/// fake リポジトリに注入して異常系を再現するためのエラー。
struct FakeRepositoryError: Error, Equatable {
    let message: String

    init(message: String = "fake repository failure") {
        self.message = message
    }
}

/// ThingRepository をメモリ上で再現し、呼び出し内容を記録するテスト用の fake。
@MainActor
final class FakeThingRepository: ThingRepository {
    /// エラーを注入できる操作の種類。
    enum Operation: Hashable {
        case fetchThing
        case fetchThings
        case createThing
        case saveChanges
        case deleteThing
        case deleteAllThings
    }

    /// fetchThings に渡された取得範囲。
    struct FetchRange: Equatable {
        let startDate: Date
        let endDate: Date
    }

    /// 操作ごとに投げるエラー。未設定の操作は正常に完了する。
    var errors: [Operation: Error] = [:]

    /// true の間 fetchThings を待機させ、読み込み中の状態をテストから再現できるようにする。
    var suspendsFetchThings = false

    private(set) var things: [Thing]
    private(set) var fetchThingDates: [Date] = []
    private(set) var fetchRanges: [FetchRange] = []
    private(set) var createdThings: [Thing] = []
    private(set) var deletedDates: [Date] = []
    private(set) var saveChangesCallCount = 0
    private(set) var deleteAllThingsCallCount = 0

    private var suspendedFetchThings: [CheckedContinuation<Void, Never>] = []

    /// 初期データを受け取り、メモリ内の保存先を準備する。
    init(things: [Thing] = []) {
        self.things = things
    }

    /// 保存済みの Thing から指定日のものを取得する。
    func fetchThing(on date: Date) async throws -> Thing? {
        try throwIfNeeded(.fetchThing)
        fetchThingDates.append(date)
        return things.first { $0.date == date }
    }

    /// 開始日以上・終了日未満の Thing を日付昇順で取得する。
    func fetchThings(from startDate: Date, to endDate: Date) async throws -> [Thing] {
        try throwIfNeeded(.fetchThings)
        // 呼び出し自体は待機前に記録し、待機中でも呼ばれた回数を検証できるようにする。
        fetchRanges.append(FetchRange(startDate: startDate, endDate: endDate))

        if suspendsFetchThings {
            await withCheckedContinuation { continuation in
                suspendedFetchThings.append(continuation)
            }
        }

        return things
            .filter { startDate <= $0.date && $0.date < endDate }
            .sorted { $0.date < $1.date }
    }

    /// 新しい Thing を作成して保存先に追加する。
    func createThing(date: Date, title: String, status: ThingStatus) async throws -> Thing {
        try throwIfNeeded(.createThing)

        let thing = Thing(date: date, title: title, status: status)
        things.append(thing)
        createdThings.append(thing)
        return thing
    }

    /// 永続化を持たないため、呼び出し回数だけを記録する。
    func saveChanges() async throws {
        try throwIfNeeded(.saveChanges)
        saveChangesCallCount += 1
    }

    /// 指定日の Thing を保存先から取り除く。
    func deleteThing(on date: Date) async throws {
        try throwIfNeeded(.deleteThing)
        deletedDates.append(date)
        things.removeAll { $0.date == date }
    }

    /// 保存済みの Thing をすべて取り除く。
    func deleteAllThings() async throws {
        try throwIfNeeded(.deleteAllThings)
        deleteAllThingsCallCount += 1
        things.removeAll()
    }

    /// 待機中の fetchThings をすべて再開させる。
    func resumeFetchThings() {
        let continuations = suspendedFetchThings
        suspendedFetchThings = []
        continuations.forEach { $0.resume() }
    }

    /// 検証用に、保存されている指定日の Thing を同期的に取り出す。
    func storedThing(on date: Date) -> Thing? {
        things.first { $0.date == date }
    }

    private func throwIfNeeded(_ operation: Operation) throws {
        if let error = errors[operation] {
            throw error
        }
    }
}
