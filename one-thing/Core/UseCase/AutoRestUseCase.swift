import Foundation

struct AutoRestUseCase {
    private let repository: ThingRepository
    private let dayBoundaryUseCase: DayBoundaryUseCase
    private let calendar: Calendar

    init(
        repository: ThingRepository,
        dayBoundaryUseCase: DayBoundaryUseCase = DayBoundaryUseCase(),
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.repository = repository
        self.dayBoundaryUseCase = dayBoundaryUseCase
        self.calendar = calendar
    }

    @discardableResult
    func execute(
        now: Date = Date(),
        dayBoundaryHour: Int = DayBoundaryUseCase.defaultBoundaryHour
    ) async throws -> Thing? {
        let today = dayBoundaryUseCase.execute(
            now: now,
            dayBoundaryHour: dayBoundaryHour
        )

        guard let previousDay = calendar.date(byAdding: .day, value: -1, to: today),
              let thing = try await repository.fetchThing(on: previousDay),
              thing.status == .inProgress else {
            return nil
        }

        thing.status = .rested
        try await repository.saveChanges()
        return thing
    }
}
