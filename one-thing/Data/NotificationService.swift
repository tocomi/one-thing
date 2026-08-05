import Foundation
import UserNotifications

/// UserNotifications を使ってローカル通知の予約を行う。
struct NotificationService: NotificationScheduling {
    private let notificationCenter: UNUserNotificationCenter
    private let calendar: Calendar

    /// 通知センターと日付計算に使う Calendar を受け取る。
    init(
        notificationCenter: UNUserNotificationCenter = .current(),
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.notificationCenter = notificationCenter
        self.calendar = calendar
    }

    /// 指定日時に配信する通知を予約する。
    func schedule(identifier: String, title: String, body: String, date: Date) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
    }

    /// 指定した識別子の未配信通知を取り消す。
    func cancelPendingNotifications(identifiers: [String]) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}

/// OS の通知センターを、そのまま通知許可の要求先として扱えるようにする。
extension UNUserNotificationCenter: NotificationAuthorizing {
    /// アラート・バッジ・サウンドの表示許可を求める。
    public func requestAuthorization() async throws -> Bool {
        try await requestAuthorization(options: [.alert, .badge, .sound])
    }
}
