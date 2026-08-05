#if DEBUG
import SwiftUI

/// Preview 用の SettingsView 組み立て。保存値は Preview 専用の UserDefaults に閉じる。
@MainActor
enum SettingsPreview {
    /// 通知の受け取り設定と許可状態を指定して SettingsViewModel を作る。
    static func makeViewModel(
        receivesNotifications: Bool,
        notificationPermissionDenied: Bool = false
    ) -> SettingsViewModel {
        let viewModel = SettingsViewModel(
            userDefaults: PreviewUserDefaults.make([
                SettingsKeys.receivesNotifications: receivesNotifications
            ]),
            // Preview で Toggle を操作しても実際の許可ダイアログは出さず、表示中の状態に合う結果を返す。
            notificationAuthorizing: PreviewNotificationAuthorizing(
                isGranted: !notificationPermissionDenied
            ),
            calendar: PreviewClock.calendar
        )
        viewModel.notificationPermissionDenied = notificationPermissionDenied
        return viewModel
    }

    /// Preview 用の SettingsView を作る。
    static func makeView(
        receivesNotifications: Bool,
        notificationPermissionDenied: Bool = false
    ) -> SettingsView {
        SettingsView(
            viewModel: makeViewModel(
                receivesNotifications: receivesNotifications,
                notificationPermissionDenied: notificationPermissionDenied
            )
        )
    }
}

#Preview("通知 ON") {
    SettingsPreview.makeView(receivesNotifications: true)
}

#Preview("通知 OFF") {
    SettingsPreview.makeView(receivesNotifications: false)
}

#Preview("通知が許可されていない") {
    SettingsPreview.makeView(receivesNotifications: true, notificationPermissionDenied: true)
}
#endif
