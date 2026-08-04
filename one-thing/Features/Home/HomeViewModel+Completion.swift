import Foundation

/// 完了時に表示する称賛メッセージの候補と、その選び方。
enum CompletionMessages {
    static let all = [
        "よくやった。",
        "それだけで、十分。",
        "今日も前に進んだ。",
        "ひとつ、できた。",
        "今日の自分を、ちゃんと褒めて。"
    ]

    /// 対象の Thing に対して常に同じメッセージを返す。
    ///
    /// シートの開閉やシーン復帰、アプリの再起動でも完了画面は読み込み直されるため、
    /// 都度抽選するとメッセージが入れ替わってしまう。識別子から決めることで表示を固定する。
    /// `hashValue` は起動ごとに変わるので使わず、識別子のバイト列から添字を求める。
    static func message(for thingID: UUID) -> String {
        let bytes = withUnsafeBytes(of: thingID.uuid) { Array($0) }
        let index = bytes.reduce(0) { ($0 &+ Int($1)) % all.count }
        return all[index]
    }
}

extension HomeViewModel {
    /// 完了状態で表示する称賛メッセージを、対象の Thing に合わせて反映する。
    func updateCompletionMessage(for thingID: UUID) {
        completionMessage = CompletionMessages.message(for: thingID)
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
