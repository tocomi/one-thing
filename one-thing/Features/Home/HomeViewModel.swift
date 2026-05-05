import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    var thing: Thing?
    var isLoading = false
    var errorMessage: String?

    private let loadOneThingUseCase: LoadOneThingUseCase

    init(loadOneThingUseCase: LoadOneThingUseCase) {
        self.loadOneThingUseCase = loadOneThingUseCase
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            thing = try await loadOneThingUseCase.execute()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markDone() {
        guard var thing else {
            return
        }

        thing.isDone = true
        self.thing = thing
    }
}
