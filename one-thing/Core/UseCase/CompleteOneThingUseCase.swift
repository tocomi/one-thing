import Foundation

enum CompleteOneThingUseCaseError: Error, Equatable {
    case thingNotFound
}

struct CompleteOneThingUseCase {
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
    ) async throws -> Thing {
        let today = dayBoundaryUseCase.execute(
            now: now,
            dayBoundaryHour: dayBoundaryHour
        )

        guard let thing = try await repository.fetchThing(on: today) else {
            throw CompleteOneThingUseCaseError.thingNotFound
        }

        thing.status = .done
        try await repository.saveChanges()
        return thing
    }
}
