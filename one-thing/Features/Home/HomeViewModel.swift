import Foundation
import Observation

/// HomeView の表示状態を保持し、ユースケースを通じて今日の Thing を操作する。
@MainActor
@Observable
final class HomeViewModel {
    var thing: Thing?
    var draftTitle = ""
    var editingTitle = ""
    var isEditingTitle = false
    var completionMessage = "ひとつ、できた。"
    var isCompletionAnimationVisible = false
    var isLoading = false
    var isSubmitting = false
    var errorMessage: String?
    var suggestions: [String] = []

    private let loadOneThingUseCase: LoadOneThingUseCase
    private let setOneThingUseCase: SetOneThingUseCase
    private let completeOneThingUseCase: CompleteOneThingUseCase
    private let autoRestUseCase: AutoRestUseCase
    private let resetThingDataUseCase: ResetThingDataUseCase
    private let suggestThingsUseCase: SuggestThingsUseCase
    private let notificationUseCase: NotificationUseCase?
    let generateDebugHistoryUseCase: GenerateDebugHistoryUseCase
    private let calendar: Calendar
    private let dateFormatter: DateFormatter
    private let completionMessages = [
        "よくやった。",
        "それだけで、十分。",
        "今日も前に進んだ。",
        "ひとつ、できた。",
        "今日の自分を、ちゃんと褒めて。"
    ]

    /// HomeView で必要なユースケースと日付表示用の依存を受け取る。
    init(
        loadOneThingUseCase: LoadOneThingUseCase,
        setOneThingUseCase: SetOneThingUseCase,
        completeOneThingUseCase: CompleteOneThingUseCase,
        autoRestUseCase: AutoRestUseCase,
        resetThingDataUseCase: ResetThingDataUseCase,
        suggestThingsUseCase: SuggestThingsUseCase,
        notificationUseCase: NotificationUseCase? = nil,
        generateDebugHistoryUseCase: GenerateDebugHistoryUseCase,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.loadOneThingUseCase = loadOneThingUseCase
        self.setOneThingUseCase = setOneThingUseCase
        self.completeOneThingUseCase = completeOneThingUseCase
        self.autoRestUseCase = autoRestUseCase
        self.resetThingDataUseCase = resetThingDataUseCase
        self.suggestThingsUseCase = suggestThingsUseCase
        self.notificationUseCase = notificationUseCase
        self.generateDebugHistoryUseCase = generateDebugHistoryUseCase
        self.calendar = calendar

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日 (E)"
        self.dateFormatter = formatter
    }

    /// 今日の日付をメイン画面向けの日本語表記で返す。
    var currentDateText: String {
        dateFormatter.string(from: Date())
    }

    /// 現在時刻に合わせた未設定状態の促し文を返す。
    var unsetPromptText: String {
        calendar.component(.hour, from: Date()) < 12
            ? "今日は何をする？"
            : "今日やること、決めた？"
    }

    /// 入力内容が保存可能な状態かどうかを返す。
    var canSubmitDraft: Bool {
        !draftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isSubmitting
    }

    /// 編集中のタイトルが保存可能な状態かどうかを返す。
    var canSaveEditingTitle: Bool {
        !editingTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isSubmitting
    }

    /// 今日の Thing を読み込み、画面表示用の状態に反映する。
    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            thing = try await loadOneThingUseCase.execute()
            suggestions = thing == nil ? try await suggestThingsUseCase.execute() : []
            if thing?.status == .done {
                updateCompletionMessage()
            }
            await syncNotifications()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// 日付切り替わりを反映してから、今日の Thing を画面状態へ再読み込みする。
    func refreshForActiveScene() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            _ = try await autoRestUseCase.execute()
            thing = try await loadOneThingUseCase.execute()
            suggestions = thing == nil ? try await suggestThingsUseCase.execute() : []
            draftTitle = ""
            editingTitle = ""
            isEditingTitle = false
            if thing?.status == .done {
                updateCompletionMessage()
            }
            await syncNotifications()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// 入力中のタイトルを今日の Thing として保存する。
    func submitDraft() async {
        let title = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            return
        }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            thing = try await setOneThingUseCase.execute(title: title)
            draftTitle = ""
            suggestions = []
            await syncNotifications()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// 現在のタイトルを編集状態へ移す。
    func startEditingTitle() {
        guard let thing else {
            return
        }

        editingTitle = thing.title
        isEditingTitle = true
    }

    /// タイトル編集を破棄して表示状態に戻す。
    func cancelEditingTitle() {
        editingTitle = ""
        isEditingTitle = false
    }

    /// 編集中のタイトルを保存して進行中状態を更新する。
    func saveEditingTitle() async {
        let title = editingTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            return
        }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            thing = try await setOneThingUseCase.execute(title: title)
            editingTitle = ""
            isEditingTitle = false
            await syncNotifications()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// 今日の Thing を完了状態に更新する。
    func completeThing() async {
        guard thing != nil else {
            return
        }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            thing = try await completeOneThingUseCase.execute()
            isEditingTitle = false
            editingTitle = ""
            updateCompletionMessage()
            await syncNotifications()
            playCompletionAnimation()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// 開発中の確認用に保存済みデータを削除し、未設定状態へ戻す。
    func resetSavedDataForDebug() async {
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            try await resetThingDataUseCase.execute()
            thing = nil
            draftTitle = ""
            editingTitle = ""
            isEditingTitle = false
            isCompletionAnimationVisible = false
            suggestions = try await suggestThingsUseCase.execute()
            await syncNotifications()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// 履歴候補を入力欄に反映する。
    func selectSuggestion(_ suggestion: String) {
        draftTitle = suggestion
    }

    /// 完了状態で表示する称賛メッセージを選ぶ。
    private func updateCompletionMessage() {
        completionMessage = completionMessages.randomElement() ?? completionMessage
    }

    /// 完了直後だけ表示する短いアニメーション状態を管理する。
    private func playCompletionAnimation() {
        isCompletionAnimationVisible = true

        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(900))
            self?.isCompletionAnimationVisible = false
        }
    }

    /// 現在の Thing と設定に合わせてローカル通知予約を更新する。
    private func syncNotifications() async {
        try? await notificationUseCase?.execute()
    }
}
