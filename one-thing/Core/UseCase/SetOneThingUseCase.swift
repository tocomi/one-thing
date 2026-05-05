import Foundation

struct SetOneThingUseCase {
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
        title: String,
        now: Date = Date(),
        dayBoundaryHour: Int = DayBoundaryUseCase.defaultBoundaryHour
    ) async throws -> Thing {
        let today = dayBoundaryUseCase.execute(
            now: now,
            dayBoundaryHour: dayBoundaryHour
        )

        if let thing = try await repository.fetchThing(on: today) {
            thing.title = title
            thing.status = .inProgress
            try await repository.saveChanges()
            return thing
        }

        return try await repository.createThing(
            date: today,
            title: title,
            status: .inProgress
        )
    }
}
