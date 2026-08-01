import Foundation

/// 完了時に表示する称賛メッセージの候補。
private enum CompletionMessages {
    static let all = [
        "よくやった。",
        "それだけで、十分。",
        "今日も前に進んだ。",
        "ひとつ、できた。",
        "今日の自分を、ちゃんと褒めて。"
    ]
}

extension HomeViewModel {
    /// 完了状態で表示する称賛メッセージを選ぶ。
    func updateCompletionMessage() {
        completionMessage = CompletionMessages.all.randomElement() ?? completionMessage
    }

    /// 完了直後だけ表示する短いアニメーション状態を管理する。
    func playCompletionAnimation() {
        isCompletionAnimationVisible = true

        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(900))
            self?.isCompletionAnimationVisible = false
        }
    }
}
