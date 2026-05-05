import Foundation
import SwiftData

@MainActor
struct SwiftDataThingRepository: ThingRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchCurrentThing() async throws -> Thing {
        var descriptor = FetchDescriptor<Thing>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        if let thing = try modelContext.fetch(descriptor).first {
            return thing
        }

        let thing = Thing(title: "Write one thing")
        modelContext.insert(thing)
        try modelContext.save()
        return thing
    }

    func fetchThing(on date: Date) async throws -> Thing? {
        var descriptor = FetchDescriptor<Thing>(
            predicate: #Predicate { thing in
                thing.date == date
            }
        )
        descriptor.fetchLimit = 1

        return try modelContext.fetch(descriptor).first
    }

    func createThing(date: Date, title: String, status: ThingStatus) async throws -> Thing {
        let thing = Thing(date: date, title: title, status: status)
        modelContext.insert(thing)
        try modelContext.save()
        return thing
    }

    func saveChanges() async throws {
        try modelContext.save()
    }
}
