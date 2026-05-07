#if DEBUG
import Foundation

extension HomeViewModel {
    /// 開発確認用に過去 1 か月のランダムな履歴を作成し、Home の表示を更新する。
    func generateRandomHistoryForDebug() async {
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            try await generateDebugHistoryUseCase.execute()
            await refreshForActiveScene()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
#endif
