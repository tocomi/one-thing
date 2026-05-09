import SwiftUI

/// 今日やることの状態表示と完了操作を提供するホーム画面。
struct HomeView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel: HomeViewModel
    @State private var historyViewModel: HistoryViewModel
    private let notificationUseCase: NotificationUseCase?
    @State private var presentedSheet: HomeSheet?

    /// ホーム画面で利用する ViewModel を受け取る。
    init(viewModel: HomeViewModel, historyViewModel: HistoryViewModel, notificationUseCase: NotificationUseCase? = nil) {
        self.viewModel = viewModel
        self.historyViewModel = historyViewModel
        self.notificationUseCase = notificationUseCase
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            contentArea
            HomeHeaderView(isHistoryPresented: historyPresentationBinding, isSettingsPresented: settingsPresentationBinding)
            #if DEBUG
            HomeDebugMenuButton(isPresented: debugMenuPresentationBinding)
            #endif
        }
        .task {
            await viewModel.refreshForActiveScene()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else {
                return
            }

            Task {
                await viewModel.refreshForActiveScene()
            }
        }
        .sheet(item: $presentedSheet) { sheetContent(for: $0) }
        .animation(.spring(duration: 0.42, bounce: 0.05), value: viewModel.isLoading)
        .animation(.spring(duration: 0.42, bounce: 0.05), value: viewModel.thing == nil)
        .animation(.spring(duration: 0.42, bounce: 0.05), value: viewModel.thing?.status)
    }

    // MARK: - Content routing

    private var historyPresentationBinding: Binding<Bool> {
        presentationBinding(for: .history)
    }

    private var settingsPresentationBinding: Binding<Bool> {
        presentationBinding(for: .settings)
    }

    #if DEBUG
    private var debugMenuPresentationBinding: Binding<Bool> {
        presentationBinding(for: .debugMenu)
    }
    #endif

    private func presentationBinding(for sheet: HomeSheet) -> Binding<Bool> {
        Binding(
            get: { presentedSheet == sheet },
            set: { isPresented in
                if isPresented {
                    present(sheet)
                } else if presentedSheet == sheet {
                    presentedSheet = nil
                }
            }
        )
    }

    private func present(_ sheet: HomeSheet) {
        if sheet == .history {
            historyViewModel.prepareForPresentation()
        }

        presentedSheet = sheet
    }

    @ViewBuilder
    private func sheetContent(for sheet: HomeSheet) -> some View {
        switch sheet {
        case .history:
            HistoryView(viewModel: historyViewModel)
        case .settings:
            SettingsView(viewModel: SettingsViewModel(notificationUseCase: notificationUseCase))
        #if DEBUG
        case .debugMenu:
            DebugMenuView(viewModel: viewModel)
        #endif
        }
    }

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
                    isAnimationVisible: viewModel.isCompletionAnimationVisible
                )
                    .transition(.opacity)
            }
        } else {
            HomeUnsetView(
                dateText: viewModel.currentDateText,
                promptText: viewModel.unsetPromptText,
                draftTitle: $viewModel.draftTitle,
                suggestions: viewModel.suggestions,
                canSubmitDraft: viewModel.canSubmitDraft,
                isSubmitting: viewModel.isSubmitting,
                selectSuggestion: viewModel.selectSuggestion,
                submitDraft: submitDraft
            )
                .transition(.opacity)
        }
    }

    // MARK: - In-progress state

    /// タスクが設定済みで完了前の状態。
    private func inProgressView(thing: Thing) -> some View {
        VStack(spacing: 0) {
            dateLabel
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

            ThingTextField(placeholder: "", text: $viewModel.editingTitle)

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
            .frame(height: 44)
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

}
