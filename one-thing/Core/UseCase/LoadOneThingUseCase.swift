import Foundation

struct LoadOneThingUseCase {
    private let repository: ThingRepository
    private let dayBoundaryUseCase: DayBoundaryUseCase

    init(
        repository: ThingRepository,
        dayBoundaryUseCase: DayBoundaryUseCase = DayBoundaryUseCase()
    ) {
        self.repository = repository
        self.dayBoundaryUseCase = dayBoundaryUseCase
    }

    func execute(
        now: Date = Date(),
        dayBoundaryHour: Int = DayBoundaryUseCase.defaultBoundaryHour
    ) async throws -> Thing? {
        let today = dayBoundaryUseCase.execute(
            now: now,
            dayBoundaryHour: dayBoundaryHour
        )

        return try await repository.fetchThing(on: today)
    }
}
