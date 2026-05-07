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
    var streakCount = 0
    var isLoading = false
    var isSubmitting = false
    var errorMessage: String?

    private let loadOneThingUseCase: LoadOneThingUseCase
    private let setOneThingUseCase: SetOneThingUseCase
    private let completeOneThingUseCase: CompleteOneThingUseCase
    private let autoRestUseCase: AutoRestUseCase
    private let calculateStreakUseCase: CalculateStreakUseCase
    private let resetThingDataUseCase: ResetThingDataUseCase
    private let dayBoundaryUseCase: DayBoundaryUseCase
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
        calculateStreakUseCase: CalculateStreakUseCase,
        resetThingDataUseCase: ResetThingDataUseCase,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.loadOneThingUseCase = loadOneThingUseCase
        self.setOneThingUseCase = setOneThingUseCase
        self.completeOneThingUseCase = completeOneThingUseCase
        self.autoRestUseCase = autoRestUseCase
        self.calculateStreakUseCase = calculateStreakUseCase
        self.resetThingDataUseCase = resetThingDataUseCase
        self.dayBoundaryUseCase = DayBoundaryUseCase(calendar: calendar)
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

    /// 連続達成日数をメイン画面向けの文言で返す。
    var streakText: String? {
        streakCount > 0 ? "\(streakCount)日連続達成中" : nil
    }

    /// 今日の Thing を読み込み、画面表示用の状態に反映する。
    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            thing = try await loadOneThingUseCase.execute()
            if thing?.status == .done {
                updateCompletionMessage()
            }
            try await refreshStreak()
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
            draftTitle = ""
            editingTitle = ""
            isEditingTitle = false
            if thing?.status == .done {
                updateCompletionMessage()
            }
            try await refreshStreak()
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
            try await refreshStreak()
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
            try await refreshStreak()
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
            try await refreshStreak()
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
            streakCount = 0
        } catch {
            errorMessage = error.localizedDescription
        }
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

    /// 現在の表示状態に合わせて連続達成日数を更新する。
    private func refreshStreak() async throws {
        if thing?.status == .inProgress,
           let previousDayReferenceDate {
            streakCount = try await calculateStreakUseCase.execute(now: previousDayReferenceDate)
            return
        }

        streakCount = try await calculateStreakUseCase.execute()
    }

    /// アプリ上の今日の前日をストリーク計算に渡すための基準日時を返す。
    private var previousDayReferenceDate: Date? {
        let appToday = dayBoundaryUseCase.execute()

        guard let previousDay = calendar.date(byAdding: .day, value: -1, to: appToday) else {
            return nil
        }

        return calendar.date(
            byAdding: .hour,
            value: DayBoundaryUseCase.defaultBoundaryHour,
            to: previousDay
        )
    }
}
