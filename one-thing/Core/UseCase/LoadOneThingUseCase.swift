struct LoadOneThingUseCase {
    private let repository: ThingRepository

    init(repository: ThingRepository) {
        self.repository = repository
    }

    func execute() async throws -> Thing {
        try await repository.fetchCurrentThing()
    }
}
