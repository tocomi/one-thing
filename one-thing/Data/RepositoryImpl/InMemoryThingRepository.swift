import Foundation

final class InMemoryThingRepository: ThingRepository {
    private var things: [Thing]

    init(things: [Thing] = []) {
        self.things = things
    }

    func fetchCurrentThing() async throws -> Thing {
        if let thing = things.sorted(by: { $0.date > $1.date }).first {
            return thing
        }

        return Thing(title: "Write one thing")
    }

    func fetchThing(on date: Date) async throws -> Thing? {
        things.first { $0.date == date }
    }

    func createThing(date: Date, title: String, status: ThingStatus) async throws -> Thing {
        let thing = Thing(date: date, title: title, status: status)
        things.append(thing)
        return thing
    }

    func saveChanges() async throws {}
}
