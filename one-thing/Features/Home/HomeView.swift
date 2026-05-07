import SwiftUI

/// 今日やることの状態表示と完了操作を提供するホーム画面。
struct HomeView: View {
    @State private var viewModel: HomeViewModel
    #if DEBUG
    @State private var isDebugMenuPresented = false
    #endif

    /// ホーム画面で利用する ViewModel を受け取る。
    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            contentArea

            #if DEBUG
            debugMenuButton
            #endif
        }
        .task {
            await viewModel.load()
        }
        #if DEBUG
        .sheet(isPresented: $isDebugMenuPresented) {
            DebugMenuView(viewModel: viewModel)
        }
        #endif
        .animation(.spring(duration: 0.42, bounce: 0.05), value: viewModel.isLoading)
        .animation(.spring(duration: 0.42, bounce: 0.05), value: viewModel.thing == nil)
        .animation(.spring(duration: 0.42, bounce: 0.05), value: viewModel.thing?.status)
    }

    // MARK: - Content routing

    @ViewBuilder
    private var contentArea: some View {
        if viewModel.isLoading {
            ProgressView()
                .tint(Color.appAccent)
        } else if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .font(.subheadline)
                .foregroundStyle(Color.appSecondary)
                .multilineTextAlignment(.center)
                .padding(32)
        } else if let thing = viewModel.thing {
            if thing.status == .inProgress {
                inProgressView(thing: thing)
                    .transition(.opacity)
            } else {
                HomeDoneView(
                    thing: thing,
                    dateText: viewModel.currentDateText,
                    message: viewModel.completionMessage,
                    streakText: viewModel.streakText,
                    isAnimationVisible: viewModel.isCompletionAnimationVisible
                )
                    .transition(.opacity)
            }
        } else {
            unsetView
                .transition(.opacity)
        }
    }

    // MARK: - Unset state

    /// タスクがまだ設定されていない状態の入力 UI。
    private var unsetView: some View {
        VStack(spacing: 0) {
            dateLabel
                .padding(.top, 20)

            Spacer()

            VStack(spacing: 20) {
                Text(viewModel.unsetPromptText)
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.appPrimary)
                    .multilineTextAlignment(.center)

                draftTextField
            }
            .padding(.horizontal, 32)

            Spacer()

            PrimaryActionButton(title: "決めた！") {
                submitDraft()
            }
            .disabled(!viewModel.canSubmitDraft || viewModel.isSubmitting)
            .padding(.horizontal, 32)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var draftTextField: some View {
        ThingTextField(placeholder: "今日やること...", text: $viewModel.draftTitle) {
            submitDraft()
        }
    }

    // MARK: - In-progress state

    /// タスクが設定済みで完了前の状態。
    private func inProgressView(thing: Thing) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                dateLabel
                if let streakText = viewModel.streakText {
                    streakBadge(text: streakText)
                }
            }
            .padding(.top, 20)

            Spacer()

            Group {
                if viewModel.isEditingTitle {
                    editingView
                        .transition(.opacity)
                } else {
                    taskHero(thing: thing)
                        .transition(.opacity)
                }
            }
            .animation(.spring(duration: 0.32, bounce: 0.0), value: viewModel.isEditingTitle)

            Spacer()

            if !viewModel.isEditingTitle {
                PrimaryActionButton(title: "できた！") {
                    completeThing()
                }
                .disabled(viewModel.isSubmitting)
                .padding(.horizontal, 32)
                .padding(.bottom, 8)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// タスクタイトルをヒーローとして大きく表示し、編集ボタンを添える。
    private func taskHero(thing: Thing) -> some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text("今日のやること")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(Color.appSecondary)
                    .tracking(0.3)

                Rectangle()
                    .fill(Color.appDivider)
                    .frame(maxWidth: 180, maxHeight: 1)
            }

            Text(thing.title)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .frame(maxWidth: 380)

            Button {
                viewModel.startEditingTitle()
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "pencil")
                        .font(.system(size: 11, weight: .semibold))
                    Text("変更")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                }
                .foregroundStyle(Color.appAccent)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.appAccentSubtle, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("編集")
        }
        .padding(.horizontal, 32)
    }

    /// 進行中タスクのタイトルを編集する入力欄と操作ボタン。
    private var editingView: some View {
        VStack(spacing: 20) {
            Text("今日のやること")
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(Color.appSecondary)
                .tracking(0.3)

            ThingTextField(placeholder: "", text: $viewModel.editingTitle) {
                saveEditingTitle()
            }

            HStack(spacing: 14) {
                Button("キャンセル") {
                    viewModel.cancelEditingTitle()
                }
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(Color.appSecondary)
                .disabled(viewModel.isSubmitting)

                Button {
                    saveEditingTitle()
                } label: {
                    Text("保存")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 11)
                        .background(Color.appAccent, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canSaveEditingTitle)
            }
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Shared components

    private var dateLabel: some View {
        Text(viewModel.currentDateText)
            .font(.system(.title3, design: .rounded, weight: .medium))
            .foregroundStyle(Color.appSecondary)
            .tracking(0.3)
    }

    /// 連続達成日数を炎アイコンとともにカプセル型で表示する。
    private func streakBadge(text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.system(size: 11, weight: .semibold))
            Text(text)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .tracking(0.2)
        }
        .foregroundStyle(Color.appAccent)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.appAccentSubtle, in: Capsule())
    }

    // MARK: - Actions

    private func submitDraft() {
        Task { await viewModel.submitDraft() }
    }

    private func saveEditingTitle() {
        Task { await viewModel.saveEditingTitle() }
    }

    private func completeThing() {
        Task { await viewModel.completeThing() }
    }

    // MARK: - Debug

    #if DEBUG
    private var debugMenuButton: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    isDebugMenuPresented = true
                } label: {
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.appSecondary.opacity(0.5))
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 20)
            .padding(.trailing, 20)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    #endif
}
