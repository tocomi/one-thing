import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel

    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
    }

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
