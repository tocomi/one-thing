import Foundation

@MainActor
protocol ThingRepository {
    func fetchCurrentThing() async throws -> Thing
    func fetchThing(on date: Date) async throws -> Thing?
    func createThing(date: Date, title: String, status: ThingStatus) async throws -> Thing
    func saveChanges() async throws
}
