import Foundation
import SwiftData

@MainActor
struct SwiftDataThingRepository: ThingRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
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

    func fetchThings(from startDate: Date, to endDate: Date) async throws -> [Thing] {
        let descriptor = FetchDescriptor<Thing>(
            predicate: #Predicate { thing in
                startDate <= thing.date && thing.date < endDate
            },
            sortBy: [SortDescriptor(\.date)]
        )

        return try modelContext.fetch(descriptor)
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
