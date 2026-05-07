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
            autoRestUseCase: AutoRestUseCase(
                repository: repository
            ),
            calculateStreakUseCase: CalculateStreakUseCase(
                repository: repository
            ),
            resetThingDataUseCase: ResetThingDataUseCase(
                repository: repository
            )
        ),
        historyViewModel: HistoryViewModel(
            loadHistoryUseCase: LoadHistoryUseCase(
                repository: repository
            ),
            editHistoryUseCase: EditHistoryUseCase(
                repository: repository,
                calculateStreakUseCase: CalculateStreakUseCase(
                    repository: repository
                )
            )
        )
    )
}
