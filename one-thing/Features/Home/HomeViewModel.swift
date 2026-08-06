import Foundation
import Observation

/// HomeView の表示状態を保持し、ユースケースを通じて今日の Thing を操作する。
@MainActor
@Observable
final class HomeViewModel {
    var thing: ThingSnapshot?
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
    private let userDefaults: UserDefaults
    private let dayBoundaryUseCase: DayBoundaryUseCase
    private let nowProvider: () -> Date
    private let dateFormatter: DateFormatter

    /// HomeView で必要なユースケースと、日付表示や日付境界の判定に使う依存を受け取る。
    /// `nowProvider` は現在時刻の取得を差し替えるためのもので、テストでは固定時刻を渡す。
    init(
        loadOneThingUseCase: LoadOneThingUseCase,
        setOneThingUseCase: SetOneThingUseCase,
        completeOneThingUseCase: CompleteOneThingUseCase,
        autoRestUseCase: AutoRestUseCase,
        resetThingDataUseCase: ResetThingDataUseCase,
        suggestThingsUseCase: SuggestThingsUseCase,
        notificationUseCase: NotificationUseCase? = nil,
        generateDebugHistoryUseCase: GenerateDebugHistoryUseCase,
        calendar: Calendar = .autoupdatingCurrent,
        userDefaults: UserDefaults = .standard,
        dayBoundaryUseCase: DayBoundaryUseCase? = nil,
        nowProvider: @escaping () -> Date = { Date() }
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
        self.userDefaults = userDefaults
        self.dayBoundaryUseCase = dayBoundaryUseCase ?? DayBoundaryUseCase(calendar: calendar)
        self.nowProvider = nowProvider

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日 (E)"
        dateFormatter = formatter
    }

    /// 今日の日付をメイン画面向けの日本語表記で返す。
    var currentDateText: String {
        dateFormatter.string(from: appToday())
    }

    /// 現在時刻に合わせた未設定状態の促し文を返す。
    var unsetPromptText: String {
        calendar.component(.hour, from: nowProvider()) < 12
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
            // 1 回の処理内で参照する現在時刻は揃える。
            let now = nowProvider()
            try await applyTodayState(now: now, boundaryMinutes: currentDayBoundaryMinutes)
            await syncNotifications()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// 日付切り替わりを反映してから、今日の Thing を画面状態へ再読み込みする。
    func refreshForActiveScene(displaysLoading: Bool = false) async {
        if displaysLoading {
            isLoading = true
        }
        errorMessage = nil
        defer {
            if displaysLoading {
                isLoading = false
            }
        }

        do {
            let now = nowProvider()
            let boundaryMinutes = currentDayBoundaryMinutes
            _ = try await autoRestUseCase.execute(now: now, dayBoundaryMinutes: boundaryMinutes)
            try await applyTodayState(now: now, boundaryMinutes: boundaryMinutes)
            draftTitle = ""
            editingTitle = ""
            isEditingTitle = false
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
            thing = try await ThingSnapshot(
                setOneThingUseCase.execute(
                    title: title,
                    now: nowProvider(),
                    dayBoundaryMinutes: currentDayBoundaryMinutes
                )
            )
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
            thing = try await ThingSnapshot(
                setOneThingUseCase.execute(
                    title: title,
                    now: nowProvider(),
                    dayBoundaryMinutes: currentDayBoundaryMinutes
                )
            )
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
            thing = try await ThingSnapshot(
                completeOneThingUseCase.execute(
                    now: nowProvider(),
                    dayBoundaryMinutes: currentDayBoundaryMinutes
                )
            )
            isEditingTitle = false
            editingTitle = ""
            if let thing {
                updateCompletionMessage(for: thing.id)
            }
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
            suggestions = try await suggestThingsUseCase.execute(
                now: nowProvider(),
                dayBoundaryMinutes: currentDayBoundaryMinutes
            )
            await syncNotifications()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// 履歴候補を入力欄に反映する。
    func selectSuggestion(_ suggestion: String) {
        draftTitle = suggestion
    }

    /// 今日の Thing と候補、完了メッセージを読み込んで画面状態へ反映する。
    /// 初回読み込みと再読み込みで同じ結果になるよう、両方からこの処理を通す。
    private func applyTodayState(now: Date, boundaryMinutes: Int) async throws {
        let loaded = try await loadOneThingUseCase.execute(
            now: now,
            dayBoundaryMinutes: boundaryMinutes
        )
        .map(ThingSnapshot.init)
        thing = displayedThing(loaded)
        suggestions = thing == nil
            ? try await suggestThingsUseCase.execute(
                now: now,
                dayBoundaryMinutes: boundaryMinutes
            )
            : []
        if let thing, thing.status == .done {
            updateCompletionMessage(for: thing.id)
        }
    }

    /// ホーム画面に出す今日の Thing を返す。出さない記録は未設定と同じ nil に寄せる。
    ///
    /// 「休んだ」は日付が切り替わるときに前日へ付く結果で、今日に残っていても完了として見せる状態ではない。
    /// 履歴から今日を書き換えられなくしてもデータとしては起こりうるため、ここで未設定に正規化し、
    /// 完了演出や完了メッセージではなく今日のことを決め直す画面を出す。
    private func displayedThing(_ thing: ThingSnapshot?) -> ThingSnapshot? {
        switch thing?.status {
        case .inProgress, .done:
            thing
        default:
            nil
        }
    }

    /// 現在の Thing と設定に合わせてローカル通知予約を更新する。
    private func syncNotifications() async {
        try? await notificationUseCase?.execute()
    }

    private var currentDayBoundaryMinutes: Int {
        userDefaults.object(forKey: SettingsKeys.dayBoundaryMinutes) == nil
            ? DayBoundaryUseCase.defaultBoundaryMinutes
            : userDefaults.integer(forKey: SettingsKeys.dayBoundaryMinutes)
    }

    private func appToday() -> Date {
        dayBoundaryUseCase.execute(
            now: nowProvider(),
            dayBoundaryMinutes: currentDayBoundaryMinutes
        )
    }
}
