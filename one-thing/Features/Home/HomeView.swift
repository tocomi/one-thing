import SwiftUI

/// 今日の「ひとつのこと」の状態表示と完了操作を提供するホーム画面。
struct HomeView: View {
    @State private var viewModel: HomeViewModel

    /// ホーム画面で利用する ViewModel を受け取る。
    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
    }

    /// タイトル、現在のタスク状態、完了ボタンを配置する。
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("One Thing")
                .font(.largeTitle.bold())

            content

            PrimaryActionButton(title: "Mark Done") {
                viewModel.markDone()
            }
            .disabled(viewModel.thing == nil)
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
            VStack(alignment: .leading, spacing: 8) {
                Text(thing.title)
                    .font(.title2)
                Text(thing.isDone ? "Done" : "Not done")
                    .foregroundStyle(.secondary)
            }
        } else {
            Text("今日はまだ決まっていません")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    HomeView(
        viewModel: HomeViewModel(
            loadOneThingUseCase: LoadOneThingUseCase(
                repository: InMemoryThingRepository()
            )
        )
    )
}
