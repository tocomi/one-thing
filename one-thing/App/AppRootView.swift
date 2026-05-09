import SwiftUI

/// アプリ全体の画面構成と feature への依存関係注入を担当するルート View。
struct AppRootView: View {
    private let repository: ThingRepository

    /// ルート配下で利用する ThingRepository を受け取る。
    init(repository: ThingRepository) {
        self.repository = repository
    }

    /// Home feature の初期画面を組み立てる。
    var body: some View {
        let notificationUseCase = NotificationUseCase(
            repository: repository,
            notificationScheduler: NotificationService()
        )

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
                notificationUseCase: notificationUseCase,
                generateDebugHistoryUseCase: GenerateDebugHistoryUseCase(
                    repository: repository
                )
            ),
            historyViewModel: HistoryViewModel(
                loadHistoryUseCase: LoadHistoryUseCase(
                    repository: repository
                ),
                editHistoryUseCase: EditHistoryUseCase(
                    repository: repository
                ),
                deleteHistoryUseCase: DeleteHistoryUseCase(
                    repository: repository
                )
            ),
            notificationUseCase: notificationUseCase
        )
    }
}

#Preview {
    AppRootView(repository: InMemoryThingRepository())
}
