#if DEBUG
import Foundation

/// 実際の許可ダイアログを出さず、決めた結果だけを返す Preview 用の通知許可要求先。
struct PreviewNotificationAuthorizing: NotificationAuthorizing {
    private let isGranted: Bool

    /// 許可を求めたときに返す結果を受け取る。
    init(isGranted: Bool = true) {
        self.isGranted = isGranted
    }

    /// OS へ問い合わせず、あらかじめ決めた結果を返す。
    func requestAuthorization() async throws -> Bool {
        isGranted
    }
}
#endif
