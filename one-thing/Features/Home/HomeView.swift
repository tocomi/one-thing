import SwiftUI

/// 今日やることの状態表示と完了操作を提供するホーム画面。
struct HomeView: View {
    @State private var viewModel: HomeViewModel

    /// ホーム画面で利用する ViewModel を受け取る。
    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
    }

    /// 今日の日付と現在のタスク状態を配置する。
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            content
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .task {
            await viewModel.load()
        }
    }

    /// 読み込み、エラー、登録済み、未登録の各状態に応じた表示を切り替える。
    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView()
        } else if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .foregroundStyle(.red)
        } else if let thing = viewModel.thing {
            VStack(alignment: .leading, spacing: 16) {
                dateText

                Text(thing.title)
                    .font(.largeTitle.weight(.semibold))
                Text(thing.isDone ? "Done" : "Not done")
                    .foregroundStyle(.secondary)
            }
        } else {
            unsetContent
        }
    }

    /// 未設定状態の入力 UI を表示する。
    private var unsetContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            dateText

            Text(viewModel.unsetPromptText)
                .font(.title.weight(.semibold))

            TextField("", text: $viewModel.draftTitle, axis: .vertical)
                .font(.largeTitle.weight(.semibold))
                .textFieldStyle(.plain)
                .submitLabel(.done)
                .lineLimit(1...3)
                .onSubmit {
                    submitDraft()
                }

            if viewModel.canSubmitDraft {
                PrimaryActionButton(title: "決めた！") {
                    submitDraft()
                }
                .disabled(viewModel.isSubmitting)
            }
        }
    }

    /// メイン画面で共通して使う今日の日付表示。
    private var dateText: some View {
        Text(viewModel.currentDateText)
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    /// 入力中の内容を非同期で保存する。
    private func submitDraft() {
        Task {
            await viewModel.submitDraft()
        }
    }
}

#Preview {
    let repository = InMemoryThingRepository()

    HomeView(
        viewModel: HomeViewModel(
            loadOneThingUseCase: LoadOneThingUseCase(
                repository: repository
            ),
            setOneThingUseCase: SetOneThingUseCase(
                repository: repository
            )
        )
    )
}
