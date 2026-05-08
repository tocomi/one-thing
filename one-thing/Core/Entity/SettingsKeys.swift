import Foundation

/// UserDefaults へ保存するアプリ設定キー。
enum SettingsKeys {
    static let receivesNotifications = "settings.receivesNotifications"
    static let morningNotificationMinutes = "settings.morningNotificationMinutes"
    static let eveningNotificationMinutes = "settings.eveningNotificationMinutes"
    static let dayBoundaryMinutes = "settings.dayBoundaryMinutes"
}
