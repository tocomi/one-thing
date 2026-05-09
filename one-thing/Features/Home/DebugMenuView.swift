#if DEBUG
import SwiftUI

/// 開発中のみ表示するデバッグ操作メニュー。
struct DebugMenuView: View {
    let viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("データ") {
                    Button {
                        Task {
                            await viewModel.generateRandomHistoryForDebug()
                            dismiss()
                        }
                    } label: {
                        Label("過去1か月の履歴を作成", systemImage: "calendar.badge.plus")
                    }
                    .disabled(viewModel.isSubmitting)

                    Button(role: .destructive) {
                        Task {
                            await viewModel.resetSavedDataForDebug()
                            dismiss()
                        }
                    } label: {
                        Label("履歴をリセット", systemImage: "trash")
                    }
                    .disabled(viewModel.isSubmitting)
                }
            }
            .navigationTitle("開発メニュー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    let repository = InMemoryThingRepository()
    DebugMenuView(
        viewModel: HomeViewModel(
            loadOneThingUseCase: LoadOneThingUseCase(repository: repository),
            setOneThingUseCase: SetOneThingUseCase(repository: repository),
            completeOneThingUseCase: CompleteOneThingUseCase(repository: repository),
            autoRestUseCase: AutoRestUseCase(repository: repository),
            resetThingDataUseCase: ResetThingDataUseCase(repository: repository),
            suggestThingsUseCase: SuggestThingsUseCase(repository: repository),
            generateDebugHistoryUseCase: GenerateDebugHistoryUseCase(repository: repository)
        )
    )
}
#endif
