struct InMemoryThingRepository: ThingRepository {
    func fetchCurrentThing() async throws -> Thing {
        Thing(title: "Write one thing")
    }
}
