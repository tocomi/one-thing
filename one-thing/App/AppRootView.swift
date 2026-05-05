import SwiftUI

struct AppRootView: View {
    var body: some View {
        HomeView(
            viewModel: HomeViewModel(
                loadOneThingUseCase: LoadOneThingUseCase(
                    repository: InMemoryThingRepository()
                )
            )
        )
    }
}

#Preview {
    AppRootView()
}
