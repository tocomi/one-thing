@MainActor
protocol ThingRepository {
    func fetchCurrentThing() async throws -> Thing
}
