import SwiftUI

/// 今日やることの状態表示と完了操作を提供するホーム画面。
struct HomeView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel: HomeViewModel
    @State private var historyViewModel: HistoryViewModel
    private let makeSettingsViewModel: () -> SettingsViewModel
    @State private var presentedSheet: HomeSheet?

    /// ホーム画面で利用する ViewModel と、設定シートを開くたびに使う ViewModel の生成方法を受け取る。
    /// 設定シートの依存を外から渡すことで、Preview から実際の設定や通知許可へ触れないようにする。
    init(
        viewModel: HomeViewModel,
        historyViewModel: HistoryViewModel,
        makeSettingsViewModel: @escaping () -> SettingsViewModel
    ) {
        self.viewModel = viewModel
        self.historyViewModel = historyViewModel
        self.makeSettingsViewModel = makeSettingsViewModel
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            contentArea
            HomeHeaderView(
                isHistoryPresented: historyPresentationBinding,
                isSettingsPresented: settingsPresentationBinding
            )
            #if DEBUG
            HomeDebugMenuButton(isPresented: debugMenuPresentationBinding)
            #endif
        }
        .task {
            await viewModel.refreshForActiveScene(displaysLoading: true)
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else {
                return
            }

            Task {
                await viewModel.refreshForActiveScene()
            }
        }
        .sheet(item: $presentedSheet, onDismiss: refreshAfterSheetDismissal) { sheetContent(for: $0) }
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
            SettingsView(viewModel: makeSettingsViewModel())
        #if DEBUG
        case .debugMenu:
            DebugMenuView(viewModel: viewModel)
        #endif
        }
    }

    /// Sheet での変更を、ホーム画面を差し替えずに表示へ反映する。
    private func refreshAfterSheetDismissal() {
        Task {
            await viewModel.refreshForActiveScene()
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
                HomeInProgressView(
                    thing: thing,
                    dateText: viewModel.currentDateText,
                    editingTitle: $viewModel.editingTitle,
                    isEditingTitle: viewModel.isEditingTitle,
                    canSaveEditingTitle: viewModel.canSaveEditingTitle,
                    isSubmitting: viewModel.isSubmitting,
                    startEditingTitle: viewModel.startEditingTitle,
                    cancelEditingTitle: viewModel.cancelEditingTitle,
                    saveEditingTitle: saveEditingTitle,
                    completeThing: completeThing
                )
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
