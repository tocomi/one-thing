import Foundation

final class InMemoryThingRepository: ThingRepository {
    private var things: [Thing]

    init(things: [Thing] = []) {
        self.things = things
    }

    func fetchThing(on date: Date) async throws -> Thing? {
        things.first { $0.date == date }
    }

    func fetchThings(from startDate: Date, to endDate: Date) async throws -> [Thing] {
        things
            .filter { thing in
                startDate <= thing.date && thing.date < endDate
            }
            .sorted { $0.date < $1.date }
    }

    func createThing(date: Date, title: String, status: ThingStatus) async throws -> Thing {
        let thing = Thing(date: date, title: title, status: status)
        things.append(thing)
        return thing
    }

    func saveChanges() async throws {}
}
