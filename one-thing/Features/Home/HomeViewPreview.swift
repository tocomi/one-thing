import SwiftUI

#Preview {
    let repository = InMemoryThingRepository()

    HomeView(
        viewModel: HomeViewModel(
            loadOneThingUseCase: LoadOneThingUseCase(
                repository: repository
            ),
            setOneThingUseCase: SetOneThingUseCase(
                repository: repository
            ),
            completeOneThingUseCase: CompleteOneThingUseCase(
                repository: repository
            ),
            calculateStreakUseCase: CalculateStreakUseCase(
                repository: repository
            ),
            resetThingDataUseCase: ResetThingDataUseCase(
                repository: repository
            )
        )
    )
}
