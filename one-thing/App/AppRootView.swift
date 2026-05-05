import SwiftUI

struct AppRootView: View {
    private let repository: ThingRepository

    init(repository: ThingRepository) {
        self.repository = repository
    }

    var body: some View {
        HomeView(
            viewModel: HomeViewModel(
                loadOneThingUseCase: LoadOneThingUseCase(
                    repository: repository
                )
            )
        )
    }
}

#Preview {
    AppRootView(repository: InMemoryThingRepository())
}
