import Foundation

@MainActor
protocol ThingRepository {
    func fetchThing(on date: Date) async throws -> Thing?
    func fetchThings(from startDate: Date, to endDate: Date) async throws -> [Thing]
    func createThing(date: Date, title: String, status: ThingStatus) async throws -> Thing
    func saveChanges() async throws
}
