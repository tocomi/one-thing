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
        ZStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

            #if DEBUG
            VStack {
                Spacer()
                debugResetButton
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            #endif
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            if thing.status == .inProgress {
                inProgressContent(thing: thing)
            } else {
                VStack(alignment: .center, spacing: 16) {
                    dateText

                    Text(thing.title)
                        .font(.largeTitle.weight(.semibold))
                        .multilineTextAlignment(.center)
                    Text(thing.isDone ? "Done" : "Not done")
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            unsetContent
        }
    }

    /// 未設定状態の入力 UI を表示する。
    private var unsetContent: some View {
        VStack(alignment: .center, spacing: 24) {
            dateText

            Text(viewModel.unsetPromptText)
                .font(.title.weight(.semibold))
                .multilineTextAlignment(.center)

            TextField("", text: $viewModel.draftTitle, axis: .vertical)
                .font(.title2.weight(.semibold))
                .textFieldStyle(.plain)
                .submitLabel(.done)
                .lineLimit(1...3)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: 320, minHeight: 56, alignment: .leading)
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.secondary.opacity(0.35), lineWidth: 1)
                }
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

    /// 今日の Thing を決めた後、完了までの進行中状態を表示する。
    private func inProgressContent(thing: Thing) -> some View {
        VStack(alignment: .center, spacing: 32) {
            VStack(alignment: .center, spacing: 8) {
                dateText

                if let streakText = viewModel.streakText {
                    Text(streakText)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }

            if viewModel.isEditingTitle {
                editingTitleField
            } else {
                inProgressTitle(thing: thing)
            }

            PrimaryActionButton(title: "できた！") {
                completeThing()
            }
            .disabled(viewModel.isSubmitting || viewModel.isEditingTitle)
        }
    }

    /// 進行中の Thing を見出しと編集操作つきで表示する。
    private func inProgressTitle(thing: Thing) -> some View {
        VStack(alignment: .center, spacing: 10) {
            HStack(spacing: 8) {
                Text("今日のやること")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                Button {
                    viewModel.startEditingTitle()
                } label: {
                    Image(systemName: "pencil")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("編集")
            }

            Text(thing.title)
                .font(.largeTitle.weight(.semibold))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
        }
    }

    /// 進行中のタイトルを編集する入力欄を表示する。
    private var editingTitleField: some View {
        VStack(alignment: .center, spacing: 12) {
            Text("今日のやること")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            TextField("", text: $viewModel.editingTitle, axis: .vertical)
                .font(.largeTitle.weight(.semibold))
                .textFieldStyle(.plain)
                .submitLabel(.done)
                .lineLimit(1...3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: 420, minHeight: 72)
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.secondary.opacity(0.35), lineWidth: 1)
                }
                .onSubmit {
                    saveEditingTitle()
                }

            HStack(spacing: 16) {
                Button("キャンセル") {
                    viewModel.cancelEditingTitle()
                }
                .disabled(viewModel.isSubmitting)

                Button("保存") {
                    saveEditingTitle()
                }
                .disabled(!viewModel.canSaveEditingTitle)
            }
            .font(.subheadline.weight(.medium))
        }
    }

    /// メイン画面で共通して使う今日の日付表示。
    private var dateText: some View {
        Text(viewModel.currentDateText)
            .font(.title3.weight(.medium))
            .foregroundStyle(.secondary)
    }

    /// 入力中の内容を非同期で保存する。
    private func submitDraft() {
        Task {
            await viewModel.submitDraft()
        }
    }

    /// 編集中のタイトルを非同期で保存する。
    private func saveEditingTitle() {
        Task {
            await viewModel.saveEditingTitle()
        }
    }

    /// 現在の Thing を完了状態へ非同期で保存する。
    private func completeThing() {
        Task {
            await viewModel.completeThing()
        }
    }

    #if DEBUG
    /// 開発中だけ表示する保存データのリセットボタン。
    private var debugResetButton: some View {
        Button(role: .destructive) {
            Task {
                await viewModel.resetSavedDataForDebug()
            }
        } label: {
            Text("開発用: 保存データをリセット")
                .font(.footnote)
        }
        .disabled(viewModel.isSubmitting)
    }
    #endif
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
