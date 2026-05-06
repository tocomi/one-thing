import Foundation
import SwiftData

/// SwiftData を使って Thing を永続化する本番用リポジトリ。
@MainActor
struct SwiftDataThingRepository: ThingRepository {
    private let modelContext: ModelContext

    /// SwiftData の ModelContext を受け取り、保存・取得処理に利用する。
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// SwiftData から指定日の Thing を 1 件取得する。
    func fetchThing(on date: Date) async throws -> Thing? {
        var descriptor = FetchDescriptor<Thing>(
            predicate: #Predicate { thing in
                thing.date == date
            }
        )
        descriptor.fetchLimit = 1

        return try modelContext.fetch(descriptor).first
    }

    /// SwiftData から指定期間の Thing を日付順で取得する。
    func fetchThings(from startDate: Date, to endDate: Date) async throws -> [Thing] {
        let descriptor = FetchDescriptor<Thing>(
            predicate: #Predicate { thing in
                startDate <= thing.date && thing.date < endDate
            },
            sortBy: [SortDescriptor(\.date)]
        )

        return try modelContext.fetch(descriptor)
    }

    /// SwiftData に新しい Thing を挿入して保存する。
    func createThing(date: Date, title: String, status: ThingStatus) async throws -> Thing {
        let thing = Thing(date: date, title: title, status: status)
        modelContext.insert(thing)
        try modelContext.save()
        return thing
    }

    /// ModelContext 上の変更を SwiftData に保存する。
    func saveChanges() async throws {
        try modelContext.save()
    }

    /// SwiftData に保存されている Thing をすべて削除する。
    func deleteAllThings() async throws {
        let descriptor = FetchDescriptor<Thing>()
        let things = try modelContext.fetch(descriptor)

        for thing in things {
            modelContext.delete(thing)
        }

        try modelContext.save()
    }
}
