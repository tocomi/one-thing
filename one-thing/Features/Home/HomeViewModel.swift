import Foundation
import Observation

/// HomeView の表示状態を保持し、ユースケースを通じて今日の Thing を読み込む。
@MainActor
@Observable
final class HomeViewModel {
    var thing: Thing?
    var isLoading = false
    var errorMessage: String?

    private let loadOneThingUseCase: LoadOneThingUseCase

    /// HomeView で必要な読み込みユースケースを受け取る。
    init(loadOneThingUseCase: LoadOneThingUseCase) {
        self.loadOneThingUseCase = loadOneThingUseCase
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

    /// 現在表示中の Thing を完了状態へ変更する。
    func markDone() {
        guard let thing else {
            return
        }

        thing.status = .done
    }
}
