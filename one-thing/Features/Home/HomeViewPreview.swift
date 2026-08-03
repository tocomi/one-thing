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
            resetThingDataUseCase: ResetThingDataUseCase(
                repository: repository
            ),
            suggestThingsUseCase: SuggestThingsUseCase(
                repository: repository
            ),
            generateDebugHistoryUseCase: GenerateDebugHistoryUseCase(
                repository: repository
            )
        ),
        historyViewModel: HistoryViewModel(
            loadHistoryUseCase: LoadHistoryUseCase(
                repository: repository
            ),
            loadEarliestHistoryDateUseCase: LoadEarliestHistoryDateUseCase(
                repository: repository
            ),
            editHistoryUseCase: EditHistoryUseCase(
                repository: repository
            ),
            deleteHistoryUseCase: DeleteHistoryUseCase(
                repository: repository
            )
        )
    )
}
