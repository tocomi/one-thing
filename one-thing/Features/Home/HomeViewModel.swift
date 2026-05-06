import Foundation
import Observation

/// HomeView の表示状態を保持し、ユースケースを通じて今日の Thing を操作する。
@MainActor
@Observable
final class HomeViewModel {
    var thing: Thing?
    var draftTitle = ""
    var isLoading = false
    var isSubmitting = false
    var errorMessage: String?

    private let loadOneThingUseCase: LoadOneThingUseCase
    private let setOneThingUseCase: SetOneThingUseCase
    private let resetThingDataUseCase: ResetThingDataUseCase
    private let calendar: Calendar
    private let dateFormatter: DateFormatter

    /// HomeView で必要なユースケースと日付表示用の依存を受け取る。
    init(
        loadOneThingUseCase: LoadOneThingUseCase,
        setOneThingUseCase: SetOneThingUseCase,
        resetThingDataUseCase: ResetThingDataUseCase,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.loadOneThingUseCase = loadOneThingUseCase
        self.setOneThingUseCase = setOneThingUseCase
        self.resetThingDataUseCase = resetThingDataUseCase
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

    /// 今日の Thing を読み込み、画面表示用の状態に反映する。
    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            thing = try await loadOneThingUseCase.execute()
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
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// 現在表示中の Thing を完了状態へ変更する。
    func markDone() {
        guard let thing else {
            return
        }

        thing.status = .done
    }
}
